#!/usr/bin/env bash
# preflight.sh [-s SERIAL] — check a Foxxd A67L Gen 2 before flashing Wicked Kernel and back up its boot images.
# Needs adb, root for the adb shell, python3 + lz4, and (only on untested firmware) pyelftools.
set -euo pipefail
cd "$(dirname "$0")"
SYMVERS=${SYMVERS:-release/vmlinux.symvers}
TESTED_VENDOR="FOXXD/A67L_Gen2/A67L_Gen2:13/T00624/1784605054:user/release-keys"
TESTED_SYSTEM_DLKM="FOXXD/A67L_Gen2/A67L_Gen2:16/BP2A.250605.031.A3/1784605054:user/release-keys"

ADB=(adb); [ "${1:-}" = -s ] && ADB=(adb -s "$2")
sh_() { "${ADB[@]}" shell "$@" | tr -d '\r'; }
fail() { echo "FAIL: $*"; exit 1; }
warn() { echo "WARN: $*"; WARNED=1; }
ok() { echo "OK:   $*"; }
WARNED=0

"${ADB[@]}" get-state >/dev/null 2>&1 || fail "no device. Connect one phone with USB debugging on (or pass -s SERIAL)."

dev=$(sh_ getprop ro.product.device)
[ "$dev" = A67L_Gen2 ] || fail "this is '$dev', not an A67L Gen 2. Wicked Kernel is for the Gen 2 only."
ok "device A67L_Gen2"

# R runs a root command; Rb streams raw bytes (exec-out, no CR filtering)
if [ "$(sh_ id -u)" = 0 ]; then R() { sh_ "$1"; }; Rb() { "${ADB[@]}" exec-out "$1"; }
elif [ "$(sh_ "su -c 'id -u'" 2>/dev/null)" = 0 ]; then R() { sh_ "su -c '$1'"; }; Rb() { "${ADB[@]}" exec-out "su -c '$1'"; }
else fail "no root from adb. In the KernelSU manager, grant superuser to Shell, then run this again."; fi
ok "root over adb"

slot=$(sh_ getprop ro.boot.slot_suffix)
ok "active slot ${slot:-none}"

batt=$(sh_ dumpsys battery | awk '$1=="level:"{print $2; exit}')
[ "${batt:-0}" -ge 50 ] && ok "battery $batt%" || warn "battery ${batt:-?}%. Charge to 50% or more first."

vfp=$(sh_ getprop ro.vendor.build.fingerprint); sfp=$(sh_ getprop ro.system_dlkm.build.fingerprint)
if [ "$vfp" = "$TESTED_VENDOR" ] && [ "$sfp" = "$TESTED_SYSTEM_DLKM" ]; then
  ok "firmware matches the tested build"
else
  echo "....  untested firmware ($vfp); checking every vendor module against this kernel"
  [ -f "$SYMVERS" ] || fail "$SYMVERS not found (it ships in this repo and on the Release page)."
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  for d in vendor_dlkm system_dlkm; do "${ADB[@]}" pull "/$d/lib/modules" "$tmp/$d" >/dev/null; done
  Rb "cat /dev/block/by-name/vendor_boot$slot" > "$tmp/vendor_boot.img"
  python3 vendor_boot_ko.py "$tmp/vendor_boot.img" "$tmp/vendor_boot"
  if python3 kmi_check.py "$SYMVERS" "$tmp/vendor_boot" "$tmp/vendor_dlkm" "$tmp/system_dlkm"; then
    ok "all vendor modules match this kernel"
  else
    fail "your vendor modules don't match this kernel. Don't flash it; it would bootloop. Open an issue with the output above."
  fi
fi

bk="backup-A67L_Gen2-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$bk"
for p in boot init_boot; do
  Rb "cat /dev/block/by-name/$p$slot" > "$bk/$p$slot.img"
  [ "$(sha256sum < "$bk/$p$slot.img" | cut -d' ' -f1)" = "$(R "sha256sum /dev/block/by-name/$p$slot" | cut -d' ' -f1)" ] \
    || fail "backup of $p$slot doesn't match the partition. Try again."
done
(cd "$bk" && sha256sum ./*.img > SHA256SUMS)
ok "backed up boot$slot + init_boot$slot to $bk/ (keep these: they're your way back)"

if python3 initboot_ksu.py "$bk/init_boot$slot.img"; then
  warn "init_boot$slot is KernelSU-patched (LKM mode). KernelSU Next manager: Uninstall, then Restore stock image. Don't reboot; flash the kernel next (README, step 2)."
else
  ok "init_boot$slot is stock"
fi

[ "$WARNED" = 0 ] || { echo "NOT READY: fix the warnings above first."; exit 1; }
echo "READY: safe to flash."
