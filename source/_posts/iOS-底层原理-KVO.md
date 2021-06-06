---
title: iOS 底层原理 --- KVO
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: 81c45883
date: 2021-05-27 01:06:23
---

本文简述KVO的底层实现是怎么一回事

<!--more-->

# 如何使用KVO

举例

```
self.person = [[Person alloc] init];
self.person.age = 1;

/// 这个配置的值会直接影响监听方法的change字典里面带些什么值给你
NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;

[self.person addObserver:self keyPath:@"age" options:options context:@"123"];

```


```
/// 当监听对象的属性值发生改变时，就会调用这个方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	/// 这里的context就是注册监听的时候传入的@“123”
}
```

# 内部发生了什么

系统通过运行时机制，给`person`对象添加了一个父类，名为`NSKVONotifying_Person`(其他被监听的对象所生成的类也会遵循这个命名规则)，本质上是将`person`对象的isa指针指向了这个动态新建的类对象。

另外，这个新建的类对象是继承自`Person`的，也就是`NSKVONotifying_Person`的superclass指针指向了`Persond`的类对象。

# NSKVONotifying_*类内部结构

- isa指针
- superclass指针
- setAge:方法  因为监听的是age属性，所以重写了setAge方法，若监听的属性没有set方法，或者值改变的时候没有调用set方法，那么KVO无法生效
- class:方法，主要是为了防止对象调用class方法的时候得到了这个动态生成的类对象，所以重写class方法，返回真正`的Person`类对象
- _isKVOA方法，返回一个bool，用来判断这是不是一个KVO类
- dealloc 进行一些收尾工作

## 重写的set方法的实现

大概是这么实现的

```
- (void)setAge:(int)age {
   _NSSetIntValueAnyNotify();
}

void _NSSetIntValueAnyNotify() 
{
   [self willChangeValueForKey:@"age"];
   [super setAge:age];
   [self didChangeValueForKey:@"age"];
}

- (void)didChangeValueForKey:(NSString *)key {
   [observer observeValueForKeyPath:key ofObject:self change:nil context:nil];
}

```

这里的方法`_NSSetIntValueAnyNotify`，看具体监听的属性类型而定，如果监听的是`double`类型，那么方法就会变成`_NSSetDoubleValueAnyNotify`，所以系统内置了很多这种类似的方法，统称为`_NSSet*ValueAnyNotify`

- 调用流程

	1. willChangeValueForKey:
	2. setAge:
	3. observeValueForKeyPath:ofObject:change:context:
	4. didChangeValueForKey:


## 总结

- 利用Runtime API动态生成一个之类，并且让instance对象的isa指针指向这个全新的子类
- 当修改instance对象的属性时，会调用Foundation的_NSSetXXXValueAnyNotify函数
	- willChangeValueForKey:
	- 父类原来的setter
	- didChangeValueForKey:
		- 内部会触发监听器（Observer）的监听方法（observeValueForKeyPath:ofObject:change:context:）

- 如何手动触发KVO
	注册监听后，手动调用`willChangeValueForKey:`和`didChangeValueForKey:`
	
- 直接修改成员属性的值不会触发KVO，必须在前后分别补上`willChangeValueForKey:`和`didChangeValueForKey:`