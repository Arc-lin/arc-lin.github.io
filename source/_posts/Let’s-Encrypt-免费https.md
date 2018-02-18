title: Let’s Encrypt 免费https
author: Arclin
tags:
  - Let's Encrypt
  - https
categories:
  - Linux
date: 2018-02-18 21:34:00
---
在服务器配置免费的CA证书

<!-- more -->

下载源码

```
git clone https://github.com/letsencrypt/letsencrypt
```

生成证书

```
cd letsencrypt/

./letsencrypt-auto certonly --standalone --email arclin@dankal.cn -d arclin.me -d g.arclin.me 
```

默认有效期90天

自动续期

```
./letsencrypt-auto certonly --renew-by-default --email arclin@dankal.cn -d arclin.me -d g.arclin.me
```

报错及解决

- 报错
Problem binding to port 443: Could not bind to IPv4 or IPv6.

- 解决
停止443端口
比如 关闭ShadowSocks服务(ssserver)  关闭nginx

- 报错 
Failed authorization procedure. arclin.me (tls-sni-01): urn:acme:error:connection :: The server could not connect to the client to verify the domain :: Connection refused

- 解决
在DNSPod 绑定 arclin.me域名到本服务器

修改Nginx 配置

```
server {
    server_name g.arclin.me;
    listen 80;
    listen 443 ssl http2; #443这里是https的端口  开启http2服务需要安装http_v2_module模块
    ssl_certificate /etc/letsencrypt/live/arclin.me/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/arclin.me/privkey.pem;
    resolver 8.8.8.8;
    location / {
        google on;
    }
  }
```

重启服务

```
nginx -c /usr/local/nginx/conf/nginx.conf
nginx -s reload
service nginx restart
```