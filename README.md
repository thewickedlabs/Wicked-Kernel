# Wicked Kernel — Foxxd A67L Gen 2

A custom GKI kernel for the **Foxxd A67L Gen 2** with **KernelSU Next built in**, **SUSFS** and **NoMount**.
A Wicked Labs fork of [WildKernels/GKI_KernelSU_SUSFS](https://github.com/WildKernels/GKI_KernelSU_SUSFS), cut down to
one phone and built locally.

> **Beta.** Tested on one A67L Gen 2 (firmware below). Read the whole install section before flashing.
> Flashing a kernel can leave your phone unbootable if you skip steps. You need an unlocked bootloader.

## What you get

| | Stock kernel | Wicked Kernel |
|---|---|---|
| Root | KernelSU Next as a loadable module, via a patched `init_boot` | **Built in**. Stock `init_boot`, about 1.6 s faster to root at boot |
| Hiding | none in the kernel | **SUSFS v2.3.0**, **NoMount** (path redirection with no mounts) |
| Network | cubic only | **BBR** and **CAKE** available (cubic stays the default) |
| Containers | SysV IPC and namespaces off | SysV IPC, POSIX mqueue, IPC/PID/user namespaces on |
| Boot log | `initcall_debug` forced on by the bootloader; Wi-Fi driver spams a heartbeat every 5 s | Both silenced |
| `uname` | factory string | the **same factory string** (`5.15.197-android13-8-g831ed15794af-dirty-ab157`) |

Base: Android Common Kernel `android13-5.15-2026-03_r2` (5.15.197). KernelSU Next **v3.4.0** (reports version
33294) with pershoot's SUSFS commits. Full-LTO, CFI on.

**What doesn't change:** the CPU, GPU, display, Wi-Fi, audio and camera drivers. Those are Unisoc's own
modules in `vendor_dlkm`/`vendor_boot`, and your phone keeps loading its own copies. This kernel is checked
against all 168 of them (0 missing symbols, 0 CRC mismatches). It is not an overclock or a speed kernel.

## Compatibility

- **Foxxd A67L Gen 2 only** (`ro.product.device=A67L_Gen2`). Not the Gen 1 (A67L): different firmware.
- Tested firmware: vendor `FOXXD/A67L_Gen2/A67L_Gen2:13/T00624/1784605054:user/release-keys`. Other builds may
  work; `preflight.sh` checks your phone's own modules and tells you.
- **Bootloader unlocked.** The kernel isn't signed by Foxxd, so a locked bootloader won't boot it.
- **KernelSU Next manager v3.4.0.** The kernel side is v3.4.0; a newer manager may expect a newer kernel interface.

## Downloads ([latest release](https://github.com/thewickedlabs/Wicked-Kernel/releases/latest))

| File | What it's for |
|---|---|
| `Wicked-Kernel-A67LG2-vX.Y-AnyKernel3.zip` | **The normal install.** Flash it with a kernel flasher app. Replaces only the kernel inside your own boot partition |
| `Wicked-Kernel-A67LG2-vX.Y-boot.img` | Fastboot install or recovery, for phones on the tested firmware |
| `Wicked-Kernel-A67LG2-vX.Y-Image` | The bare kernel, for people repacking themselves |
| `vmlinux.symvers` | Used by `preflight.sh` to check your phone's modules (also in this repo) |
| `SHA256SUMS` | Checksums for all of the above |

## Install

You need: the phone, already rooted with KernelSU Next; a PC with `adb`, `python3` and `lz4` for the preflight
check (strongly recommended); and [Kernel Flasher](https://github.com/capntrips/KernelFlasher) or another
AnyKernel3 flasher app on the phone. Charge to at least 50 %, and keep it plugged in.

**1. Run the preflight check (PC).** Download this repo (Code → Download ZIP), unzip it, connect the phone
with USB debugging on, grant superuser to **Shell** in the KernelSU Next manager, then run:

    ./preflight.sh

It checks the model, root, battery and firmware. On firmware we haven't tested, it pulls your phone's own
vendor modules and checks every one against this kernel (that part also needs `pip install pyelftools`).
Then it **backs up your current `boot` and `init_boot`** into a `backup-A67L_Gen2-…` folder on your PC.
Keep that folder. Only continue when it ends with `READY` (or when its only warning is about `init_boot` in
step 2).

**2. If KernelSU is installed as a module (most people): restore stock `init_boot`. Don't reboot.**
KernelSU Next manager → Home → **Uninstall** → **Restore stock image**. Root keeps working until you
reboot. **Do not reboot yet.** If the preflight said `init_boot is stock`, skip this step.

**3. Flash the kernel.** Kernel Flasher → your current slot → **Flash** → **Flash AK3 Zip** → pick
`Wicked-Kernel-A67LG2-vX.Y-AnyKernel3.zip`. Wait for it to finish. The installer refuses to run if
`init_boot` is still patched, so you can't do steps 2 and 3 in the wrong order by accident.

**4. Reboot once.** The bootloader shows its usual unlocked warning for about 10 seconds, then Android
starts (about 1 minute). Open the KernelSU Next manager: it should say **Working**, version 33294, built in.

**5. Optional extras.** The kernel has SUSFS and NoMount built in, but they only do something once userspace
uses them: the SUSFS module/tool v2.3.0 from [susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu), and the
[NoMount](https://github.com/maxsteeel/nomount) metamodule (built from the same commit as the kernel,
`e2e71ee`, works best).

### Why it has to be done this way

- **Built-in KernelSU and a patched `init_boot` can't be combined.** A patched `init_boot` loads the
  KernelSU module at every boot. This kernel already has KernelSU inside it, so you would get two copies
  fighting over the same hooks. That's why stock `init_boot` has to go back first.
- **Why not reboot between steps 2 and 3:** after step 2 alone, a reboot gives you the stock kernel with a
  stock `init_boot`, so no root, and you can't flash the kernel from the phone anymore (you'd need fastboot).
  After step 3 alone (if the installer let you), a reboot would load KernelSU twice. Doing both, then one
  reboot, goes straight from one working state to the other.
- **Why the preflight check:** the phone's drivers are Unisoc modules built for one kernel interface. If a
  firmware update changed them, they could fail to load on this kernel: no display, no Wi-Fi, or a bootloop.
  The check catches that on your PC before anything is written.
- **Why the backups:** your own `boot` and `init_boot` images are the only exact way back to how your phone
  was. Nothing else is guaranteed to match your firmware.
- **Why the current slot only:** the A67L Gen 2 ships with only slot A populated. Slot B stays empty until an
  OTA writes it, and switching to it won't boot. Kernel Flasher's current slot is the right one.
- **Why it needs the unlocked bootloader:** the boot image's signature no longer matches its contents. The
  bootloader boots it anyway in unlocked ("orange") state, which is the warning screen you see.

### Fastboot install (alternative, tested firmware only)

    adb reboot bootloader
    fastboot flash boot_a Wicked-Kernel-A67LG2-vX.Y-boot.img
    fastboot flash init_boot_a <your stock init_boot>
    fastboot reboot

The `boot.img` is built on the stock boot image of the tested firmware. Use your own **stock** `init_boot`
(from your firmware, or the KernelSU backup), not a KernelSU-patched one. This is the way back in, too, if a
flash goes wrong and Android won't start.

## Going back (uninstall)

From the preflight backup folder:

    adb reboot bootloader
    fastboot flash boot_a backup-A67L_Gen2-…/boot_a.img
    fastboot flash init_boot_a backup-A67L_Gen2-…/init_boot_a.img
    fastboot reboot

That restores exactly what you had, including KernelSU in module mode if you had it.

## Building it yourself

On Linux x86-64 with about 15 GB free disk (5.3 GB of sources) and 16 GB RAM plus swap (the full-LTO link
peaks around 19 GB):

    ./sync.sh                     # fetch every source at its pinned commit (pins.env)
    ./patch.sh                    # apply KernelSU Next, SUSFS, NoMount and our patches; set the config
    LTO=full ./build.sh           # thin LTO is the default and much lighter
    ./repack.sh STOCK_BOOT.img work/out/dist/Image boot.img
    ./ak3-zip.sh work/out/dist/Image Wicked-Kernel-AnyKernel3.zip
    python3 kmi_check.py work/out/dist/vmlinux.symvers MODULE_DIRS...

| File | Purpose |
|---|---|
| `pins.env` | Every source at a fixed commit, plus the stock kernel identity |
| `sync.sh` / `patch.sh` / `build.sh` | Fetch, patch, build (GKI `build/build.sh`, output in `work/out/dist/`) |
| `a67lg2.config` | Config fragment on top of `gki_defconfig` |
| `patches/ksun/` | pershoot's 8 `dev-susfs` commits, rebased onto KernelSU Next v3.4.0 |
| `patches/common/` | Ours: ignore the bootloader's `initcall_debug`; drop the Wi-Fi heartbeat log |
| `repack.sh` | Puts a kernel into a stock boot image's exact layout |
| `ak3-zip.sh`, `anykernel/` | Builds the AnyKernel3 zip from the pinned AnyKernel3 |
| `kmi_check.py`, `vendor_boot_ko.py`, `initboot_ksu.py`, `preflight.sh` | Checks used before flashing |

Build notes:
- KernelSU Next is rebased, not pershoot's tip: his `dev-susfs` sits on upstream `dev`, which moved to kernel
  interface 5, while the v3.4.0 manager speaks 4. Three hunks were resolved by hand in patch 0001.
- `patch.sh` sets the KernelSU version to the v3.4.0 tag's count (33294).
- Wild's SUSFS "fake patches" for 5.15.197 are no-ops on this tag, so they're left out.
- Only clang r450784e and the NDK r23 sysroot are fetched (keeps `CC_CAN_LINK=y` like stock).

## Credits

[WildKernels](https://github.com/WildKernels/GKI_KernelSU_SUSFS) (build method, AnyKernel3),
[KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next), [pershoot](https://github.com/pershoot/KernelSU-Next)
(SUSFS integration), [simonpunk](https://gitlab.com/simonpunk/susfs4ksu) (SUSFS),
[maxsteeel](https://github.com/maxsteeel/nomount) (NoMount),
[ravindu644](https://github.com/ravindu644/Droidspaces-OSS) (SysV IPC KABI patch),
[osm0sis](https://github.com/osm0sis/AnyKernel3) (AnyKernel3). Licenses in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

This repo's own files: [GPL-3.0-or-later](LICENSE). The kernel and the patches applied to it keep their own
licenses (the kernel is GPL-2.0). No warranty: you flash this at your own risk.

Foxxd and Unisoc ship this phone's kernel without publishing its source. This repo is the complete source for
the kernel we distribute.

---

Wicked Labs · https://www.cyberspace7.org
