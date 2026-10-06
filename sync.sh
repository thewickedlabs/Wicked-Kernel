#!/usr/bin/env bash
# Fetch every pinned source into work/. Re-running only fetches what's missing or moved.
set -euo pipefail
cd "$(dirname "$0")"
. ./pins.env
W=work
mkdir -p "$W"

fetch() {  # path repo sha [depth]
  local d="$W/$1" depth=${4:-1}
  if git -C "$d" cat-file -e "$3^{commit}" 2>/dev/null; then return; fi
  echo ">> $1 @ ${3:0:12}"
  rm -rf "$d"; mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" remote add origin "$2"
  if [ "$depth" = 0 ]; then git -C "$d" fetch -q --tags origin "$3"; else git -C "$d" fetch -q --depth "$depth" origin "$3"; fi
  git -C "$d" -c advice.detachedHead=false checkout -q FETCH_HEAD
}

while IFS='|' read -r p r s; do [ -n "$p" ] && fetch "$p" "$r" "$s"; done <<<"$TREE"
# KSU Next derives its version from the commit count, so it needs full history
while IFS='|' read -r p r s; do
  [ -n "$p" ] || continue
  case $p in src/KernelSU-Next) fetch "$p" "$r" "$s" 0 ;; *) fetch "$p" "$r" "$s" ;; esac
done <<<"$EXTRA"
k="$W/src/KernelSU-Next"
git -C "$k" cat-file -e "$PERSHOOT_SHA" 2>/dev/null || git -C "$k" fetch -q "$PERSHOOT_REPO" "$PERSHOOT_SHA"

c="$W/prebuilts/clang/host/linux-x86/clang-$CLANG_VERSION"
if [ ! -x "$c/bin/clang" ]; then
  echo ">> clang-$CLANG_VERSION"
  mkdir -p "$c"
  curl -fsSL --retry 5 "$CLANG_URL" | tar -xz -C "$c"
fi

n="$W/prebuilts/ndk-r23/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
if [ ! -d "$n/usr" ]; then
  echo ">> ndk-r23 sysroot"
  mkdir -p "$n"
  curl -fsSL --retry 5 "$NDK_SYSROOT_URL" | tar -xz -C "$n"
fi

# repo linkfiles from the kernel manifest
mkdir -p "$W/build" "$W/tools"
for f in build.sh build_abi.sh build_test.sh build_utils.sh config.sh envsetup.sh _setup_env.sh multi-switcher.sh abi static_analysis; do
  ln -sfn "../build/kernel/$f" "$W/build/$f"
done
ln -sfn ../build/kernel/kleaf/bazel.sh "$W/tools/bazel"
echo "sync done"; du -sh "$W"
