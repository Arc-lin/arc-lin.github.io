title: iOS 底层原理 --- Category、+load、+initialize和关联对象
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: 2397c268
date: 2021-06-06 22:24:00
---
本文简述iOS中分类的底层实现和load方法、initialize方法在类和分类中的调用特性，还有如何通过关联对象的方式给分类添加属性，以及关联对象的底层实现原理

<!--more-->


## 分类（Category）

### 先写一个Demo

新建一个命令行工程，在main.m中写几个类


父类：写一个run方法

```
@interface Person : NSObject

- (void)run;

@end
```

父类的分类：写一个eat方法

```
@interface Person(Test) 

- (void)eat;

@end

```

根据经验可知道，现在Peron对象拥有了run方法和eat方法

### 分类的底层结构

输入命令行

`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m`

接下来同级目录下就会多出一个编译后的文件`main.cpp`，查看后发现`Person(Test) `分类被编译成了如下变量

```
static struct _category_t _OBJC_$_CATEGORY_Person_$_Test __attribute__ ((used, section ("__DATA,__objc_const"))) = 
{
	"Person",
	0, // &OBJC_CLASS_$_Person,
	(const struct _method_list_t *)&_OBJC_$_CATEGORY_INSTANCE_METHODS_Person_$_Test,
	0,
	0,
	0,
};
```

这个变量的类型是`static struct _category_t`，名字是`_OBJC_$_CATEGORY_Person_$_Test`，等于号后面是一个初始化结构体的过程，可以看到要实例化这个结构体需要6个参数，所以查看`_category_t`的结构如下

```
struct _category_t {
	const char *name; /// 原来的类的名字
	struct _class_t *cls; /// 类对象
	const struct _method_list_t *instance_methods; /// 实例方法数组
	const struct _method_list_t *class_methods; /// 类方法数组
	const struct _protocol_list_t *protocols; /// 遵循的协议数组
	const struct _prop_list_t *properties; /// 属性数组
};
```

由此可知，**分类可以定义实例方法，可以定义类方法，可以遵循协议，可以添加属性，但是不能添加成员变量！因为分类的结构里面没有存储成员变量的地方.**

### 程序通过runtime动态将分类合并到类对象、元类对象中

分类中的方法是在运行时才添加到类对象和元类对象中的，而不是编译的时候添加的，编译之后只是多了几个类型为`_category_t`的结构体变量。

合并的过程可以在runtime源码（objc4-818.2）中`objc-runtime-new.mm`的`load_categories_nolock`函数中看到，这里不展开流程，直接说结论。

合并过程是这样子的，首先我们知道原来的类（我们就叫他主类吧）对象是存放着成员方法的，主类的元类对象是放着类方法的，因为类对象和元类对象结构是一样的，所以我们就讨论成员方法就好了。

其次呢，runtime先根据分类方法的数量在数组里面开辟空间，然后把分类方法塞到原来的成员方法数组的前端，这样子合并就完成了，其他类方法、协议、属性等数组，也是同样的过程。

所以最后在**类对象的方法列表数组里面，排在前面的是分类方法，后面才是主类的方法。如果有多个分类的话，那么后编译的分类的成员方法会插在数组的前面（因为插入数组的时候是倒序插入）**。

有了上述结论 我们就可以解释很多事情了。

#### 如果分类实现了主类的方法会怎么样

根据上述结论，系统在找对应的调用方法的时候，会先找到分类的方法，所以主类的方法没有机会被调用到。

#### 如果多个分类都实现了同个主类的方法

根据上述结论，后编译的分类的成员方法会插在方法列表的前面，所以谁后编译，就调用谁

#### 如果子类或者子类的分类实现了父类的分类方法

根据上述结论和结合我们以前所学知识，最后子类实例对象会去子类的类对象里面寻找方法并调用，使用`super`关键字调用方法的话，则会去到父类的类对象内找方法。

### Category跟Class Extension的区别

- Class Extension是编译的时候，它的数据就已经包含在类信息中
- Category 是在运行时才会讲数据合并到类信息中


## load方法


### 先写一个Demo


父类：实现load方法

```
@implementation Person

+ (void)load {
    NSLog(@"Person load");
}

@end
```

父类的分类：实现load方法

```
@implementation Person(Test)

+ (void)load {
    NSLog(@"Person Text load");
}

@end

```

子类：实现load方法

```
@implementation Student

+ (void)load {
    NSLog(@"Student load");
}

@end

```

子类的分类：实现load方法

