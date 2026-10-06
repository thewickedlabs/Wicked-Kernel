#!/usr/bin/env bash
# repack.sh STOCK_BOOT.img KERNEL_Image OUT.img
# Header v4, given kernel, empty ramdisk (as stock), then the stock boot signature, signed vbmeta
# blob and footer, the same way ksud's boot patch leaves it. The digest goes stale; LK boots it while unlocked (orange).
set -euo pipefail
cd "$(dirname "$0")"
stock=$(realpath "$1"); kernel=$(realpath "$2"); out=$(realpath -m "$3")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
: > "$tmp/ramdisk"
python3 work/tools/mkbootimg/mkbootimg.py --header_version 4 --kernel "$kernel" --ramdisk "$tmp/ramdisk" \
  --cmdline '' --output "$tmp/boot.img"
python3 - "$stock" "$tmp/boot.img" "$out" <<'PY'
import struct, sys
stock = open(sys.argv[1], 'rb').read()
body = open(sys.argv[2], 'rb').read()
magic, maj, mn, orig, off, sz = struct.unpack('>4sIIQQQ', stock[-64:-28])
assert magic == b'AVBf' and stock[off:off+4] == b'AVB0'
vbmeta = stock[off:off+sz]
# v4 boot signature (16 KiB after kernel+ramdisk): keep the stock blob, as ksud does
up = lambda x: (x + 4095) // 4096 * 4096
ks, = struct.unpack_from('<I', stock, 8)
sig_off = 4096 + up(ks)
assert stock[sig_off:sig_off+4] == b'AVB0' and off - sig_off == 16384
nk, nr = struct.unpack_from('<II', body, 8)
body = body[:4096 + up(nk) + up(nr)] + stock[sig_off:off]
img = body + vbmeta
img += b'\0' * (len(stock) - 64 - len(img))
assert len(img) == len(stock) - 64, 'image too big for the partition'
img += struct.pack('>4sIIQQQ', b'AVBf', maj, mn, len(body), len(body), sz) + stock[-28:]
open(sys.argv[3], 'wb').write(img)
PY
sha1sum "$out"
