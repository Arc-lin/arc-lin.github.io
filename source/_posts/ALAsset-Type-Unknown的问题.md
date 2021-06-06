---
title: 'ALAsset-Type:Unknown的问题'
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: a8ea2211
date: 2016-10-17 00:00:00
---
- 利用ALAssetsLibrary时候，将得到的`ALAsset`存到数组里，会出现`ALAsset - Type:Unknown, URLs:(null)`的问题

解决方案：初始化ALAssetsLibrary的时候，不要用alloc-init，用一个单例，如下：

```
+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred,
                  ^{
                      library = [[ALAssetsLibrary alloc] init];
                  });
    return library;
}
```