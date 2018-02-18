title: docker笔记
author: Arclin
tags:
  - docker
categories:
  - Linux
date: 2018-02-18 22:19:00
---
docker学习笔记

<!-- more -->

docker是一种类似虚拟机的存在


// 查看本机docker信息

`docker info`

// 运行hello world

`docker run centos:6.7 /bin/echo "Hello World"`

//  -t 进入伪终端
//  -i 允许你对容器内的标准输入 (STDIN) 进行交互。 

`docker run -i -t centos:6.7 /bin/bash`

// -d 后台模式

` docker run -d centos:6.7 /bin/sh -c "while true;do echo hello world; sleep 1; done"`

//  查看当前运行的容器

`docker ps`

// -l 最近创建的容器

`docker ps -l`

// -a 所有容器

`docker ps -a`

// 查看运行log

`docker logs 2b1b7a428627`

//或

`docker logs angry_austin`

// 具体参数看ps的内容进行替换

// 停止容器

`docker stop angry_austin`


// 删除容器

`docker rm awesome_bardeen`

// 进入容器终端 允许标准输入

`docker exec -it practical_fermat /bin/bash`

中间的参数是容器名

// 拉取镜像 (如:httpd)

`docker pull httpd`

// 指定端口运行容器

`docker run -d -p 5000:5001 httpd`

// 提交新的镜像并添加tag v2 

`docker commit -m "has update" -a="arclin" 000c5746fa52 arclin/centos:v2`

// 添加标签dev  中间那串是容器id

`docker tag d 607e5fac1115 arclin/centos:dev`

// 删除标签 6.7

`docker rmi -f arclin/centos:6.7`


// 指定端口运行  8080 是本地端口 80是容器端口 -d 是后台运行的意思

`docker run -d -p 8080:80 httpd`

// 随机端口运行 -P

`docker run -d -P  httpd`

// 查看容器practical_fermat的80端口被绑定到本机的哪个端口上了

`docker port practical_fermat 80`

// 运行的时候顺便给容器命名

`docker run -d -P --name testName httpd`

// 给容器重命名

`docker rename practical_fermat test_httpd`

// 运行nginx
```
docker run -p 81:80 --name mynginx -v $PWD/www:/www -v 

$PWD/conf/nginx.conf:/etc/nginx/nginx.conf -v $PWD/logs:/wwwlogs  -d nginx  
-p 81:80：将容器的80端口映射到主机的81端口
--name mynginx：将容器命名为mynginx
-v $PWD/www:/www：将主机中当前目录下的www挂载到容器的/www
-v $PWD/conf/nginx.conf:/etc/nginx/nginx.conf：将主机中当前目录下的nginx.conf挂载到容器的/etc/nginx/nginx.conf
-v $PWD/logs:/wwwlogs：将主机中当前目录下的logs挂载到容器的/wwwlogs
```

// 查看nginx的文件系统

`docker inspect mynginx | grep Mounts -A 20`


// 安装Apache

`mkdir -p  ~/apache/www ~/apache/logs ~/apache/conf `

// 运行Apache

`docker run -p 80:80 -v $PWD/www/:/usr/local/apache2/htdocs/ -v $PWD/conf/httpd.conf:/usr/local/apache2/conf/httpd.conf -v $PWD/logs/:/usr/local/apache2/logs/ -d httpd`


// 删除所有容器

`sudo docker rm $(docker ps -a -q)`

// 下载容器内的文件

`docker cp ecef8319d2c8:/root/test.txt /root/`

// 上传文件到容器中

`docker cp /root/test.txt ecef8319d2c8:/root/`
