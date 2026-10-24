import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / 'scripts/qemu/vm.py'
spec = importlib.util.spec_from_file_location('tamber_vm', SOURCE)
vm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vm)


class VMTests(unittest.TestCase):
    def test_lock_matches_recorded_upstream_checksum(self):
        lock = vm.load_lock()
        evidence = (vm.ROOT / 'docs/evidence/almalinux-2026-10-23.CHECKSUM').read_text()
        self.assertIn(lock['sha256'] + '  ' + lock['filename'], evidence.splitlines())

    def test_checksum_rejects_corruption(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / 'image'
            p.write_bytes(b'original')
            lock = {'sha256': hashlib.sha256(b'original').hexdigest()}
            vm.verify_image(p, lock)
            p.write_bytes(b'corrupt')
            with self.assertRaises(ValueError): vm.verify_image(p, lock)

    def test_rejects_devices_and_symlinks(self):
        with self.assertRaises(ValueError): vm.regular('/dev/null')
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / 'link'
            p.symlink_to('/etc/os-release')
            with self.assertRaises(ValueError): vm.regular(p)

    def test_rejects_output_escape(self):
        for name in ('../outside', '/dev/sda', 'test,foo', '', 'a/b'):
            with self.subTest(name=name), self.assertRaises(ValueError): vm.output_path(name)

    def test_rejects_symlinked_build(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / 'build'
            p.symlink_to(Path(t), target_is_directory=True)
            with patch.object(vm, 'BUILD', p), self.assertRaises(ValueError): vm.output_path('dev')

    def test_network_defaults_and_loopback(self):
        cmd = vm.command(Path('/tmp/test'))
        self.assertIn('user,id=net0,restrict=on', cmd)
        self.assertNotIn('hostfwd', ' '.join(cmd))
        self.assertNotIn('/dev/', ' '.join(cmd))
        cmd = vm.command(Path('/tmp/test'), True, 2222)
        self.assertIn('user,id=net0,restrict=off,hostfwd=tcp:127.0.0.1:2222-:22', cmd)
        for network, port in ((False, 2222), (True, 22), (True, 70000)):
            with self.assertRaises(ValueError): vm.command(Path('/tmp/test'), network, port)

    def test_cloud_init_security_and_modes(self):
        key = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexample tamber-dev'
        cfg = json.loads(vm.cloud_config(key, False).split('\n', 1)[1])
        self.assertFalse(cfg['ssh_pwauth'])
        self.assertTrue(cfg['disable_root'])
        self.assertTrue(cfg['users'][0]['lock_passwd'])
        self.assertEqual(len(cfg['runcmd']), 1)
        self.assertIn('TAMBER_SSH_HOSTKEY', cfg['runcmd'][0][2])
        self.assertNotIn('/usr/local/bin/tamber-m1-check >', cfg['runcmd'][0][2])
        smoke = json.loads(vm.cloud_config(key, True).split('\n', 1)[1])
        self.assertEqual(smoke['power_state']['mode'], 'poweroff')
        with self.assertRaises(ValueError): vm.cloud_config(key + '\nusers: [root]', True)

    def test_log_parser_requires_exact_all_gates(self):
        valid = '\n'.join('TAMBER_CHECK ' + x + ' PASS' for x in ('identity', 'network', 'dnf', 'packages'))
        self.assertTrue(all(vm.check_transcript(valid).values()))
        self.assertFalse(all(vm.check_transcript(valid.replace('dnf PASS', 'dnf FAIL')).values()))
        self.assertFalse(any(vm.check_transcript('echo TAMBER_CHECK identity PASS').values()))
        self.assertFalse(any(vm.check_transcript('').values()))

    def test_dry_run_no_files_or_subprocess(self):
        with tempfile.TemporaryDirectory() as t, patch.object(vm, 'BUILD', Path(t) / 'build'):
            with patch.object(sys, 'argv', ['vm.py', 'run', '--dry-run']), patch.object(vm.subprocess, 'run') as run:
                with contextlib.redirect_stdout(io.StringIO()): self.assertEqual(vm.main(), 0)
                run.assert_not_called()
            self.assertFalse((Path(t) / 'build').exists())

    def test_cli_errors_do_not_report_success(self):
        p = subprocess.run([sys.executable, str(SOURCE), 'prepare', '--name', 'unit-test-missing-input'], capture_output=True, text=True)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('requires --code and --vars', p.stderr)

    def test_existing_vm_not_overwritten(self):
        with tempfile.TemporaryDirectory() as t, patch.object(vm, 'BUILD', Path(t)):
            dest = vm.output_path('existing')
            dest.mkdir(parents=True)
            sentinel = dest / 'disk.qcow2'
            sentinel.write_bytes(b'keep')
            args = type('Args', (), {'name': 'existing'})()
            with self.assertRaises(ValueError): vm.prepare(args, vm.load_lock())
            self.assertEqual(sentinel.read_bytes(), b'keep')


class DownloadTests(unittest.TestCase):
    def test_download_atomic_verification_and_cleanup(self):
        payload = b'unit-test-image-not-a-real-vm'
        lock = {'filename': 'test.qcow2', 'sha256': hashlib.sha256(payload).hexdigest(),
                'url': 'https://repo.almalinux.org/test'}
        with tempfile.TemporaryDirectory() as t, patch.object(vm, 'BUILD', Path(t)):
            response = io.BytesIO(payload); response.url = lock['url']
            with patch.object(vm.urllib.request, 'urlopen', return_value=response):
                target = vm.fetch(lock)
            self.assertEqual(target.read_bytes(), payload)
            self.assertFalse(target.with_suffix('.partial').exists())
            with patch.object(vm.urllib.request, 'urlopen') as network:
                self.assertEqual(vm.fetch(lock), target)
                network.assert_not_called()
            target.unlink()
            response = io.BytesIO(b'bad'); response.url = lock['url']
            with patch.object(vm.urllib.request, 'urlopen', return_value=response), self.assertRaises(ValueError):
                vm.fetch(lock)
            self.assertFalse(target.exists())
            self.assertFalse(target.with_suffix('.partial').exists())

    def test_existing_partial_is_preserved(self):
        with tempfile.TemporaryDirectory() as t, patch.object(vm, 'BUILD', Path(t)):
            cache = vm.output_path('cache'); cache.mkdir(parents=True)
            partial = cache / 'test.partial'; partial.write_text('other process')
            with self.assertRaises(FileExistsError):
                vm.fetch({'filename': 'test.qcow2', 'sha256': '0' * 64, 'url': 'https://example.org'})
            self.assertEqual(partial.read_text(), 'other process')

    def test_pass_then_fail_is_not_success(self):
        self.assertFalse(vm.check_transcript('TAMBER_CHECK dnf PASS\nTAMBER_CHECK dnf FAIL')['dnf'])

if __name__ == '__main__': unittest.main()

class ProxyTests(unittest.TestCase):
    def test_rejects_credentials_and_non_gateway_proxy(self):
        key='ssh-ed25519 AAAA test'
        for proxy in ('http://user:secret@10.0.2.2:1234','http://example.org:1234','http://10.0.2.2:1234/path'):
            with self.subTest(proxy=proxy), self.assertRaises(ValueError):vm.cloud_config(key,False,proxy)
        data=json.loads(vm.cloud_config(key,False,'http://10.0.2.2:1234').split('\n',1)[1])
        self.assertEqual(data['write_files'][-1]['content'],'http://10.0.2.2:1234\n')
