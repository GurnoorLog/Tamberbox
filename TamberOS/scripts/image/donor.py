#!/usr/bin/env python3
"""Inspect and extract a checksum-pinned Ultra donor using regular files only."""
import hashlib,json,lzma,os,shutil,stat,struct,subprocess,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/m2'
LOCK=Path(__file__).with_name('donor.lock.json')
def digest(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def regular(p):
 if p.is_symlink() or not stat.S_ISREG(p.stat().st_mode):raise ValueError('Expected ordinary file: '+str(p))
def partitions(p):
 regular(p)
 with p.open('rb') as f:
  f.seek(512);h=f.read(512)
  if h[:8]!=b'EFI PART':raise ValueError('Expected GPT donor')
  lba,n,size=struct.unpack_from('<QII',h,72)
  if n>128 or size!=128:raise ValueError('Unexpected GPT table')
  f.seek(lba*512);table=f.read(n*size)
 entries=[]
 for i in range(n):
  e=table[i*size:(i+1)*size]
  if e[:16]!=bytes(16):entries.append(struct.unpack_from('<QQ',e,32))
 if entries!=[(32768,4765695)]:raise ValueError('Donor layout differs from reviewed Ultra image')
 return entries[0]
def main():
 for p in [ROOT/'build',WORK]:
  if p.is_symlink():raise ValueError('Symlinked workspace')
 WORK.mkdir(parents=True,exist_ok=True)
 lock=json.loads(LOCK.read_text());packed=WORK/'donor.img.xz';image=WORK/'donor.img'
 if not packed.exists():
  with urllib.request.urlopen(lock['url'],timeout=120) as src,packed.open('xb') as out:shutil.copyfileobj(src,out)
 regular(packed)
 if digest(packed)!=lock['sha256']:raise ValueError('Donor checksum mismatch')
 if not image.exists():
  with lzma.open(packed) as src,image.open('xb') as out:shutil.copyfileobj(src,out)
 # Revalidate decompressed cache against the authenticated compressed input.
 h=hashlib.sha256()
 with lzma.open(packed) as f:
  while b:=f.read(1024*1024):h.update(b)
 if digest(image)!=h.hexdigest():raise ValueError('Decompressed donor mismatch')
 start,end=partitions(image);part=WORK/'donor-root.ext4'
 if part.exists():part.unlink() if not part.is_symlink() else (_ for _ in ()).throw(ValueError('Symlink'))
 with image.open('rb') as src,part.open('xb') as out:
  src.seek(start*512);left=(end-start+1)*512
  while left:
   b=src.read(min(left,1024*1024))
   if not b:raise ValueError('Truncated donor')
   out.write(b);left-=len(b)
 dest=WORK/'donor-assets'
 if dest.exists():raise ValueError('Use a fresh donor-assets directory')
 for rel in ['usr/lib','licenses']: (dest/rel).mkdir(parents=True,exist_ok=True)
 for source,target in [('/boot',dest),('/usr/lib/modules',dest/'usr/lib'),('/usr/lib/firmware',dest/'usr/lib')]:
  subprocess.run(['debugfs','-R',f'rdump {source} {target}',str(part)],check=True)
 for source,name in [('/etc/armbian-release','armbian-release'),('/usr/lib/u-boot/LICENSE','u-boot-LICENSE')]:
  result=subprocess.run(['debugfs','-R','cat '+source,str(part)],capture_output=True,text=True,check=True)
  (dest/'licenses'/name).write_text(result.stdout)
 if 'BOARD=orangepi5-ultra' not in (dest/'licenses/armbian-release').read_text():raise ValueError('Wrong board')
 k='6.1.172-vendor-rk35xx'
 for p in [dest/'boot'/('vmlinuz-'+k),dest/'boot'/('dtb-'+k)/'rockchip/rk3588-orangepi-5-ultra.dtb',dest/'usr/lib/modules'/k/'modules.dep']:
  regular(p)
 manifest={str(p.relative_to(dest)):digest(p) for p in dest.rglob('*') if p.is_file() and not p.is_symlink()}
 (WORK/'donor-assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print('Verified and extracted exact-Ultra donor; hardware boot remains untested.')
if __name__=='__main__':main()
