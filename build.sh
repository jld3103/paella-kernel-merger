#!/usr/bin/env bash
set -x
cd kernel || exit 1
ARCH=arm64 make paella_defconfig
cat >>.config <<EOL
CONFIG_ARM64_PTR_AUTH=y
CONFIG_ARM64_BTI_KERNEL=y
EOL
sed -i "s/=m/=y/" .config
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
  make Image.gz -j"$(nproc --all)" || (echo "Failed to build" && exit 1)
