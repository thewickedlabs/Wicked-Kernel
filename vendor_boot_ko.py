#!/usr/bin/env python3
"""Extract the kernel modules from a vendor_boot (header v3/v4) image.
usage: vendor_boot_ko.py vendor_boot.img OUTDIR"""
import gzip, os, struct, subprocess, sys

img = open(sys.argv[1], 'rb').read()
out = sys.argv[2]
assert img[:8] == b'VNDRBOOT', 'not a vendor_boot image'
ver, page = struct.unpack_from('<II', img, 8)
rd_size, = struct.unpack_from('<I', img, 24)
hdr_size, = struct.unpack_from('<I', img, 2096)
align = lambda x: (x + page - 1) // page * page
section = img[align(hdr_size):align(hdr_size) + rd_size]

frags = [(0, rd_size)]
if ver >= 4:
    dtb_size, = struct.unpack_from('<I', img, 2100)
    tbl_size, n, esz = struct.unpack_from('<III', img, 2112)
    tbl = align(hdr_size) + align(rd_size) + align(dtb_size)
    frags = [struct.unpack_from('<II', img, tbl + i * esz)[::-1] for i in range(n)]

def unpack(blob):
    if blob[:2] == b'\x1f\x8b':
        return gzip.decompress(blob)
    return subprocess.run(['lz4', '-dc'], input=blob, capture_output=True, check=True).stdout

os.makedirs(out, exist_ok=True)
count = 0
for off, size in frags:
    cpio, p = unpack(section[off:off + size]), 0
    while cpio[p:p + 6] == b'070701':
        f = [int(cpio[p + 6 + i * 8:p + 14 + i * 8], 16) for i in range(13)]
        fsize, nsize = f[6], f[11]
        name = cpio[p + 110:p + 110 + nsize - 1].decode()
        p = (p + 110 + nsize + 3) & ~3
        if name.endswith('.ko'):
            open(os.path.join(out, os.path.basename(name)), 'wb').write(cpio[p:p + fsize])
            count += 1
        p = (p + fsize + 3) & ~3
print(f'{count} modules from vendor_boot')
