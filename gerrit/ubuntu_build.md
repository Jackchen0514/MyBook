
# Gerrit搭建

## 添加用户
- **adduser**

添加用户，切换用户
```
sudo adduser gerrit
sudo su gerrit
```

- **sudo**

给用户sudo权限
```
chmod u+w /etc/sudoers
```
编辑/etc/sudoers,==root ALL=(ALL) ALL==下面一行添加：
```
gerrit ALL=(ALL) ALL
```
保存，撤销写的权限
```
chmod u-w /etc/sudoers
```

## 安装jdk
- 安装openjdk
```
$ sudo apt-get update
```
安装openjdk-8-jdk：
```
$ sudo apt-get install openjdk-8-jdk
```


## 安装git

已知ubuntu14.04使用的git（版本1.9）版本过低，配合gerrit（版本2.12）使用有bug，请安装最新的git，命令如下：
```
$ sudo apt-get install software-properties-common
$ sudo add-apt-repository ppa:git-core/ppa
$ sudo apt-get update
$ sudo apt-get install git
$ git version
git version 2.11.0


注意： git版本新一点
```

Source安装


首先，安装一些git依赖的软件：
```
$ sudo apt-get install build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip
```
使用命令行下载：
下载地址https://github.com/git/git

```
wget https://github.com/git/git/archive/xxx.zip -O git.zip
```
编译源码：
```
$ make prefix=/usr/local all
$ sudo make prefix=/usr/local install
```




配置Git

请把下面的yourname替换为自己的名字
```
$ git config --global user.email "yourname@example.com"
$ git config --global user.name "yourname"
$ git config --global core.editor vim
```


## 安装Gerrit

- **下载**

Gerrit是由Java开发的，封装为一个war包：gerrit.war

[gerrit.war下载链接](https://www.gerritcodereview.com/releases/2.14.md)

```
wget https://gerrit-releases.storage.googleapis.com/gerrit-2.14.6.war
```
- **安装**

```
$ java -jar gerrit-2.14.6.war init -d review_site
```
有 [y/n] y

无 [y/n] 直接默认回车键
- **配置**
```
$ vim review_site/etc/gerrit.config
```
如下：

```
[gerrit]
        basePath = git
        serverId = d4e87978-a2ea-4783-8071-661850c68fdb
        canonicalWebUrl = http://localhost:8080/
[database]
        type = h2
        database = /home/xinsi/review_site/db/ReviewDB
[index]
        type = LUCENE
[auth]
        type = HTTP
[receive]
        enableSignedPush = false
[sendemail]
        smtpServer = localhost
[container]
        user = xinsi
        javaHome = /usr/lib/jvm/java-8-openjdk-amd64/jre
[sshd]
        listenAddress = *:29418
[httpd]
        listenUrl = proxy-http://*:8080/
[cache]

```

按照如上内容配置完 Gerrit Server 之后，可以通过如下命令重新启动它以应用新的配置

```
$ review_site/bin/gerrit.sh restart
```


## 设置第一个账号密码

htpasswd 命令是 apache2-utils 软件包中的一个工具。如果系统中还没有安装的话，通过如下命令进行安装：

```
$ sudo apt-get install apache2-utils
```
然后创建passwd保存账户：

```
$ touch ./review_site/etc/passwd
$ htpasswd -b ./review_site/etc/passwd admin admin
Adding password for user admin
```
(后续再添加 Gerrit 用户可使用 htpasswd -b ./review_site/etc/passwd UserName PassWord)

对于 Gerrit 来说，第一个成功登录的用户具有特殊意义 —— 它会直接被赋予管理员权限。对于第一个账户，需要特别注意一下。

## 开启Gerrit服务器

Gerrit 服务器还可以通过如下的命令进行启动：
```
$ review_site/bin/gerrit.sh start
Starting Gerrit Code Review: FAILED
```
上面的命令，通过 review_site/bin/gerrit.sh start 启动 Gerrit Server，但是失败了。Gerrit Server 启动，需要监听 8080 端口，如前面的配置文件 review_site/etc/gerrit.config 中的 listenUrl 行所显示的那样。通过如下的命令查看 8080 端口的使用情况：
```
$ sudo lsof -i -P | grep 8080
java       9538          tomcat   53u  IPv6 17098680      0t0  TCP *:8080 (LISTEN)
```

## 修改认证方式和反向代理

为了通过更为强大的 Web 服务器来对外提供服务，同时方便 Gerrit Server 的 HTTP 用户认证方式可以正常工作，需要设置反向代理。这里使用 nginx 作为 Web 服务器。

首先更改 Gerrit 配置，使能代理；另外，使用反向代理后就可以直接使用 nginx 的 80 端口访问了，需要把 canonicalWebUrl 中的 8080 去掉，Gerrit Server 监听的端口也改为 8081：

- **安装nginx**
```
sudo apt-get install nginx
```
- **gerrit.config**

修改gerrit的配置文件

```
[gerrit]
        basePath = git
        serverId = d4e87978-a2ea-4783-8071-661850c68fdb
        canonicalWebUrl = http://106.14.204.83/
        #去掉8080端口
···
[httpd]
        listenUrl = proxy-http://*:8081/
        #将8080端口改为8081
```

修改之后，重启 Gerrit Server
```
$ review_site/bin/gerrit.sh restart
Stopping Gerrit Code Review: OK
Starting Gerrit Code Review: OK
```
- **nginx.conf**

修改nginx的配置文件 /etc/nginx/nginx.conf
在它的 http 块中加入如下内容
```
server {
  listen 80;
  server_name [your ip];
  location ^~ / {
           auth_basic "Restricted";
           auth_basic_user_file /home/gerrit/review_site/etc/passwd;
    proxy_pass        http://127.0.0.1:8081;
    proxy_set_header  X-Forwarded-For $remote_addr;
    proxy_set_header  Host $host;
  }
}
```
auth_basic_user_file 行用户配置用户名和密码文件的保存路径。

重新加载配置文件：
```
$ sudo nginx -s reload
```
这样就可以直接通过 nginx 监听的 80 端口访问 Gerrit了

然后我们打开浏览器输入gerrit ip地址，会出现一个用户验证，我们输入账号密码例如：
```
admin
admin
```

## 邮箱配置
```
[sendemail]
        smtpServer = smtp.163.com
        smtpServerPort = 465
        smtpEncryption = ssl
        smtpUser = chenxinsi2612@163.com
        smtpPass = XXXX
        sslVerify = false
        from=CodeReview<chenxinsi2612@163.com>
```

## 数据库
这边用的默认自带的h2数据库，如有需要参考下面资料

## 问题

服务器每次反应较慢，等个2分钟，再判断配置有没成功

nginx服务器log位置：

```
cd /var/log/nginx
```

## 参考

http://hanpfei.github.io/2017/11/24/gerrit_codereview/


