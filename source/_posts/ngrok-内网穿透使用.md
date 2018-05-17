---
title: ngrok 内网穿透使用
author: Arclin
tags:
  - ngrok
categories:
  - Linux
abbrlink: dda122f4
date: 2018-02-18 22:02:00
---
ngrok 内网穿透使用

<!-- more -->

### 安装golang

```
sudo yum install build-essential golang mercurial git
```

### 运行脚本

```
cd ~
git clone https://github.com/tutumcloud/ngrok.git ngrok
export NGROK_DOMAIN="ngrok.arclin.me"
cd ngrok
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN” -days 5000 -out rootCA.pem
openssl genrsa -out device.key 2048
openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN” -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
cp rootCA.pem assets/client/tls/ngrokroot.crt
cp device.crt assets/server/tls/snakeoil.crt
cp device.key assets/server/tls/snakeoil.key
GOOS=linux GOARCH=amd64
make release-server
cd /usr/lib/golang/src/
GOOS=darwin GOARCH=amd64 ./make.bash
cd ~/ngrok
GOOS=darwin GOARCH=amd64 make release-client
```

### 服务端运行脚本

```
nohup  bin/ngrokd -domain="ngrok.arclin.me" -httpAddr=":8081" -httpsAddr=":8082" &
```
> nohub 后台运行

### 客户端

新建 `./ngrok.cfg` 文件写入信息

```
server_addr:arclin.me:4443
trust_host_root_certs: false
```

客户端运行
```
./ngrok -config=./ngrok.cfg -subdomain=test 3000
```