#!/usr/bin/env python3
"""Add one public SSH key to a NEW regular image file. Never flashes storage."""
import argparse,base64,json,shutil,struct,subprocess,tempfile
from pathlib import Path
from donor import WORK,regular,partitions,digest
from validate import verify_gpt

def public_key(text):
 words=text.strip().split()
 if len(words)<2 or words[0]!='ssh-ed25519':raise ValueError('Supply an Ed25519 PUBLIC key')
 try:
  blob=base64.b64decode(words[1],validate=True)
  if len(blob)!=51 or blob[:19]!=struct.pack('>I',11)+b'ssh-ed25519'+struct.pack('>I',32):raise ValueError()
 except Exception as e:raise ValueError('Malformed Ed25519 public key') from e
 return 'ssh-ed25519 '+words[1]+'\n'

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--public-key',type=Path,required=True);args=parser.parse_args()
 regular(args.public_key);key=public_key(args.public_key.read_text())
 src=WORK/'TamberOS-M2-ultra.img';dest=WORK/'TamberOS-M2-ultra-personalized.img'
 regular(src);verify_gpt(src)
 if WORK.is_symlink() or dest.exists() or dest.is_symlink():raise ValueError('Output exists or unsafe workspace')
 start,end=partitions(src)
 with tempfile.TemporaryDirectory(prefix='personalize-',dir=WORK) as temp:
  temp=Path(temp);fs=temp/'root.ext4';pub=temp/'key.pub';pub.write_text(key)
  with src.open('rb') as f,fs.open('xb') as out:
   f.seek(start*512);remaining=(end-start+1)*512
   while remaining:
    data=f.read(min(remaining,1024*1024))
    if not data:raise ValueError('Truncated image')
    out.write(data);remaining-=len(data)
  passwd=subprocess.check_output(['debugfs','-R','cat /etc/passwd',str(fs)],text=True)
  account=[line.split(':') for line in passwd.splitlines() if line.startswith('tamber:')]
  if len(account)!=1:raise ValueError('Missing Tamber test user')
  uid,gid=map(int,account[0][2:4]);target='/home/tamber/.ssh/authorized_keys'
  commands=[f'write {pub} {target}',f'set_inode_field {target} uid {uid}',f'set_inode_field {target} gid {gid}',f'set_inode_field {target} mode 0100600']
  for command in commands:subprocess.run(['debugfs','-w','-R',command,str(fs)],check=True)
  check=subprocess.check_output(['debugfs','-R','cat '+target,str(fs)],text=True)
  if check!=key:raise ValueError('Key readback failed; no output published')
  subprocess.run(['e2fsck','-fn',str(fs)],check=True)
  with src.open('rb') as f,dest.open('xb') as out:shutil.copyfileobj(f,out)
  with dest.open('r+b') as out,fs.open('rb') as f:out.seek(start*512);shutil.copyfileobj(f,out)
 report={'file':dest.name,'sha256':digest(dest),'source_sha256':digest(src),'public_key_only':True,'physical_storage_written':False}
 (WORK/'personalized-manifest.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
