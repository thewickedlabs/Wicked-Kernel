#!/usr/bin/env bash
# Build the patched tree with the GKI build.sh. Output: work/out/dist/{Image,vmlinux,.config,...}
# LTO=full ./build.sh for a release build (stock uses full; needs a lot of RAM).
set -euo pipefail
cd "$(dirname "$0")"
. ./pins.env
W=$PWD/work
export CCACHE_DIR=$W/ccache CCACHE_MAXSIZE=4G CCACHE_BASEDIR=$W
export TZ=UTC LC_ALL=C
export SOURCE_DATE_EPOCH=$(date -d "$BUILD_TIMESTAMP" +%s)
cd "$W"
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR=$W/out DIST_DIR=$W/out/dist \
LTO=${LTO:-thin} \
BUILD_GKI_ARTIFACTS=0 BUILD_GKI_CERTIFICATION_TOOLS=0 BUILD_SYSTEM_DLKM=0 \
SKIP_VENDOR_BOOT=1 SKIP_EXT_MODULES=1 SKIP_CP_KERNEL_HDR=1 \
CC="/usr/bin/ccache clang" CXX="/usr/bin/ccache clang++" \
HOSTCC="/usr/bin/ccache clang" HOSTCXX="/usr/bin/ccache clang++" \
  build/build.sh -j"$(nproc)"
