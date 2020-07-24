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
  git remote add aosp https://android.googlesource.com/kernel/common
  git remote add linux https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux
  git remote add msm8916 https://github.com/msm8916-mainline/linux
fi

git reset --hard
git clean -fd

git fetch --all --tags --progress

git checkout --track -b aosp aosp/android-mainline 2>/dev/null || true
git checkout aosp
git pull -f
git checkout --track -b linux linux/master 2>/dev/null || true
git checkout linux
git pull -f
git checkout --track -b msm8916 msm8916/master 2>/dev/null || true
git checkout msm8916
git pull -f

msm8916_head=$(git rev-parse HEAD)
merge_base=$(git merge-base msm8916 linux)
git checkout aosp
aosp_head=$(git rev-parse HEAD)
if [ "$(git diff "$msm8916_head"~ "$msm8916_head" | sha256sum)" != "$(git diff "$aosp_head"~ "$aosp_head" | sha256sum)" ] &&
  [ "$(git diff "$msm8916_head"~ "$msm8916_head" | sha256sum)" != "$(git diff "$aosp_head"~2 "$aosp_head"~ | sha256sum)" ]; then
  git reset --hard aosp/android-mainline >/dev/null 2>&1 || true
  git cherry-pick --abort || true
  git cherry-pick "$merge_base...$msm8916_head" -X theirs --ff
  until git cherry-pick --continue; do
    git commit --allow-empty --no-edit
  done
fi

if [ "$(git diff "$msm8916_head"~ "$msm8916_head" | sha256sum)" == "$(git diff "$aosp_head"~2 "$aosp_head"~ | sha256sum)" ]; then
  git reset --hard @~
fi
git apply ../*.patch

../merge_config_intelligently.sh \
  arch/arm64/configs/paella_defconfig \
  arch/arm64/configs/msm8916_defconfig \
  "../configs/$configs_version/android-base.config" \
  "../configs/$configs_version/android-recommended.config" \
  "../configs/$configs_version/android-recommended-arm64.config" || exit 1
sed -i "s/=m/=y/" arch/arm64/configs/paella_defconfig
git add .
git commit -m "Add paella_defconfig"
