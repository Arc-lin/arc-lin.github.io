---
title: iOS 底层原理 --- instance、class和meta-class
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: fdd98f42
date: 2021-05-26 00:22:27
---

本文讲的是实例对象(instance)，类对象(class)，元类对象（meta-class）的内容和他们之间的联系

<!--more-->

# 实例对象

实例对象内存储着成员变量的值

# class对象

## class对象的基本内容

每个类在内存中有且只有一个class对象

class对象在内存中，存储的信息主要包括

- isa指针
- superclass指针
- 类的属性信息（@property）、 类的对象方法信息（instance method）
- 类的协议信息（protocol）、类的成员变量信息（ivar）


## class对象的结构

```
rw: readwrite
ro: readonly
t:   table
```

```
struct objc_class {
	Class isa;
	Class superclass;
	cache_t cache; 	// 方法缓存
	cache_data_bits_t bits; // 用于获取具体类信息
	
	class_rw_t *data() {
	   return bits.data();  //  实际方法实现为 bits & FAST_DATA_MASK  结果返回值为 class_rw_t类型的对象
	}
}

struct class_rw_t {
	unit32 flags;
	unit32 version;
	const class_ro_t *ro;			// 方法列表
	property_list_t *properties;		// 属性列表
	const protocol_list_t *protocols;	// 协议列表
	Class firstSubclass;
	Class nextSiblingClass;
	chat *demangledName;
};

struct class_ro_t {
	uint32_t flags;
	unit32_t instanceStart;
	unit32_t instanceSize; 			// instance对象占用的内存空间
	
	const uint8_t * ivarLayout;
	const chat * name; 			// 类名
	method_list_t  * baseMethodList;
	protoocl_list_t * baseProtocols;
	const ivar_list_t *ivars;		  // 成员变量列表
	const uint8_t *weakIverLayout;
	property_list_t *baseProperties;
}
```

## 相关的几个函数

1. `Class objc_getClass(const chat *aClassName)`
    1. 传入字符串类名
    2. 返回对应的类对象
    
2. `Class object_getClass(id obj)`获取isa指向的对象
    1. 传入的obj可能是instance对象、class对象、meta-class对象
    2. 返回值
        1. 如果是instance对象，返回class对象
        2. 如果是class对象，返回meta-class对象
        3. 如果是meta-class对象，返回NSObject（基类）的meta-class对象
        
3.  `- (Class)class`、`+ (Class)class` 返回的就是类对象

# meta-class对象

意思是用来描述类对象的对象，是一种特殊的类对象。

每个类在内存中有且只有一个meta-class对象

meta-class对象和class对象的内存接口是一样的，但是用途不一样，在内存中存储的信息主要包括

- isa指针
- superclass指针
- 类的类方法信息

# isa指针和spuerclass指针

<img src="https://i.loli.net/2021/05/26/pjxbn5vQ17hrmae.png" width="50%">


## isa指针

instance的isa指向class

> 当调用对象方法时，通过instance的isa找到class，最后找到对象方法的实现进行调用

class的isa指向meta-class

> 当调用类方法时，通过class的isa找到meta-class，最后找到类方法的实现进行调用 

meta-class的isa指向基类（NSObject）的meta-class（NSObject的meta-class的isa指向自己的meta-class）

## superclass指针

举个例子，比如Student类继承自Person类，Person类继承自NSObject类：

Student的class的superclass指针指向父类的class对象，如果没有父类（NSObject），则superclass指针为空

Student的meta-class对象的superclass指针指向Person的meta-class

基类（NSObject）的meta-class的superclass指针指向class对象

### 调用成员方法

因为Student要调用成员方法的时候，需要找到class对象，因为class对象才存放着成员方法，找不到的话就通过superclass指针找到父类class对象看看里面有没有想要的成员方法

### 调用类方法

当Student要调用Student的类方法的时候，就通过Student的class对象的isa找到Student的meta-class对象，然后找到类方法进行调用

当Student要调用Person的类方法的时候，就得先通过Student的class对象的isa找到Student的meta-class对象，然后通过Student的mata-class对象里面的superclass指针找到Person的meta-class对象，然后在里面找到Person的类方法进行调用

### 调用init方法

比如现在Student对象要调用init方法，流程如下
1. 先通过对象自己的isa指针，找到Student的类对象
2. Student的类对象里面有superclass指针，那么就通过superclass指针拿到了Person的类对象
3. Person的类对象里面也有superclass指针，那么就通过superclass指针拿到NSObject的类对象
4. NSObject的类对象里面找到了init方法的相关信息，那么就可以进行调用了

### 调用不存在的类方法

Student调用一个不存在的类方法流程
1. 通过isa指针找到类对象
2. 类对象的isa指针找到meta-class对象
3. meta-class找不到该类方法，通过superclass指针找到父类的meta-class对象
4. 一直找，直到找到基类的meta-class对象，基类的meta-class的superclass指向基类的class对象
5. 基类的class对象里面有对象方法，如果对象方法刚好跟准备调用的类方法同名，那么则会调用该对象方法，如果找不到，则开始抛出异常

## ISA_MASK

```
#if __arm64___
#define ISA_MASK 0x000000ffffffff8ULL
#elif __x86_64__
#define  ISA_MASK 0x00007ffffffffff8ULL
#endif
```

实例对象从64位系统开始，isa不直接指向类对象的地址，isa需要进行一次位运算，才能计算出真实地址

```
instance的 isa & ISA_MASK -> class对象
class的isa & ISA_MASK -> meta_class 对象
```



