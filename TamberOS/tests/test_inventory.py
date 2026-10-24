import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('inventory', Path(__file__).resolve().parents[1] / 'scripts/board_inventory.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class InventoryTests(unittest.TestCase):
    def test_empty_root_is_unknown(self):
        with tempfile.TemporaryDirectory() as t:
            r = m.collect(Path(t))
            self.assertFalse(r['exact_ultra_compatible'])
            self.assertIsNone(r['board_model'])
            self.assertIsNone(r['uboot_version'])

    def test_exact_board_and_sensitive_fields_excluded(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            fixture = {'proc/device-tree/compatible': 'xunlong,orangepi-5-ultra\0rockchip,rk3588\0',
                       'etc/os-release': 'ID="almalinux"\nVERSION_ID="10.2"\nSECRET=abc',
                       'boot/armbianEnv.txt': 'fdtfile=rockchip/rk3588-orangepi-5-ultra.dtb\nrootdev=UUID=secret\nextraargs=password=secret',
                       'proc/cmdline': 'password=should-not-read',
                       'proc/modules': 'panthor 123 0 - Live 0xffff\n'}
            for path, value in fixture.items():
                p = root / path; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(value)
            r = m.collect(root)
            self.assertTrue(r['exact_ultra_compatible'])
            self.assertNotIn('secret', str(r))
            self.assertEqual(r['loaded_modules'], ['panthor'])
            (root / 'proc/device-tree/compatible').write_text('xunlong,orangepi-5-plus\0')
            self.assertFalse(m.collect(root)['exact_ultra_compatible'])

    def test_redaction(self):
        s = m.redact('aa:bb:cc:dd:ee:ff serial=123 token=secret 12345678-1234-1234-1234-123456789abc')
        for x in ('aa:bb', '=123', '=secret', '12345678'): self.assertNotIn(x, s)
