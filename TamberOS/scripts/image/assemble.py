#!/usr/bin/env python3
"""Assemble a regular-file SD candidate; never accepts a physical destination."""
import hashlib,json,os,shutil,struct,subprocess,uuid,zlib
from pathlib import Path
from donor import ROOT,WORK,partitions,regular,digest
KVER='6.1.172-vendor-rk35xx'
ROOT_UUID='6b824c82-df58-5da7-922c-764d173a5bca'
def update_gpt(image):
 with image.open('r+b') as f:
  for sector in [1,image.stat().st_size//512-1]:
   f.seek(sector*512);h=bytearray(f.read(512))
   if h[:8]!=b'EFI PART':raise ValueError('Missing GPT header')
   lba,n,size=struct.unpack_from('<QII',h,72);f.seek(lba*512);table=bytearray(f.read(n*size))
   table[16:32]=uuid.UUID('8f1b94b2-801b-5c31-b6b7-dc240dd1937e').bytes_le
   f.seek(lba*512);f.write(table)
   h[56:72]=uuid.UUID('5c206bfa-0827-5b6b-923d-5b15a9c2efac').bytes_le
   struct.pack_into('<I',h,88,zlib.crc32(table)&0xffffffff)
   struct.pack_into('<I',h,16,0);length=struct.unpack_from('<I',h,12)[0]
   struct.pack_into('<I',h,16,zlib.crc32(h[:length])&0xffffffff)
   f.seek(sector*512);f.write(h)
def main():
 for p in [ROOT/'build',WORK]:
  if p.is_symlink():raise ValueError('Symlinked workspace')
 root=WORK/'alma-root';donor=WORK/'donor.img';regular(donor)
 if root.is_symlink() or not root.is_dir():raise ValueError('Missing staged Alma root')
 if 'ID="almalinux"' not in (root/'etc/os-release').read_text():raise ValueError('Not AlmaLinux')
 if sorted(p.name for p in (root/'usr/lib/modules').iterdir())!=[KVER]:raise ValueError('Kernel/module mismatch')
 boot=root/'boot';env=boot/'armbianEnv.txt'
 env.write_text('verbosity=7\nbootlogo=false\nconsole=both\nextraargs=cma=256M enforcing=0\noverlay_prefix=rockchip-rk3588\nfdtfile=rockchip/rk3588-orangepi-5-ultra.dtb\nrootdev=UUID='+ROOT_UUID+'\nrootfstype=ext4\n')
 subprocess.run(['mkimage','-A','arm64','-O','linux','-T','ramdisk','-C','none','-n','TamberOS AlmaLinux initramfs','-d',str(boot/f'initramfs-{KVER}.img'),str(boot/'uInitrd')],check=True)
 # Original exact-board U-Boot script/DTB/kernel remain coherent with the donor.
 (boot/'boot.bmp').unlink(missing_ok=True)
 image=WORK/'TamberOS-M2-ultra.img';fs=WORK/'tamber-root.ext4'
 if image.exists() or image.is_symlink() or fs.exists() or fs.is_symlink():raise ValueError('Refusing to overwrite output')
 start,end=partitions(donor);size=(end-start+1)*512
 with fs.open('xb') as f:f.truncate(size)
 subprocess.run(['mke2fs','-q','-F','-t','ext4','-b','4096','-O','^metadata_csum_seed,^orphan_file','-U',ROOT_UUID,'-L','TamberOS','-d',str(root),str(fs)],check=True)
 subprocess.run(['e2fsck','-fn',str(fs)],check=True)
 with donor.open('rb') as src,image.open('xb') as out:shutil.copyfileobj(src,out)
 with fs.open('rb') as src,image.open('r+b') as out:
  out.seek(start*512);shutil.copyfileobj(src,out)
 update_gpt(image)
 with donor.open('rb') as a,image.open('rb') as b:
  a.seek(32768);b.seek(32768)
  if a.read(start*512-32768)!=b.read(start*512-32768):raise ValueError('Bootloader region changed')
 report={'hardware_boot_verified':False,'image_sha256':digest(image),'bytes':image.stat().st_size,'root_uuid':ROOT_UUID,'kernel':KVER,'donor_lock':json.loads((ROOT/'scripts/image/donor.lock.json').read_text()),'boot_region_preserved':True,'login_personalized':(root/'home/tamber/.ssh/authorized_keys').exists(),'reproducibility':'Pinned donor; RPM NEVRAs recorded, repository/container snapshots not yet locked; not bit-reproducible'}
 (WORK/'image-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps(report,indent=2))
if __name__=='__main__':main()
