---
title: 发现一个api
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 54b26395
date: 2016-10-17 00:00:00
---
发现一个好用的api，用于找出selectedItem 在 dataSource 里面的位置，适用于tableView和collectionView

```
NSIndexSet *indexSet = [self.photos indexesOfObjectsPassingTest:^BOOL(DKPhoto * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([self.selectedPhotoArray containsObject:obj]) {
        return YES;
    }
    return NO;
}];
```