```
@implementation Student(Test)

+ (void)load {
    NSLog(@"Student Test load");
}

@end
```

### load方法的调用时机

通过runtime源码（objc4-818.2）`objc-runtime-new.mm`第3233行得知，load方法是在加载镜像(load_images)的时候调用的。

```
void load_images(const char *path __unused, const struct mach_header *mh)
{
    if (!didInitialAttachCategories && didCallDyldNotifyRegister) {
        didInitialAttachCategories = true;
        loadAllCategories();
    }

    // Return without taking locks if there are no +load methods here.
    if (!hasLoadMethods((const headerType *)mh)) return;

    recursive_mutex_locker_t lock(loadMethodLock);

    // Discover load methods
    {
        mutex_locker_t lock2(runtimeLock);
        prepare_load_methods((const headerType *)mh);
    }

    // Call +load methods (without runtimeLock - re-entrant)
    call_load_methods();
}

```

> 补充小细节：从`load_images`函数可以看到，加载分类`loadAllCategories()`早于调用load方法`call_load_methods()`，也就是元类对象中的类方法列表内，分类的load方法会在主类的load方法之前

在调用load方法之前，首先要通过`prepare_load_methods`函数整理出一个数组，这个数组会决定主类的load方法的调用顺序

从`prepare_load_methods`函数中调用的`schedule_class_load`函数的内部实现我们可以知道，父类会先被加入到数组中，其次才是主类。

```
/***********************************************************************
* prepare_load_methods
* Schedule +load for classes in this image, any un-+load-ed 
* superclasses in other images, and any categories in this image.
**********************************************************************/
// Recursively schedule +load for cls and any un-+load-ed superclasses.
// cls must already be connected.
static void schedule_class_load(Class cls)
{
    if (!cls) return;
    ASSERT(cls->isRealized());  // _read_images should realize

    if (cls->data()->flags & RW_LOADED) return;

    // Ensure superclass-first ordering
    schedule_class_load(cls->getSuperclass());

    add_class_to_loadable_list(cls);
    cls->setInfo(RW_LOADED); 
}
```

然后我们回到最开始的地方（load_images），通过`objc-loadmethod.mm`第337行`call_load_methods`得知，先调用主类的load方法(call_class_loads())，再调用分类的load方法`call_category_loads();`


> 补充一个小细节：在整理数组的时候，这个数组里面存放的是一个个结构体，结构体长这样

  ```
  struct loadable_class {
      Class cls;  // may be nil  这里放元类对象（load是类方法所以存在元类对象里面）
      IMP method;  /// 这里放的是load方法的函数指针
  };

  struct loadable_category {
      Category cat;  // may be nil 这个是上面讲到的category_t类型的对象
      IMP method; /// 这里放的是load方法的函数指针
  };
  ```
  
注意：runtime代码内有记录类的load方法是否曾经被加入到load数组过（RW_LOADED），如果被调用过了，就会跳过，这就是load方法只会执行一次的原因（但是你要是非要手动调用load方法那还是会执行的）
  
**重要：系统调用load方法不通过消息发送机制**，可以查看`objc-loadmethod.mm`第177行如下

```
/***********************************************************************
* call_class_loads
* Call all pending class +load methods.
* If new classes become loadable, +load is NOT called for them.
*
* Called only by call_load_methods().
**********************************************************************/
static void call_class_loads(void)
{
    int i;
    
    // Detach current loadable list.
    struct loadable_class *classes = loadable_classes;
    int used = loadable_classes_used;
    loadable_classes = nil;
    loadable_classes_allocated = 0;
    loadable_classes_used = 0;
    
    // Call all +loads for the detached list.
    for (i = 0; i < used; i++) {
        Class cls = classes[i].cls;
        load_method_t load_method = (load_method_t)classes[i].method;
        if (!cls) continue; 

        if (PrintLoading) {
            _objc_inform("LOAD: +[%s load]\n", cls->nameForLogging());
        }
        /// 意为直接通过函数指针调用函数
        (*load_method)(cls, @selector(load));
    }
    
    // Destroy the detached list.
    if (classes) free(classes);
}
```



### load方法的调用顺序

综上所述，分类也有load方法。调用顺序是：先调用父类load方法，再调用子类load方法，最后调用分类的load方法，如果有多个分类，那么先编译的，先调用。


所以上述Demo代码执行后输出结果为

```
Person load
Student load
Person Test load
Student Test load
```

