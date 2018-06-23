# Gradle

## 基本概念

和ant Maven一样, 构建程序

由下面三部分组成：

- groovy核心语法

- build script block

- gradle api


## 优势

- 灵活性

- 粒度性

- 扩展性

复用现有库

- 兼容性

兼容所有ant maven


## 生命周期

- Initialization初始化阶段

解析整个工程的所有Project，构建所有的Project对应的project对象

- Configuration配置阶段

解析所有的projects对象中的task， 构建好所有的task的拓扑图

- Execution执行阶段

执行具体的task及其依赖task

## Project详解

Project API组成

```
this.getAllprojects()

this.getSubprojects()

this.getParent().name

this.getRootProject().name

project('app') {Project project ->
   apply plugin: 'com.android.application'
   android {
          compileSdkVersion 27
          defaultConfig {
              applicationId "com.example.xinsi.groovy"
              minSdkVersion 26
              targetSdkVersion 27
              testInstrumentationRunner "android.support.test.runner.AndroidJUnitRunner"
          }
   }
}


//为所有的project进行配置
allprojects {}

//为所有的子project进行配置
subprojects {}


apply from: this.file('common.gradle')

```






