title: iOS 底层原理 --- 方法缓存、消息发送与super关键字
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: 5ed61a9
date: 2021-06-29 01:11:00
---
方法缓存、消息发送与super关键字
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: 5ed61a9
date: 2021-06-29 01:11:00
---
本文主要简述类（元类）对象里面的方法缓存、消息发送（包括消息发送，动态方法解析与消息转发）与super关键字的底层原理

<!--more-->

## 方法

### Class对象的结构

```
struct objc_class {
	Class isa;
    Class superclass;
    cache_t cache; // 方法缓存
    class_data_bits_t bits; // 用于获取具体的类信息
}
```

其中`bits`成员变量与`FAST_DATA_MASK`进行一次与运算之后，会获得一个其属性可读可写的对象的地址，这个对象长这样

```
struct class_rw_t {
	uint32_t flags;
    uint32_t version;
    const clsss_ro_t *ro;
    method_array_t * methods; // 方法列表
    property_array_t *properties; // 属性列表
    protocol_array_t protocols; // 协议列表
    Class firstSubclass;
    Class nextSiblingClass;
    char *demangledName;
}
```

其中 `class_ro_t`里面存放的是类的原始信息(不包括分类里面的东西)，是仅可读的，结构如下

```
struct class_ro_t {
	uint32_t flags;
    unit32_t instanceStart;
    uint32_t instanceSize; // instance对象占用的内存空间
#ifdef __LP__64__
	uint32_t reserved;
#endif
	const uint8_t *ivarLayout;
    const char * name; // 类名
    method_list_t * baseMethodList;
    protocol_list_t * baseProtocols;
    const ivar_list_t * ivars; // 成员变量列表
    const uint8_t * weakIverLayout;
    property_list_t * baseProperties;
}
```


### class_rw_t

`class_rw_t`里面的methods、properties、protocols是二维数组，是可读可写的，比如方法列表随时可以新增`method_list_t`类型的数据进去。`class_rw_t`包含了类的初始内容和分类的内容，其中方法列表类似如下结构

```
method_array_t: [
	method_list_t : [
      method_t,
      method_t,
      method_t
    ],
    method_list_t : [
      method_t,
      method_t,
      method_t
    ],
]
```

`objc_class`内有一个`data()`函数，其返回值一开始是指向`class_ro_t`类型的对象的。在合并分类内的内容时，才会产生`class_rw_t`类型的对象，并指向这个对象。可以参考runtime源码，`objc-runtime-new.mm`中`realizeClassWithoutSwift`函数的实现

### class_ro_t

`class_ro_t`里面的baseMethodList、baseProtocols、ivars、baseProperties是一维数组，是只读的，所以不能新增内容，包含了类的初始内容，其中方法列表类似如下结构

```
method_list_t : [
  method_t,
  method_t,
  method_t
]
```

> 在runtime源码，`objc-runtime-new.mm`中的`attachCategories`方法中我们可以看到分类合并到`class_rw_t`对象的过程

### method_t

- `method_t`是对方法/函数的封装

```
struct method_t {
	SEL name; // 函数名
    const char; // 编码（返回值类型、参数类型）
    IMP imp; // 指向函数的指针（函数地址）
}
```

- `IMP`代表具体函数的实现

	`typedef id _Nullable (*IMP)(id _Nonnull, SEL _Nonnull, ...);`

- `SEL`可以代表方法\函数名，一般叫做选择器，底层结构跟`char *`类似
	
    `typedef struct objc_selector *SEL`;
    - 可以通过`@selector()`和`sel_registerName()`获得
	- 可以通过`sel_getName()`和`NSStringFromSelector()`转成字符串
	- 不同类中相同名字的方法，所对应的方法选择器是相同的

- `types`包含了函数返回值、参数编码的字符串，称作`Type Encodings`，具体可以参考[苹果官方文档](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100)

	- 比如`-（void）test:(int)a;`的方法编码为`v@:i`，v = void,@表示指针变量(因为编译后第一个参数是self)，：表示选择器(因为编译后第二个参数是_cmd)，i表示int