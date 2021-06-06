---
title: frp 内网穿透
author: Arclin
tags:
  - frp
categories:
  - Linux
abbrlink: b72542c2
date: 2018-02-18 22:05:00
---
frp 内网穿透

<!-- more -->

[文档](https://github.com/fatedier/frp/blob/master/README_zh.md)

### 服务器CentOS下载安装

```
wget https://github.com/fatedier/frp/releases/download/v0.13.0/frp_0.13.0_linux_amd64.tar.gz
tar -zxvf frp_0.13.0_linux_amd64.tar.gz
cd frp_0.13.0_linux_amd64.tar.gz
rm -f frpc
rm -f frpc.ini
vi frps.ini
```

编辑frps.ini

```
[common]
vhost_http_port = 8001 # http访问端口
bind_port = 8009 # 远程响应的地址
dashboard_port = 8002 #控制面板端口号
# dashboard 用户名密码，默认都为 admin
dashboard_user = admin
dashboard_pwd = admin
```

### 启动服务端

```
./frps -c ./frps.ini
```

### Mac客户端下载

```
wget https://github.com/fatedier/frp/releases/download/v0.13.0/frp_0.13.0_darwin_amd64.tar.gz
tar -zxvf frp_0.13.0_darwin_amd64.tar.gz
cd frp_0.13.0_darwin_amd64.tar.gz
rm -f frps
rm -f frps.ini
vi frpc.ini
```

编辑frpc.ini

```
[common]
server_addr = 120.78.175.51 # 远程服务器地址
server_port = 8009 # 服务端填写的bind_port

[web]
type = http 
local_port = 3000 # 本地要映射的端口
custom_domains = frp.arclin.me # 自定义的域名,需要在dnspod绑定远程主机地址
```

### 客户端运行

```
 ./frpc -c ./frpc.ini
```