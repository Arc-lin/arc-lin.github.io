title: 安装shadowsocks服务端
author: Arclin
tags:
  - Shadowsocks
categories:
  - Linux
date: 2018-02-18 22:15:00
---
安装shadowsocks服务端

<!-- more -->

```
sudo yum install python-pip
sudo pip install shadowsocks
```

配置文件

```
{
 "server”:”172.93.xx.xx”, # 服务器IP 
 "server_port":8388, # 端口号
 "local_address": "127.0.0.1",
 "local_port”:1080,
 "password":"gtPtAb)Wsss", # 密码
 "timeout":300,
 "method":"aes-256-cfb",# 加密类型
 "fast_open": false
}
```