# React Native--(一)

## 创建项目
- **创建一个工程HelloWorld**

```
react-native init HelloWorld
```

- **运行项目**

```
react-native run-android
```

问题1：

java.lang.RuntimeException: SDK location not found. Define location with sdk.dir in the local.properties file or with an ANDROID_HOME environment variable.

这个是原因是工程找不到我们的android SDK

解决方法：在Android studio工程的根目录下拷贝local.properties的文件


问题2：

A problem occurred configuring project ':app'.>failed to find Build Tools revision 23.0.1

这个是因为Build Tools revision 23.0.1和我们的sdk里面的版本不一致导致的

在/HelloWorld/android/app/build.gradle

```
android {
    compileSdkVersion 26
    buildToolsVersion "26.0.1"

    defaultConfig {
        applicationId "com.awesomeproject"
        minSdkVersion 16
        targetSdkVersion 22
        versionCode 1
        versionName "1.0"
        ndk {
            abiFilters "armeabi-v7a", "x86"

    。。。

```


- **运行成功截图**

![image](https://upload-images.jianshu.io/upload_images/1448227-ee92ac4a917d482f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/435)



