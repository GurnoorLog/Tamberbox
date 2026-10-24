import importlib.util
import os
from pathlib import Path
import struct,sys,tempfile,unittest,zlib
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/image'))
import donor
import validate
class ImageGuards(unittest.TestCase):
 def test_device_and_symlink_refused(self):
  with self.assertRaises(ValueError):donor.regular(Path('/dev/null'))
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'link';p.symlink_to('/etc/os-release')
   with self.assertRaises(ValueError):donor.regular(p)
 def test_wrong_board_layout_refused(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'image';p.write_bytes(bytes(4096))
   with self.assertRaises(ValueError):donor.partitions(p)
 def test_gpt_crc_detects_corruption(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'image';raw=bytearray(4096);table=bytes(128)
   for sector,lba in [(1,2),(7,6)]:
    h=bytearray(512);h[:8]=b'EFI PART';struct.pack_into('<I',h,12,92)
    struct.pack_into('<QII',h,72,lba,1,128);struct.pack_into('<I',h,88,zlib.crc32(table))
    struct.pack_into('<I',h,16,zlib.crc32(h[:92]));raw[sector*512:(sector+1)*512]=h
   p.write_bytes(raw);self.assertTrue(validate.verify_gpt(p))
   raw[1030]=1;p.write_bytes(raw)
   with self.assertRaisesRegex(ValueError,'table checksum'):validate.verify_gpt(p)

class PersonalizationGuards(unittest.TestCase):
 def test_private_key_and_wrong_type_rejected(self):
  import personalize
  for key in ['-----BEGIN OPENSSH PRIVATE KEY-----','ssh-rsa AAAA','ssh-ed25519 !!!']:
   with self.assertRaises(ValueError):personalize.public_key(key)
 def test_valid_ed25519_public_key(self):
  import base64,personalize
  blob=struct.pack('>I',11)+b'ssh-ed25519'+struct.pack('>I',32)+bytes(range(32))
  key='ssh-ed25519 '+base64.b64encode(blob).decode()
  self.assertEqual(personalize.public_key(key+' test@local'),key+'\n')
