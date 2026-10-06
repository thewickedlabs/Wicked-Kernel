# Changelog

## [0.3] - 2026-10-06

First public release (the third internal build).

- Android Common Kernel `android13-5.15-2026-03_r2` (5.15.197), full LTO, CFI.
- KernelSU Next v3.4.0 built in (version 33294), with pershoot's SUSFS commits rebased onto it.
- SUSFS v2.3.0 and NoMount built in.
- SysV IPC, POSIX mqueue and IPC/PID/user namespaces on (with the Droidspaces SysV IPC KABI fix).
- BBR and CAKE available; cubic stays the default.
- Ignores the bootloader's forced `initcall_debug=1`; drops the Wi-Fi driver's 5-second heartbeat log lines.
- SUSFS kernel logging off.
- `uname` and `/proc/version` match the factory kernel.
- AnyKernel3 zip that refuses to install over a KernelSU-patched `init_boot`; `preflight.sh` with module
  compatibility check and boot backups.
