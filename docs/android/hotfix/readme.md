# 热修复

## dex/class

- class

能够被JVM识别， 加载并执行的文件格式

  - 生成class文件
  - class文件结构


- dex

能够被dvm识别，加载并执行的文件格式

  - 生成dex文件

     dx --dex --output Hello.dex Hello.class

     adb shell
     dalvikvm -cp Hello.dex Hello

     打印: Hello
  - dex文件作用

     记录整个工程所有类文件的信息，记住是整个工程
  - dex文件格式

- class 与 dex 对比




## jvm/dvm/art



## class loader

- Resolving

- Initialising



加载流程



Android中ClassLoader的种类

- BootClassLoader

  加载framework层的字节码

- PathClassLoader

  安装apk的路径

- DexClassloader

- BaseDexClassLoader

Android中ClassLoader的特点


双亲代理模型的特点

   - 类加载的共享功能

   - 类加载的隔离功能

Android动态加载难点

- 有许多组件类需要注册才能使用

- 资源的动态加载很复杂

- Android程序运行需要一个上下文环境


## 热修复详解

- 基本概念

   - 什么是热修复

   - 热修复有哪些好处

   - 有了热修复我们就可以高枕无忧了么

- 市面上流行的几种热修复技术


   阿里AndFix, 微信Tinker, 美团

- 方案和选型

  学习成本 大公司方案


### AndFix详解

使用上 原理上 都相对更简单

- AndFix的基本介绍

- AndFix执行流程及核心原理

- 使用AndFix完成线上bug修复

- AndFix源码讲解

## 插件化


