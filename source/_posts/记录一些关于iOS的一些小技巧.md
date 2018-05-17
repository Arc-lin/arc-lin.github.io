---
title: 记录一些关于iOS的一些小技巧
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 1b8f24c7
date: 2016-06-12 00:30:00
---
记录一些关于iOS的一些小技巧

<!-- more -->

XCode Profile 的路径
xcode5 provisioning profile path： 
`~/Library/MobileDevice/Provisioning Profiles`

在升级XCode7.0使用UICollectionViewLayout进行自定义布局时，调试台会出现以下的警告打印。

```
UICollectionViewFlowLayout has cached frame mismatch for index path {length = 2, path = 0 - 0} - cached value: {{122, 15}, {170, 170}}; expected value: {{157, 50}, {100, 100}} 
This is likely occurring because the flow layout subclass LineLayout is modifying attributes returned by UICollectionViewFlowLayout without copying them
```

这个警告来源主要是在使用layoutAttributesForElementsInRect：方法返回的数组时，没有使用该数组的拷贝对象，而是直接使用了该数组。解决办法对该数组进行拷贝，并且是深拷贝。拷贝代码如下：

```
- (NSArray *)deepCopyWithArray:(NSArray *)array
{
    NSMutableArray *copys = [NSMutableArray arrayWithCapacity:array.count];

    for (UICollectionViewLayoutAttributes *attris in array) {
        [copys addObject:[attris copy]];
    }
    return copys;
}
```

将layoutAttributesForElementsInRect：方法返回的数组扔到这个方法中，并且使用返回后的数组就行了。

- 在navigationController中插入ScrollView后，scrollView的ContentInset的值发生了变化

	- 解决： self.automaticallyAdjustsScrollViewInsets = NO;
	- 原因： self.automaticallyAdjustsScrollViewInsets 默认值是YES，选择YES表示你允许视图控制器调整它内部插入的滑动视图来应对状态栏，导航栏，工具栏，和标签栏所消耗的屏幕区域。如果你设置为NO呢，就代表呀你要自己调整你插入的滑动视图，比如你的视图层次里面有多于一个的滑动视图。
这大概是个什么意思呢，就是你的视图控制器在没经你允许的情况下调整你的控件位置了