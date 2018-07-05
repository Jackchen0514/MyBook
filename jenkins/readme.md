# Jenkins

## 下载

```
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war
```

## 安装

```
java -jar jenkins.war
```

生成初始密码:

```
Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

190a8df497e14c77aba5d322749a2510

This may also be found at: /home/xinsi/.jenkins/secrets/initialAdminPassword

```
## 启动

```
http://localhost:8080/
```

输入初始密码

1. Install suggested plugins

2. Select plugins to install

## 配置

- **1. Global Tool Configuration**

在系统管理选项中找到Global Tool Configuration进入，如果上面的插件安装成功,你会看到好多模块

首先，配置JDK



## 参考

[1]https://www.jianshu.com/p/38b2e17ced73