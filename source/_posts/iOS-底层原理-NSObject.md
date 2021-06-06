title: iOS 底层原理 --- NSObject
author: Arclin
abbrlink: 70f61b87
tags:
  - iOS 
  - 底层原理
categories:
  - iOS
date: 2021-05-25 22:34:00
---
本文只是作为iOS底层原理课程的笔记用，所以均为结论性内容，如有疑问可在评论区进行探讨。

<!--more-->

##  NSObject的本质

### 一个NSObject对象占用16个字节。

验证方法

1. 初始化一个`NSObject`对象
	`NSObject *obj = [[NSObject alloc] init];`

2. 打印内存分配的量，得到16字节
	`malloc_size((__bridge const void *)obj)` 

3. 但是实际上只使用了8个字节，因为使用`class_getInstanceSize([NSObject class])`得到8

`class_getInstanceSize`计算出了NSObject对象内的成员变量（即isa）的占用内存大小

### NSObject实质上是一个结构体对象

大概长这样

```
struct NSObject_IMPL {
	Class isa;
}
```

因为成员变量isa永远是对象（NSObject的子类对象）的第一个成员变量，所以对象的地址就是成员变量isa的地址

### NSObject的子类

比如有这么一个类

```
@interface Student : NSObject
{
    @public
    int _no;
    int _age;
    int _height;
}
```

实例化一下

```
Student *stu = [[Student alloc] init];
```

`class_getInstanceSize([Student class])` 得到 24（意思为这个类至少需要的内存）
`malloc_size((__bridge const void *)stu)` 得到32（意思为系统分配给这个类的内存）

一般情况下我们更关心`malloc_size`得到的值

因为继承自`NSObject`，所以`Student`有一个`Class isa`属性，占用8个字节，`_no`、`_age`、`_height` 各占用4个字节，一共占用20个字节，

因为内存分配原则为**最大成员所占内存**（目前是isa 最大）的倍数，所以给够24个，这个叫做字节对齐

因为 `isa`、`_no`、`_age` 刚好够 16个字节了，这时候突然又来多了个`_height`，这时候就需要20个字节了 , 那么为了适配各个厂商的内存读取规则，又给他分配了16个（凑16的倍数），这个叫做内存对齐，所以一共给类分配了 32个字节

注：int 占用4个字节 double占用8个字节

分配原则：如果内存一行(16个字节)放不下，那么就直接开新的一行
比如

```
_no : Int 
_age : Double
_height : Int
```

第一行：`isa` :8个，`_no` 4个，第一行剩下4个字节的位置，不够放`_age`,但是够放`_height`，那就直接放`_height`，如果这时候`_height`是`Double`的话，没别的东西来占用这4个位置，那么就直接放弃，开辟下一行
第二行：前八个位置直接给`_age`

```
0x108b0bb00: d1 81 00 00 01 80 1d 01  <- isa   04 00 00 00 <- age   00 00 00 00  <- height ................
0x108b0bb10: 00 00 00 00 00 00 00 00  <- age 00 00 00 00 00 00 00 00  ................
```

### sizeof()

__sizeof()__方法是一个运算符，在编译期间就确定值，类似于宏替换，他的作用是计算传入的对象占用的内存的大小，如果传入的是类型（或者类名）的话，就计算类型占用的大小，比如传入一个对象的话，就是计算指向这个对象的指针的大小，指针占用的内存大小是8个字节，跟`class_getInstanceSize`的区别是`class_getInstanceSize`是计算类实例化后占用的大小。
