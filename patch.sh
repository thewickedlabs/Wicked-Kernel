#!/usr/bin/env bash
# Reset work/common to the pinned tag and apply everything. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")"
. ./pins.env
K=$PWD/work/common
S=$PWD/work/src
DEFCONFIG=$K/arch/arm64/configs/gki_defconfig

git -C "$K" reset -q --hard "$KERNEL_SHA"
git -C "$K" clean -qfdx

echo ">> KernelSU Next $KSUN_TAG + pershoot susfs commits"
KS=$S/KernelSU-Next
KSUN_SHA=$(awk -F'|' '$1=="src/KernelSU-Next"{print $3}' <<<"$EXTRA")
git -C "$KS" am --abort 2>/dev/null || true
git -C "$KS" reset -q --hard
git -C "$KS" checkout -qf -B wl-susfs "$KSUN_SHA"
git -C "$KS" -c user.name=wl -c user.email=wl@localhost am -q "$PWD"/patches/ksun/*.patch
# Report the release's version (30000 + commits at the tag), not our local commit count
KSU_COUNT=$(git -C "$KS" rev-list --count "$KSUN_SHA")
sed -i -e "s|^KSU_GIT_VERSION := .*|KSU_GIT_VERSION := $KSU_COUNT|" \
       -e "s|^KSU_GIT_TAG := .*|KSU_GIT_TAG := $KSUN_TAG|" "$KS/kernel/Kbuild"
grep -q "^KSU_GIT_VERSION := $KSU_COUNT$" "$KS/kernel/Kbuild"
ln -sfn "$(realpath --relative-to="$K/drivers" "$KS/kernel")" "$K/drivers/kernelsu"
printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$K/drivers/Makefile"
sed -i '/^endmenu/i source "drivers/kernelsu/Kconfig"' "$K/drivers/Kconfig"

echo ">> susfs"
SF=$S/susfs4ksu/kernel_patches
cp "$SF"/fs/* "$K/fs/"
cp "$SF"/include/linux/* "$K/include/linux/"
patch -d "$K" -p1 --no-backup-if-mismatch -s < "$SF/50_add_susfs_in_gki-android13-5.15.patch"

echo ">> DroidSpaces SYSVIPC KABI fix"
patch -d "$K" -p1 --no-backup-if-mismatch -s \
  < "$S/droidspaces/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kabi_6_7_8.patch"

echo ">> NoMount"
ln -sfn "$(realpath --relative-to="$K/fs" "$S/nomount/kernel/src")" "$K/fs/nomount"
printf '\nobj-$(CONFIG_NOMOUNT) += nomount/\n' >> "$K/fs/Makefile"
awk '/^endmenu/{l=NR} {a[NR]=$0} END{for(i=1;i<=NR;i++){if(i==l)print "source \"fs/nomount/Kconfig\""; print a[i]}}' \
  "$K/fs/Kconfig" > "$K/fs/Kconfig.tmp" && mv "$K/fs/Kconfig.tmp" "$K/fs/Kconfig"

echo ">> our kernel patches"
for p in patches/common/*.patch; do patch -d "$K" -p1 --no-backup-if-mismatch -s < "$p"; done

echo ">> config"
while IFS= read -r line; do
  line=$(sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$line")
  [ -n "$line" ] || continue
  key=${line%%=*}
  if grep -q "^$key=" "$DEFCONFIG"; then sed -i "s|^$key=.*|$line|" "$DEFCONFIG"
  elif grep -q "^# $key is not set" "$DEFCONFIG"; then sed -i "s|^# $key is not set|$line|" "$DEFCONFIG"
  else echo "$line" >> "$DEFCONFIG"; fi
done < a67lg2.config
sed -i 's/check_defconfig//' "$K/build.config.gki"

echo ">> version string"
sed -i '$d' "$K/scripts/setlocalversion"
echo "echo \"$LOCALVERSION_STR\"" >> "$K/scripts/setlocalversion"

git -C "$K" add -A
git -C "$K" -c user.name=wl -c user.email=wl@localhost commit -qm "A67LG2 patches"
echo "patch done: $(git -C "$K" diff --shortstat "$KERNEL_SHA" HEAD)"
