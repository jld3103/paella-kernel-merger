# paella kernel merger
A simple script to use the latest Android mainline kernel with the latest msm8916/paella drivers and configs.  
The script cherry-picks the commits that are add by https://github.com/msm8916-mainline/linux against https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux to https://android.googlesource.com/kernel/common.  
Then it creates the defconfig for paella using the msm8916_defconfig with the latest configs required by Android.
The result ends up in https://github.com/jld3103/android_kernel_bq_paella-mainline.