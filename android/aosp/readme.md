# AOSP


## 下载repo工具
```
mkdir ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```
## 下载初始包
```
wget -c https://mirrors.tuna.tsinghua.edu.cn/aosp-monthly/aosp-latest.tar
tar xf aosp-latest.tar
cd AOSP   # 解压得到的 AOSP 工程目录
# 这时 ls 的话什么也看不到，因为只有一个隐藏的 .repo 目录
repo sync # 正常同步一遍即可得到完整目录
# 或 repo sync -l 仅checkout代码

```

## 需要特定版本的Android版本

地址 [列表](https://source.android.com/source/build-numbers.html#source-code-tags-and-builds)
```
repo init -b android-8.1.0_r7

repo sync
```

## 替换已有的AOSP源代码的remote

如果你之前已经通过某种途径获得了 AOSP 的源码(或者你只是 init 这一步完成后)， 你希望以后通过 TUNA 同步 AOSP 部分的代码，只需要将 `.repo/manifest.xml` 把其中的 aosp 这个 remote 的 fetch 从 `https://android.googlesource.com` 改为 `https://aosp.tuna.tsinghua.edu.cn/`。

```
<manifest>

   <remote  name="aosp"
-           fetch="https://android.googlesource.com"
+           fetch="https://aosp.tuna.tsinghua.edu.cn"
            review="android-review.googlesource.com" />

   <remote  name="github"
```
同时，修改 `.repo/manifests.git/config`，将
```
url = https://android.googlesource.com/platform/manifest
```

更改为

```
url = https://aosp.tuna.tsinghua.edu.cn/platform/manifest
```

## 注意

由于 AOSP 镜像造成CPU/内存负载过重，我们限制了并发数量，因此建议： 1. sync的时候并发数不宜太高，否则会出现 503 错误，即-j后面的数字不能太大，建议选择4。 2. 请尽量选择流量较小时错峰同步。

## Android studio快速导入

在android.iml中添加：

```
<excludeFolder url="file://$MODULE_DIR$/.repo" />
<excludeFolder url="file://$MODULE_DIR$/abi" />
<excludeFolder url="file://$MODULE_DIR$/art" />
<excludeFolder url="file://$MODULE_DIR$/bionic" />
<excludeFolder url="file://$MODULE_DIR$/bootable" />
<excludeFolder url="file://$MODULE_DIR$/build" />
<excludeFolder url="file://$MODULE_DIR$/cts" />
<excludeFolder url="file://$MODULE_DIR$/dalvik" />
<excludeFolder url="file://$MODULE_DIR$/developers" />
<excludeFolder url="file://$MODULE_DIR$/development" />
<excludeFolder url="file://$MODULE_DIR$/device" />
<excludeFolder url="file://$MODULE_DIR$/docs" />
<excludeFolder url="file://$MODULE_DIR$/external" />
<excludeFolder url="file://$MODULE_DIR$/hardware" />
<excludeFolder url="file://$MODULE_DIR$/libcore" />
<excludeFolder url="file://$MODULE_DIR$/libnativehelper" />
<excludeFolder url="file://$MODULE_DIR$/ndk" />
<excludeFolder url="file://$MODULE_DIR$/out" />
<excludeFolder url="file://$MODULE_DIR$/packages" />
<excludeFolder url="file://$MODULE_DIR$/pdk" />
<excludeFolder url="file://$MODULE_DIR$/prebuilt" />
<excludeFolder url="file://$MODULE_DIR$/prebuilts" />
<excludeFolder url="file://$MODULE_DIR$/sdk" />
<excludeFolder url="file://$MODULE_DIR$/system" />
<excludeFolder url="file://$MODULE_DIR$/tools" />
```
android studio 将不扫描这些目录
