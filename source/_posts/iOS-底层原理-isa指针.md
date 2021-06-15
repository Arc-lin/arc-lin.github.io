title: iOS 底层原理 --- isa指针
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: 78ececc4
date: 2021-06-14 15:26:00
---
本文讲述isa指针在runtime内部的底层实现和isa的优化方式

<!-- more -->

## isa指针的底层实现

- 在arm64架构出现之前，isa就是一个普通的指针(`Class isa`)，存储着Class,Meta-Class对象的内存地址

- 从arm64架构开始，对isa进行了优化，变成了一个共用体，还使用位域来存储更多的信息

- isa指针的结构如下（objc4-818.2）

```
union isa_t {
    isa_t() { }
    isa_t(uintptr_t value) : bits(value) { }
    uintptr_t bits;

private:
    Class cls;

public:
    struct {
        uintptr_t nonpointer        : 1; 
        uintptr_t has_assoc         : 1;
        uintptr_t has_cxx_dtor      : 1;
        uintptr_t shiftcls          : 33;
        uintptr_t magic             : 6;
        uintptr_t weakly_referenced : 1;
        uintptr_t unused            : 1;
        uintptr_t has_sidetable_rc  : 1;
        uintptr_t extra_rc          : 19
    };

    bool isDeallocating() {
        return extra_rc == 0 && has_sidetable_rc == 0;
    }
    void setDeallocating() {
        extra_rc = 0;
        has_sidetable_rc = 0;
    }

    void setClass(Class cls, objc_object *obj);
    Class getClass(bool authenticated);
    Class getDecodedClass(bool authenticated);
};

```

首先，共用体同结构体一样，是拥有成员变量的，但是不同的点在于所有成员变量共用一块内存，也就是说当一个成员变量有值时，其他成员变量都成了装饰。

在runtime中，我们只需要用到`uintptr_t bits`，`uintptr_t`是`unsigned long`的别名，在64位系统下占用8个字节，共64位

共用体内的`struct { ... }` 是为了增加可读性而添加的，它描述了`bits`里面存放了什么信息，我们一个个说明一下

> 补充说明： 结构体内的冒号后面的数字表示这个成员所占的位数，举个例子，本来`char name`作为一个成员变量，是会占用一个字节，也就是8个二进制位，如果有3个这样子的成员变量，那么这个结构体就会占用3个字节，如果我们在这个成员变量的后面添加了一个数字，去限制这个成员变量所占的位数，比如`char name : 1`，那么三个这样子的成员变量就一共占用3个二进制位，也就是不到一个字节，因为系统分配内存的最小单位为1个字节，所以这个结构体就占用1个字节，这么做我们就可以节约2个字节了，这种技术叫做**位域**。

- nonpointer
	- 0代表普通的指针，存储着Class、Meta-Class对象的内存地址
    - 1代表优化过，使用位域存储着更多的信息
    
- has_assoc
	- 是否有设置过关联对象（注意是“设置过”，就算以后关联对象移除了，它还会是true），如果没有，会释放得更快
    
- has_cxx_dtor
	- 是否有C++的析构函数（.cxx_destruct），如果没有，会释放得更快
   
上面两个`会释放得更快`的原因是，在对象销毁的时候，会调用runtime里面的这个方法

```
void *objc_destructInstance(id obj) 
{
    if (obj) {
        // Read all of the flags at once for performance.
        bool cxx = obj->hasCxxDtor();
        bool assoc = obj->hasAssociatedObjects();

        // This order is important.
        if (cxx) object_cxxDestruct(obj);
        if (assoc) _object_remove_assocations(obj, /*deallocating*/true);
        obj->clearDeallocating();
    }

    return obj;
}
```

可以看到如果`has_assoc`或者`has_cxx_dtor`的话，就不会进入判断为true的逻辑，函数会运行得更快

- shiftcls
	- 存储着Class、Meta-Class对象的内存信息
    
- magic
	- 用于在调试时分辨对象是否未完成初始化
    
- weakly_referenced
	- 是否有被弱引用指向过（同样注意“指向过”，有过即为true），如果没有，释放时会更快
    
“会释放得更快”是因为对象销毁时调用了如下runtime源码

```
NEVER_INLINE void
objc_object::clearDeallocating_slow()
{
    ASSERT(isa.nonpointer  &&  (isa.weakly_referenced || isa.has_sidetable_rc));

    SideTable& table = SideTables()[this];
    table.lock();
    if (isa.weakly_referenced) {
        weak_clear_no_lock(&table.weak_table, (id)this);
    }
    if (isa.has_sidetable_rc) {
        table.refcnts.erase(this);
    }
    table.unlock();
}
```

- deallocating
	- 对象是否正在释放
    
- extra_rc 
	- 里面存储的值是引用计数器减1后的值
    
- has_sitdtable_rc
	- 引用计数器是否过大无法存储在isa中
    - 如果为1，那么引用计数器会存储在一个叫做SideTable的类的属性中
    
## 如何从isa指针中取出对应的信息

isa是通过位运算来取出和存入信息的。

- 我们以取出`shiftcls`内的类信息为例

首先isa里面的bits存储着64个二进制位，然后其中`shiftcls`是使用了33个（从上面的共用体里面的位域看出），当系统需要取出对应信息的时候，就使用`ISA_MASK`（ISA掩码）跟bits做一次与运算，举个例子，bits的十六进制地址为`0x011d8001000083a5`

>补充： ISA_MASK在arm64下的值为`0x0000000ffffffff8ULL`，下面我们把他转成二进制

||8|16|24|32|40|48|56|64|
|---|---|---|---|---|---|---|---|---|
|bits<br>(0x011d8001000083a5)|1010 0101|1100 0001|0000 0000|0000 0000|1000 0000|0000 0001|1011 1000|1000 0000|
|ISA_MASK<br>(0x0000000ffffffff8)|0001 1111|1111 1111|1111 1111|1111 1111|1111 0000|0000 0000|0000 0000|0000 0000|
|与运算后的结果<br>(0x00000001000083a0)|0000 0101|1100 0001|0000 0000|0000 0000|1000 0000|0000 0000|0000 0000|0000 0000|

我们可以来验证一下

<img src="https://z3.ax1x.com/2021/06/15/2qoart.png" width="80%">


可以看到 isa一开始的值跟`[person class]`的值是不相同的，跟`ISA_MASK`进行一次与运算之后就相同了，所以可以看出实例对象的isa不是直接指向类对象的，是需要进行一次运算取出来的。

- 其他的信息如`nonpointer`等，取出的方式也类似这样，这么做的好处是充分利用了64个二进制位的内存，而不用像以前一样一个属性就占用了多个字节，造成二进制位的浪费。


    