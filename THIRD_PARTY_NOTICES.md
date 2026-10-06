# Third-party notices

Nothing below is vendored in this repo except where noted. `sync.sh` fetches each component at the commit
pinned in `pins.env`, and each keeps its own license.

| Component | Upstream | License |
|---|---|---|
| Kernel source | [kernel/common](https://android.googlesource.com/kernel/common) | GPL-2.0 |
| KernelSU Next | [KernelSU-Next/KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) | GPL-3.0 (kernel side GPL-2.0) |
| SUSFS integration commits (`patches/ksun/`, vendored) | [pershoot/KernelSU-Next](https://github.com/pershoot/KernelSU-Next) | GPL-3.0 |
| susfs4ksu | [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) | GPL-3.0+ (kernel patches GPL-2.0) |
| NoMount | [maxsteeel/nomount](https://github.com/maxsteeel/nomount) | GPL-3.0 |
| Droidspaces SysV IPC KABI patch | [ravindu644/Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) | GPL-3.0 |
| kernel_patches | [WildKernels/kernel_patches](https://github.com/WildKernels/kernel_patches) | GPL-2.0 |
| Build method | [WildKernels/GKI_KernelSU_SUSFS](https://github.com/WildKernels/GKI_KernelSU_SUSFS) | GPL-3.0-or-later |
| AnyKernel3 (in the release zip) | [WildKernels/AnyKernel3](https://github.com/WildKernels/AnyKernel3), from [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3) | BSD (see its LICENSE in the zip) |
| magiskboot, busybox and other tools in the zip | [topjohnwu/Magisk](https://github.com/topjohnwu/Magisk), via AnyKernel3 | GPL-3.0 / GPL-2.0 |
| Clang r450784e, GKI build tools | [Android toolchain](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86) | Apache-2.0 with LLVM exception |

If something here is credited wrong, open an issue and we'll fix it.
