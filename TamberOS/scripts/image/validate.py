#!/usr/bin/env python3
"""Offline image checks. A pass does not establish physical-board bootability."""
import json,struct,subprocess,zlib
from pathlib import Path
from donor import WORK,partitions,regular,digest
from assemble import KVER,ROOT_UUID

def verify_gpt(path):
 regular(path);length=path.stat().st_size
 with path.open('rb') as f:
  for sector in (1,length//512-1):
   f.seek(sector*512);header=bytearray(f.read(512))
   if header[:8]!=b'EFI PART':raise ValueError('Missing GPT signature')
   size=struct.unpack_from('<I',header,12)[0]
   if not 92<=size<=512:raise ValueError('Invalid GPT header size')
   crc=struct.unpack_from('<I',header,16)[0];struct.pack_into('<I',header,16,0)
   if zlib.crc32(header[:size])&0xffffffff!=crc:raise ValueError('GPT header checksum mismatch')
   lba,n,width=struct.unpack_from('<QII',header,72)
   if n>128 or width!=128 or lba*512+n*width>length:raise ValueError('Invalid GPT table extent')
   f.seek(lba*512);table=f.read(n*width)
   if zlib.crc32(table)&0xffffffff!=struct.unpack_from('<I',header,88)[0]:raise ValueError('GPT table checksum mismatch')
 return True

def main():
 image=WORK/'TamberOS-M2-ultra.img';root=WORK/'alma-root';donor=WORK/'donor-assets'
 verify_gpt(image);start,end=partitions(image)
 kernel=root/'boot'/('vmlinuz-'+KVER)
 with kernel.open('rb') as f:f.seek(56);magic=f.read(4)
 if magic!=b'ARM\x64':raise ValueError('Kernel is not an uncompressed ARM64 Image')
 dtb=root/'boot'/('dtb-'+KVER)/'rockchip/rk3588-orangepi-5-ultra.dtb'
 compatible=subprocess.check_output(['fdtget',str(dtb),'/','compatible'],text=True).strip()
 if 'xunlong,orangepi-5-ultra' not in compatible:raise ValueError('Wrong DTB compatible')
 manifest=json.loads((WORK/'donor-assets.json').read_text())
 matched=0
 for name,sha in manifest.items():
  if name.endswith(('.ko','.ko.xz','.ko.zst')) or name in ['boot/boot.cmd','boot/boot.scr',f'boot/vmlinuz-{KVER}'] or name.startswith('boot/dtb-'):
   if digest(root/name)!=sha:raise ValueError('Board asset changed: '+name)
   matched+=1
 initramfs=root/'boot'/f'initramfs-{KVER}.img'
 if not initramfs.is_file() or initramfs.stat().st_size<100000:raise ValueError('Missing Alma initramfs')
 env=(root/'boot/armbianEnv.txt').read_text()
 if 'rootdev=UUID='+ROOT_UUID not in env or ROOT_UUID not in (root/'etc/fstab').read_text():raise ValueError('Root UUID mismatch')
 subprocess.run(['e2fsck','-fn',str(WORK/'tamber-root.ext4')],check=True)
 report={'offline_checks_passed':True,'hardware_boot_verified':False,'gpt_crc':True,'kernel_arm64_magic':True,'dtb_compatible':compatible,'matched_donor_assets':matched,'root_uuid_consistent':True,'filesystem_check':True,'image_sha256':digest(image)}
 (WORK/'offline-validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
