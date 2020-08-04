#!/usr/bin/env bash
set -x
cd kernel || exit 1
ARCH=arm64 make paella_defconfig
echo "CONFIG_ARM64_PTR_AUTH=n" >>.config
sed -i "s/=m/=y/" .config
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
  make Image.gz -j"$(nproc --all)" || (echo "Failed to build" && exit 1)
