# Gerrit安装

## Git安装
**安装依赖包**：

```
# yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
# yum install  gcc perl-ExtUtils-MakeMaker
```

卸载旧的git版本
```
# yum remove git
```

下载&解压
```
# cd /usr/src
# wget https://www.kernel.org/pub/software/scm/git/git-2.5.0.tar.gz
# tar -zxvf git-2.5.0.tar.gz
```

编译安装
```
# cd git-2.5.0
# make prefix=/usr/local/git all
# make prefix=/usr/local/git install
# echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/bashrc
# source /etc/bashrc
```

检查git版本
```
# git --version
git version 2.5.0
```
如果安装完查看版本不是我们安装的最新版，请重新执行下面的操作
```
# yum remove -y git
# source /etc/bashrc
# git --version
```


安装Nginx源

```
rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
```
安装Nginx
```
yum install -y nginx
```

常用命令

(1) 启动：

```
nginx
```

(2) 测试Nginx配置是否正确：
```
nginx -t
```
(3) 优雅重启：
```
nginx -s reload
```


添加密码：


```
yum -y install httpd-tools
```


查看nginx进程
```
ps -ef | grep nginx
```

关闭nginx
```
pkill -9 nginx
```
