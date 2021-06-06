---
title: pan手势判断方向
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 34db2dbc
date: 2016-10-17 00:00:00
---
pan手势判断方向

```
UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
CGPoint point = [pan translationInView:gestureRecognizer.view]; // point.x < 0 左滑
```