这里Person比Student先调用是因为他是父类，Person(Test)比Student(Test)先调用是因为它先编译

### 综上所述

于是我们可以解答下面的问题

1. 类和分类都有+load方法
2. 根据编译顺序，先调用父类+load，再调用子类+load，再调用分类+load(看编译顺序)
3. 因为系统调用load方法时不通过消息发送机制，所以不存在子类load方法覆盖父类load方法的情况，但是，如果手动调用load方法（即通过消息发送机制调用方法），那么这时候就有继承的现象发生了，也就是子类会覆盖父类方法的实现。

搞点复杂的事情

1. 父类实现，父类分类实现，子类不实现，子类分类实现<br/>
	顺序：父类load，子类分类load、父类分类load<br/>
    原因：本来应该调用子类load的，无奈子类load没实现，但是找到了子类分类，那么就调用子类分类的load，最后在调用父类分类load(因为分类要最晚调用，由于刚才子类分类被调用过了，所以这里没它事了)<br/>
    **所以：不一定主类的load方法总比分类的load方法早调用，存在特殊情况**<br/><br/>
2. 父类不实现，父类分类实现，子类实现，子类分类实现<br/>
	顺序：父类分类load，子类load，子类分类load<br/>
    原因：跟上面的理由是一样的，父类没实现但是父类分类找到了那么就调用<br/>
    **所以：父类的分类的load也可以比子类load方法早调用**
    
## initialize方法


### 先写个Demo


父类：实现initialize方法

```
@implementation Person

+ (void)initialize {
    NSLog(@"Person initialize");
}

@end
```

父类的分类：实现initialize方法

```
@implementation Person(Test)

+ (void)initialize {
    NSLog(@"Person Text initialize");
}

@end

```

子类：实现initialize方法

```
@implementation Student

+ (void)initialize {
    NSLog(@"Student initialize");
}

@end

```

子类的分类：实现initialize方法

```
@implementation Student(Test)

+ (void)initialize {
    NSLog(@"Student Test initialize");
}

@end
```

### initialize方法的调用时机

- `+initialize`会在类第一次接受到消息的时候调用，即`objc_msgSend()`被触发的时候调用，这部分是汇编实现

- runtime源码里面有一个`class_getInstanceMethod()`函数，用于查找方法，当找到要调用的方法之后，就会调用`initialize`方法，`class_getInstanceMethod()`内的主要实现为`lookUpImpOrForward()`函数的调用

```
/***********************************************************************
* class_getInstanceMethod.  Return the instance method for the
* specified class and selector.
**********************************************************************/
Method class_getInstanceMethod(Class cls, SEL sel)
{
    if (!cls  ||  !sel) return nil;

    // This deliberately avoids +initialize because it historically did so.

    // This implementation is a bit weird because it's the only place that 
    // wants a Method instead of an IMP.

    Method meth;
    meth = _cache_getMethod(cls, sel, _objc_msgForward_impcache);
    if (meth == (Method)1) {
        // Cache contains forward:: . Stop searching.
        return nil;
    } else if (meth) {
        return meth;
    }
        
    // Search method lists, try method resolver, etc.
    lookUpImpOrForward(nil, sel, cls, LOOKUP_INITIALIZE | LOOKUP_RESOLVER);

    meth = _cache_getMethod(cls, sel, _objc_msgForward_impcache);
    if (meth == (Method)1) {
        // Cache contains forward:: . Stop searching.
        return nil;
    } else if (meth) {
        return meth;
    }

    return _class_getMethod(cls, sel);
}
```

- `lookUpImpOrForward()`函数实现内，有一判断条件为`if(slowpath(!cls->isInitialized())) { ... }` ，若该类已经调用过`+initialize`，那么就不会再调用，这就是`+initialize`只被系统调用一次的原因

- 经过一层层点击方法实现（流程见补充），最终我们可以在`objc-initialize.mm`内发现函数`callInitialize(Class cls)`，内部实现是`objc_msgSend`，如下

```
  void callInitialize(Class cls)
{
    ((void(*)(Class, SEL))objc_msgSend)(cls, @selector(initialize));
    asm("");
}
```

> 补充：函数调用路径为`lookUpImpOrForward`->`realizeAndInitializeIfNeeded_locked`->`initializeAndLeaveLocked`->`initializeAndMaybeRelock`->`initializeNonMetaClass`->`callInitialize`<br/>其中：`initializeNonMetaClass`函数实现内有一个递归，不断地传入`superclass`指针，去调用父类的`initialize`方法，直到`superclass`指针为空（或已经调用过`initialize`）为止，这就是先调用父类的`initialize`方法的原因
  

