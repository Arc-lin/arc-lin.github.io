---
title: NavigationController的RootViewController和子ViewController的状态栏颜色不一样或者状态栏显示异常
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: cacc49a3
date: 2016-10-17 00:00:00
---
如果NavigationController的状态栏颜色跟子ViewController的状态栏颜色不一样，那么就像下面这么写

在UINavigationController的子类写这个

```
- (UIViewController *)childViewControllerForStatusBarStyle{
    return self.topViewController;
}
```