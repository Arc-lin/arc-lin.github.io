---
title: ' UISplitViewController在竖屏情况下叫出PopoverView后Dissmiss崩溃的问题'
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 1787ee1c
date: 2016-11-09 00:00:00
---
UISplitViewController在竖屏情况下叫出PopoverView后Dissmiss崩溃

```
-[UIPopoverController dealloc] reached while popover is still visible.
```

<!-- more -->

错误的大体意思是：popover在仍旧可见的时候被销毁了（调用了dealloc）

从错误可以得出的结论
当popover仍旧可见的时候，不准销毁popover对象
在销
毁popover对象之前，一定先让popover消失（不可见）

```
@property (retain, nonatomic) UIPopoverController *popoverController;

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    self.popoverController = pc;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.popoverController dismissPopoverAnimated:YES];
    [super dismissViewControllerAnimated:YES completion:nil];
}
```