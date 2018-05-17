---
title: Nginx 内容替换模块 http_substitutions_filter_module
author: Arclin
tags:
  - nginx
categories:
  - Linux
abbrlink: e35ccdb6
date: 2018-02-18 22:16:00
---
在镜像了某个网站之后,想要改变这个网站上某些元素的显示内容, 这是我们可以使用nginx的一个第三方模块`http_substitutions_filter_module`

<!-- more -->

修改nginx配置文件
```
server {
    server_name g.arclin.me;
    listen 80;
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/arclin.me/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/arclin.me/privkey.pem;
    resolver 8.8.8.8;
    location / {
        subs_filter Google\s提供 Arclin提供 r;
        google on;
    }
  }
```