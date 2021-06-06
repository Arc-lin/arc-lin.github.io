title: iOS 底层原理 --- KVC
abbrlink: 34b9a649
tags:
  - iOS
  - 底层原理
categories:
  - iOS
author: Arclin
date: 2021-05-30 11:59:00
---
本文讲述KVC的底层实现和KVC是否能触发KVO呢？

<!--more-->

## KVC的使用


```
[self.person setValue:@10 forKey:@"age"]

[self.person setValue:@10 forKeyPath:@"age"]
```

keyPath和key的区别是，keyPath可以使用路径的方式进行赋值，比如person对象内有cat模型属性，cat对象里面有age属性，那么就可以使用`[self.person setValue:@10 forKeyPath:@"cat.age"]`的方式使用KVC，而key方式只支持直接访问的方式赋值

## 赋值过程

`setValue:forKey`首先会先寻找`setKey:`方法，如果找不到，那么就会寻找`_setKey:`方法，类似下面这样子

```
/// 优先找这个方法
- （void）setAge:(int)age {
	_age = age;
}

/// 找不到上面那个方法的话，就找下面这儿方法
- （void）_setAge:(int)age {
	_age = age;
}
```

如果上述两个方法都找不到，那么就会去访问类方法`+ (BOOL)accessInstanceVariablesDirectly`，询问是否允许直接访问成员变量，默认返回YES
	
  - 如果返回NO的话，那么程序会直接抛出异常`exception NSUnknownKeyException, reason:[XXX setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key age`

  - 如果返回YES，那么程序会去直接访问成员变量，查找的顺序是`_key、_isKey、key、isKey`，类似下面这样子
  
```
{
    @public 
    int _age;
    int _isAge;
    int age;
    int isAge;
}
```
  	
  1. 如果找到了成员变量，那么就直接赋值
  2. 如果找不到成员变量，那么就抛出上述异常
    
## KVC是否会触发KVO

由于KVO是通过重写set方法的方式实现的，所以如果KVC找到了属性值并且通过set方法赋值的话，那么就自然会触发KVO

如果KVC找不到set方法，如果`+ (BOOL)accessInstanceVariablesDirectly`返回YES的话，那么他去访问成员方法的时候，即便这时候成员方法是没有实现set方法的，KVC依旧会去执行`willChangeValueForKey:`和`didChangeValueForKey:`方法，在执行`didChangeValueForKey:`的时候，自然KVO就被触发了

## valueForKey:的底层原理

`valueForKey:`首先会根据`getKey、key、isKey、_key`顺序查找方法，找到了的话就调用，拿到返回值。

如果没有找到方法，那么就会去访问类方法`+ (BOOL)accessInstanceVariablesDirectly`，询问是否允许直接访问成员变量，默认返回YES

如果允许，那么按照`_key、_isKey、key、isKey`顺序查找成员变量，找到了的话就直接取值，找不到就抛出异常`NSUnknownKeyException`。

如果不允许，就抛出异常`NSUnknownKeyException`