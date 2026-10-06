#!/usr/bin/env bash
# ak3-zip.sh IMAGE OUT.zip — AnyKernel3 zip from the pinned AnyKernel3 and our anykernel.sh
set -euo pipefail
cd "$(dirname "$0")"
image=$(realpath "$1"); out=$(realpath -m "$2")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git -C work/src/AnyKernel3 archive HEAD | tar -x -C "$tmp"
rm -f "$tmp"/README.md "$tmp"/.gitignore
cp anykernel/anykernel.sh anykernel/banner "$tmp/"
cp "$image" "$tmp/Image"
rm -f "$out"
(cd "$tmp" && TZ=UTC find . -exec touch -d @0 {} + && zip -qr9X "$out" .)
sha256sum "$out"
