# nginx

## 搭建简单的文件下载服务器

```
vim /etc/nginx/nginx.conf
```

添加内容如下：
```
server {
    listen       80;        #端口
    server_name  localhost;   #服务名
    charset utf-8; # 避免中文乱码
    root    /dev/shm/update;  #显示的根索引目录，注意这里要改成你自己的，目录要存在

    location / {
        autoindex on;             #开启索引功能
        autoindex_exact_size off; # 关闭计算文件确切大小（单位bytes），只显示大概大小（单位kb、mb、gb）
        autoindex_localtime on;   # 显示本机时间而非 GMT 时间
    }
}
```

重新加载：
```
nginx -s reload
```

