---
title: pop后强制竖屏
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 50c5f6e6
date: 2016-10-17 00:00:00
---
pop之后强制竖屏

<!-- more -->

`AppDeleagte.h`

```
// 控制全部不支持横屏，当allowRotation为YES的时候可以横/竖屏切换
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if (self.allowRotation) {
        return  UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}
```

pop之后强制竖屏

```
- (void)viewDidAppear:(BOOL)animated
{
     [super viewDidAppear:animated];
    
    // 强制竖屏
    [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
}
```