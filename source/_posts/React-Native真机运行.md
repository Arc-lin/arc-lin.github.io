---
title: React Native真机运行
author: Arclin
tags:
  - React Native
  - iOS
categories:
  - React Native
abbrlink: 7724d1af
date: 2017-03-08 00:00:00
---
三步即可

在项目根目录使用终端执行

```
$ curl http://localhost:8081/index.ios.bundle -o main.jsbundle
```

`AppDelegate.m` 找到这一行并注释

```
jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios&dev=true"];
```

`AppDelegate.m` 写上或反注释这一行

```
jsCodeLocation = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
```