### initialize方法的调用顺序

- 先调用父类的`initialize`方法，再调用子类的`initialize`


### 综上所述

1. `initialize`是通过`objc_msgSend`方式调用的，所以会受分类、继承等等因素影响调用
2. 如果子类没有实现`+initialize`，会调用父类的`+initiailize`（所以父类的`+initialize`可能会被调用多次）
3. 如果分类实现了`+initialize`，就会覆盖主类的`+initialize`调用


## 关联对象


假如我们要给一个类添加一个属性如下：<br>
`@property (copy, nonatomic) NSString *test;`


### 存值


```
OBJC_EXPORT void
objc_setAssociatedObject(id _Nonnull object, const void * _Nonnull key,
                         id _Nullable value, objc_AssociationPolicy policy)
``` 

|参数名|解释|
|---|---|
|object|要关联的对象，如果是在分类内给主类添加属性，那么这里就写`self`|
|key|要用来标记这个属性的key，取值的时候也得靠这个key取|
|value|存储的内容|
|policy|存储策略（见下表）|

#### objc_AssociationPolicy 存储策略

|策略枚举|对应修饰符|
|---|---|
|OBJC_ASSOCIATION_ASSIGN|assign|
|OBJC_ASSOCIATION_RETAIN_NONATOMIC|strong, nonatomic|
|OBJC_ASSOCIATION_COPY_NONATOMIC|copy,nonatomic|
|OBJC_ASSOCIATION_RETAIN|strong, atomic|
|OBJC_ASSOCIATION_COPY|copy,atomic|

> 如果要存weak类型的对象怎么办？<br/>创建一个类，用`OBJC_ASSOCIATION_RETAIN_NONATOMIC`标记存在主类中，然后在这个新建的类里面再存放一个weak引用的属性

#### key有多少种填写形式

  1. 声明全局变量`static const void *TestKey = &TestKey;`,将`TestKey`的地址作为key的内容，不能直接写`const void *TestKey`，因为这么写等共同于`const void *TestKey = NULL`，要是以后添加别的属性，就会冲突，使用例子：
  
  ```
  objc_setAssociatedObject(self,TestKey,test,OBJC_ASSOCIATION_COPY_NONATOMIC)
  ```
  
  2. 声明全局变量`static const char TestKey`，同样将`TestKey`的地址作为key，好处是`char`只占用一个字节的内存大小，使用例子：
  
  ```
  objc_setAssociatedObject(self,&TestKey,test,OBJC_ASSOCIATION_COPY_NONATOMIC)
  ```
  
  3. 因为OC内的字符串都存在常量区，所以通过字面量创建的相同字符串都是同个地址，所以我们也可以随便定义一个字符串去做key，使用例子：
  
  ```
  objc_setAssociatedObject(self,@"Test",test,OBJC_ASSOCIATION_COPY_NONATOMIC)
  ```
  
  4. 我们也可以通过使用getter方法的方法编号去做key，使用例子：
  
  ```
  objc_setAssociatedObject(self,@selector(test),test,OBJC_ASSOCIATION_COPY_NONATOMIC)
  ```
  
### 取值

```
OBJC_EXPORT id _Nullable
objc_getAssociatedObject(id _Nonnull object, const void * _Nonnull key);
``` 


- object同上，一般分类里面就填self
- key属性需要和上面设值的key属性一致


- 如果使用getter方法的方法编号去做key，有两种写法
	1. `objc_getAssociatedObject(self, @selector(test))`
    2. `objc_getAssociatedObject(self, _cmd)`，`_cmd`表示当前方法的方法地址
    
    
### 底层实现

![图片来源自小码哥教程](https://www.hualigs.cn/image/60bd149eb55dc.jpg)

- runtime维护着一个名为`AssociationsManager`的类
- 类里面存放着一个字典，键是传入的对象（object参数），值是`ObjectAssociationMap`类的实例对象
- `ObjectAssociationMap`是一个字典，键是传入的key参数，值是`ObjcAssociation`类的实例对象
- `ObjcAssociation`有两个成员变量，`_policy`存放着传入的policy参数，`_value`存放着传入的value参数


### 综上所述

1. 关联对象并不是存储在被关联对象的内存中
2. 关联对象存储在全局统一的`AssociationsManager`中
3. 设置关联对象（object参数）为nil，就相当于是移除关联对象