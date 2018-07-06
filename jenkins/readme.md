# Jenkins

- **最简单的方式：**

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

- **CentOS安装**

## 源设置

```
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum repolist
yum makecache
```

## 安装

方式一：

```
yum install jenkins
```

方式二：

直接从https://pkg.jenkins.io/redhat-stable/下载rpm包
```
sudo rpm -ih jenkins-1.562-1.1.noarch.rpm
```

自动安装完成之后：
   - `/usr/lib/jenkins/jenkins.war` WAR包
   - `/etc/sysconfig/jenkins` 配置文件
   - `/var/lib/jenkins/` 默认的JENKINS_HOME目录
   - `/var/log/jenkins/jenkins.log` Jenkins日志文件

## 启动&停止

启动
```
service jenkins start
```

停止
```
service jenkins stop
```

## 修改端口

vim vim /etc/sysconfig/jenkins
```
JENKINS_PORT="8484"

## Type:        string
## Default:     ""
## ServiceRestart: jenkins
#
# IP address Jenkins listens on for HTTP requests.
# Default is all interfaces (0.0.0.0).
```

```
service jenkins restart
```

查看是否修改成功
```
ps -def | grep java
```

如果成功如下显示：

```
...  --webroot=/var/cache/jenkins/war --daemon --httpPort=8484 --debug=5
```

## 输入初始密码

```
cat /var/lib/jenkins/secrets/initialAdminPassword
```


## 配置git项目时注意点

gerrit服务器在本地，
本机服务器ssh用的 private key， 不是public key



## 参考

[1] https://www.jianshu.com/p/38b2e17ced73

[2] https://www.hugeserver.com/kb/how-install-jenkins-centos7/

[3] https://blog.csdn.net/u013066244/article/details/52694772