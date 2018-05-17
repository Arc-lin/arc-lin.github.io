---
title: nginx 镜像谷歌
author: Arclin
tags:
  - nginx
categories:
  - Linux
abbrlink: a6a89073
date: 2018-02-18 22:12:00
---
nginx 镜像谷歌

<!-- more -->

安装nginx第三方模块

下载->解压->编译

```
wget  http://artfiles.org/openssl.org/source/openssl-1.1.0g.tar.gz
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.39.tar.gz
wget http://zlib.net/zlib-1.2.11.tar.gz

git clone https://github.com/nginx/nginx.git
git clone https://github.com/cuber/ngx_http_google_filter_module
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module

tar -zxvf openssl-1.1.0g.tar.gz 
tar -zxvf pcre-8.39.tar.gz 
tar -zxvf zlib-1.2.11.tar.gz

cd nginx

./auto/configure --with-http_v2_module --with-pcre=../pcre-8.39 --with-openssl=../openssl-1.1.0g --with-zlib=../zlib-1.2.11 --with-http_ssl_module --add-module=../ngx_http_google_filter_module --add-module=../ngx_http_substitutions_filter_module

make -j 4

sudo make install
```

修改配置文件

`vi /usr/local/nginx/conf/nginx.conf`

```
server {
    server_name g.arclin.me;
    listen 80;
    resolver 8.8.8.8;
    location / {
        google on;
    }
}
```

重启nginx

```
nginx -s reload
service nginx restart
```

reload 时发生错误

```
nginx: [error] open() "/var/run/nginx.pid" failed (2: No such file or directory)
```

解决

```
nginx -c /usr/local/nginx/conf/nginx.conf
```
