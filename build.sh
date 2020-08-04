#!/bin/bash
set -x
if [ ! -d configs ]; then
  git clone https://android.googlesource.com/kernel/configs
  (cd configs && git config pull.ff only)
else
  (cd configs && git pull)
fi

cd configs || exit 1
configs_version=$(find . -maxdepth 1 -name "android*" | tail -1 | sed -e "s/\.\///")
cd ..

mkdir -p kernel
cd kernel || exit 1

if [ ! -d .git ]; then
  git init
  git config pull.rebase true
  git config merge.renamelimit 10000
  git config diff.renameLimit 10000
  git remote add aosp https://android.googlesource.com/kernel/common
  git remote add linux https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux
  git remote add msm8916 https://github.com/msm8916-mainline/linux
fi

git reset --hard
git clean -fd

git fetch --all --tags --progress

git checkout --track -b linux linux/master 2>/dev/null || true
git checkout linux
git reset --hard linux/master
git pull
# The rebase branch doesn't contain all patches, but is compatible with the android-mainline branch
git checkout --track -b msm8916 msm8916/rebase 2>/dev/null || true
git checkout msm8916
git reset --hard msm8916/rebase
git pull
msm8916_head=$(git rev-parse HEAD)
git checkout --track -b aosp aosp/android-mainline 2>/dev/null || true
git checkout aosp
git reset --hard aosp/android-mainline
git pull
aosp_head=$(git rev-parse HEAD)

msm8916_merge_base=$(git merge-base msm8916 linux)
aosp_merge_base=$(git merge-base aosp linux)

git branch -D paella-mainline >/dev/null 2>&1 || true
git checkout -b paella-mainline >/dev/null 2>&1 || true
git reset --hard linux/master >/dev/null 2>&1 || true
git reset --hard "$msm8916_merge_base"

git diff "$aosp_merge_base...$aosp_head" >patch.txt
git apply --reject patch.txt
rm patch.txt
git add .
git commit -m "Add commits from android-mainline"

git diff "$msm8916_merge_base...$msm8916_head" >patch.txt
git apply --reject patch.txt
rm patch.txt
git add .
git commit -m "Add commits from msm8916"

../merge_config_intelligently.sh \
  arch/arm64/configs/paella_defconfig \
  arch/arm64/configs/msm8916_defconfig \
  "../configs/$configs_version/android-base.config" \
  "../configs/$configs_version/android-recommended.config" \
  "../configs/$configs_version/android-recommended-arm64.config" || exit 1
sed -i "s/=m/=y/" arch/arm64/configs/paella_defconfig
printf "CONFIG_ARM64_PTR_AUTH=n\nCONFIG_HW_RANDOM=y\nCONFIG_EFIVAR_FS=y" >>arch/arm64/configs/paella_defconfig
git add .
git commit -m "Add paella_defconfig"

git apply ../001-selinux-cap-fix.patch
git add .
git commit -m "Add manual patches"
