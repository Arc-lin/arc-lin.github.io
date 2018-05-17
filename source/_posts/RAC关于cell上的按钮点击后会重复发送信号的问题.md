---
title: RAC关于cell上的按钮点击后会重复发送信号的问题
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 452efb32
date: 2016-10-17 00:00:00
---
关于cell上的按钮点击后会重复发送信号的问题

RAC给`UITableViewCell`提供了一个方法：`rac_prepareForReuseSignal`，它的作用是当Cell即将要被重用时，告诉Cell。想象Cell上有多个button，Cell在初始化时给每个button都`addTarget:action:forControlEvents`，被重用时需要先移除这些target，下面这段代码就可以很方便地解决这个问题：

```
[[[self.cancelButton
    rac_signalForControlEvents:UIControlEventTouchUpInside]
    takeUntil:self.rac_prepareForReuseSignal]
    subscribeNext:^(UIButton *x) {
    // do other things
}];
```