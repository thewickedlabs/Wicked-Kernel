#!/usr/bin/env python3
"""Exit 0 if a boot/init_boot image (header v3/v4) has a KernelSU-patched ramdisk (kernelsu.ko), else 1.
usage: initboot_ksu.py init_boot.img"""
import gzip, struct, subprocess, sys

img = open(sys.argv[1], 'rb').read()
assert img[:8] == b'ANDROID!', 'not a boot image'
ksize, rsize = struct.unpack_from('<II', img, 8)
up = lambda x: (x + 4095) // 4096 * 4096
rd = img[4096 + up(ksize):4096 + up(ksize) + rsize]
if not rd:
    sys.exit(1)
cpio = gzip.decompress(rd) if rd[:2] == b'\x1f\x8b' else \
    subprocess.run(['lz4', '-dc'], input=rd, capture_output=True, check=True).stdout
p = 0
while cpio[p:p + 6] == b'070701':
    fsize, nsize = int(cpio[p + 54:p + 62], 16), int(cpio[p + 94:p + 102], 16)
    if cpio[p + 110:p + 110 + nsize - 1] == b'kernelsu.ko':
        sys.exit(0)
    p = (((p + 110 + nsize + 3) & ~3) + fsize + 3) & ~3
sys.exit(1)
