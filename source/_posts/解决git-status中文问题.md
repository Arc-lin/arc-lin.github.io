---
title: 解决git status中文问题
author: Arclin
tags:
  - 技巧
  - git
categories:
  - Git
abbrlink: 93da1b70
date: 2017-08-08 00:00:00
---
在中文情况下`git status`是 `\344\272\247\345\223\201\351\234\200\346\261\202` 差不多这样的。

解决这个问题方法是：

`git config --global core.quotepath false`