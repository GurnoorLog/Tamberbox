#!/usr/bin/env python3
"""Stage themes in build/ only; never activates SDDM or modifies an initramfs."""
import pathlib,shutil,subprocess,struct,zlib
root=pathlib.Path(__file__).resolve().parents[1];out=root/'build/themes'
if out.exists():raise SystemExit('Fresh build/themes directory required')
shutil.copytree(root/'themes/sddm/tamber',out/'sddm/tamber')
shutil.copytree(root/'themes/plymouth/tamber',out/'plymouth/tamber')
subprocess.run(['rsvg-convert','-w','130','-h','165','-o',str(out/'plymouth/tamber/mascot.png'),str(root/'branding/tamber-llama.svg')],check=True)
def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
raw=b''.join(b'\x00'+bytes([238,148,102,255])*200 for _ in range(3))
(out/'plymouth/tamber/progress.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>2I5B',200,3,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print(out)
