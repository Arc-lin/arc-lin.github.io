---
title: pod install速度慢的终极解决方案
tags:
  - iOS
  - Cocoapods
  - 技巧
categories:
  - iOS
abbrlink: 826fbbdd
date: 2020-04-01 10:13:48
---

相信大家已经感受到pod install速度越来越慢了，网上提供了几种解决方案，但是都没有完全解决速度慢的问题。

<!-- more -->

[原博文](https://blog.csdn.net/iotjin/article/details/81604034)已经被删掉了，所以我自己copy并整理了一份

相信大家已经感受到pod install速度越来越慢了，网上提供了几种解决方案，但是都没有完全解决速度慢的问题。

使用国内镜像的Specs
在pod install时使用命令
`pod install --no-repo-update`

使用proxychains使终端命令走代理
下面就来说明一下这几种方法为何没有完全解决问题

使用国内镜像的Specs
这个只是加快了Specs下载更新速度，而且如果使用国内镜像Specs，那么Podfile中就必须指明使用这个Specs。

在pod install时使用命令
`pod install --no-repo-update`

install时不更新本地库，但如果第一次install还是要去github clone代码

使用proxychains使终端命令走代理

这个只是使pod命令走代理，git download的时候不会走代理
其实真正慢的原因并不在pod命令，而是在于github上的代码库访问速度慢，那么就知道真正的解决方案就是要加快git命令的速度。

我使用Shadowsocks代理，默认代理端口为1080，配置好代理之后去终端输入git配置命令，命令如下

`git config --global http.proxy socks5://127.0.0.1:1080`

> 注意这里的 socks5:// 协议 如果你用的是http/https协议 这里要改成 http:// 或https://

> 这里的http.proxy 一般不用改

> 查看端口号的方式可以在小飞机那里或者其他翻墙软件点击配置信息查看，看本地端口号一项

上面的命令是给git设置全局代理，但是我们并不希望国内git库也走代理，而是只需要github上的代码库走代理，命令如下

`git config --global http.https://github.com.proxy socks5://127.0.0.1:1080`

> 这里的socks5:// 协议 跟上面说的同理

（ps：如果要恢复/移除上面设置的git代理，使用如下命令
`git config --global --unset http.proxy`
`git config --global --unset http.https://github.com.proxy`)

（如果不恢复的话，你一旦关掉代理（小飞机），那么之后git命令都跑不了网络了）

> 注意这里的 http.proxy 其实就是上面的`git config --global http.proxy socks5://127.0.0.1:1080`中的 http.proxy, 如果你写的是https.proxy，那么这里unset的时候应该也写https.proxy