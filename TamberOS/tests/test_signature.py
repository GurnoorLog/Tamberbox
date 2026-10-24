import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('verify_signature',Path(__file__).resolve().parents[1]/'scripts/qemu/verify_signature.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

@unittest.skipUnless(shutil.which('gpg') and shutil.which('gpgv'), 'GnuPG tools required for real signature tests')
class SignatureTests(unittest.TestCase):
    def test_real_upstream_signature_and_pinned_image(self):
        lock=json.loads((m.TRUST.parent/'image.lock.json').read_text())
        self.assertTrue(m.verify_lock(lock)['signature_verified'])
    def test_modified_checksum_rejected(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t)/'CHECKSUM';p.write_bytes((m.TRUST/'CHECKSUM').read_bytes()+b'tampered\n')
            with self.assertRaises(ValueError):m.verify(p)
    def test_wrong_image_lock_rejected(self):
        lock=json.loads((m.TRUST.parent/'image.lock.json').read_text());lock['sha256']='0'*64
        with self.assertRaises(ValueError):m.verify_lock(lock)
