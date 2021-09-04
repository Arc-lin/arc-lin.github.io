title: iOS 底层原理 --- 内存管理
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: 56d1bd42
date: 2021-09-03 17:26:00
---
本文主要介绍iOS中内存管理的一些事情

<!--more-->

## 定时器

### CADisplayLink、NSTimer

`CADisplayLink`、`NSTimer`会对`target`产生强引用，如果`target`又对它们产生强引用，那么就会引发循环引用

比如：

```
@property (strong) NSTimer *timer;
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTimer) userInfo:nil repeats:YES];
```

在这里，`self`强持有了`timer`，`timer`强持有了`self`，造成了循环引用

#### 利用block解决

针对`NSTimer`我们可以有另外的解决办法：

```objectivec
__weak typeof(self) weakself = self;
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
    [weakself timerTest];
]};
```

让`timer`强持有block，block弱持有`self`，这样子`self`就是间接被弱持有，打破了循环引用。

#### 利用NSProxy解决

新建一个类继承自`NSProxy`

```objectivec
@interface MyProxy : NSProxy

+ (instancetype)proxyWithTarget:(id)target;

@end

```

```objectivec
@interface MyProxy()

@property (nonatomic, weak) id target;

@end

@implementation MyProxy

+ (instancetype)proxyWithTarget:(id)target {
    // NSProxy对象不需要调用init，因为它没有init方法
    MyProxy *proxy = [MyProxy alloc];
    proxy.target = target;
    return proxy;
}

/// 实现消息转发的两个方法，一定要实现，不然会报方法找不到的错误

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

@end
```

使用

```objectivec
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[MyProxy proxyWithTarget:self] selector:@selector(test) userInfo:nil repeats:YES];

```

原理很简单，就是把`self`让`proxy`弱持有，`timer`强持有`proxy`，这样子就能够做到间接弱持有`self`，打破循环引用

为了让`timer`调用`selector`的时候能调回到`self`的方法，在`proxy`内部我们使用消息转发机制，把消息转发到`target`（也就是`self`）中，实现调用。

至于消息转发机制的另一个方法`-forwardingTargetForSelector:`之所以不能使用，是因为`NSProxy`不提供。

实际上我们如果不继承自`NSProxy`，直接继承自`NSObject`也是能完成上述操作的，但是使用`NSProxy`的话可以跳过消息发送和动态方法解析阶段，直接进入消息转发阶段，效率比较高

> 注意： `NSProxy`对象如果调用`isKindOfClass:`或其他方法，那么由于它直接进入了消息转发阶段，所以会直接拿`target`属性去调用方法，所以都跟`NSProxy`对象本身没有关系


### GCD定时器

- `NSTimer`依赖`RunLoop`，如果`Runloop`的任务过于繁重，可能会导致`NSTimer`不准时
	- 因为Runloop每次循环的时间是不定的，所以下次循环的时候到达处理定时器那个环节，不一定跟上次刚好相差我们所指定时间，所以就会不准
    
- GCD的定时器会更加准时

```objectivec
// 队列
dispatch_queue_t queue = dispatch_get_main_queue();

// 创建定时器
dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

// 设置时间
NSTimeInterval start = 2.0; // 2秒后开始执行
NSTimeInterval interval = 1.0; // 每1秒执行一次
dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0);

// 设置回调
dispatch_source_set_event_handler(timer, ^{
    NSLog(@"11111");
});

// 启动定时器
dispatch_resume(timer);

// 取消定时器
// dispatch_source_cancel(timer);

self.timer = timer;
```

由于GCD的定时器跟`Runloop`没有关系，所以滚动视图也不会影响GCD定时器的执行

除了使用block回调，我们也可以写一个C函数作为回调函数

```c
dispatch_source_set_event_handler_f(timer, timerFire);
```

```c
void timerFire(void *param) {
    NSLog(@"%@ %@",param,[NSThread currentThread]);
}
```

## 内存布局

- 内存布局从低地址到高地址排序如下
  1. 保留
  2. 代码段（__TEXT）
  3. 数据段（__DATA）：字符串常量， 已初始化数据，未初始化数据
  4. 堆（heap）
  5. 栈（stack）
  6. 内核区
  
- 代码段：编译之后的代码
- 数据段：
	- 字符串常量
    - 已初始化数据：已初始化的全局变量、静态变量等
    - 未初始化数据：未初始化的全局变量、静态变量等
- 堆：通过alloc、malloc、calloc的那个动态分配的空间，分配的内存空间地址越来越大
- 栈：函数调用开销，比如局部变量，分配的内存空间地址越来越小


## Tagged Pointer

- 从64bit开始，iOS引入了Tagged Pointer技术，用于优化`NSNumber`,`NSDate`，`NSString`等小对象的存储

- 在没有使用Tagged Pointer之前，`NSNumber`等对象需要动态分配内存，维护引用计数的等，`NSNumber`指针存储的是堆中`NSNumber`对象的地址值.

- 使用`Tagged Pointer`之后，`NSNumber`指针里面存储的数据变成了：Tag + Data，也就是将数据直接存储在了指针中。

- 在Mac环境下当对象指针的二进制最低有效位是1，则该指针为`Tagged Pointer`（如果是0那么就是OC对象，因为OC对象分配内存是按照16个字节对齐的，所以最后一位肯定是0）,可以编写如下函数来判断是否是`Tagged Pointer`

	- 跟1进行与运算，取出最低位判断是不是1即可

  ```c
  BOOL isTaggedPointer(id pointer) {
      return (long)(__bridge void *)pointer & 1;
  }
  ```
  - 如果是iOS环境下，则判断的是最高有效位(第64位)是否是1，即`(long)(__bridge void *)pointer & 1UL<<63`

- 当指针不够存储数据时，才会使用动态分配内存来存储数据（比如NSNumber的存储的数字太大了，指针8个十六进制位都装不下）

- `objc_msgSend`能识别`Tagged Pointer`，比如`NSNumber`的intValue方法，直接从指针提取数据，节省了以前的调用开销

### 字符串

```
@property(copy, nonatomic) NSString *name;
```

这个属性的set方法实际为

```
- (void)setName:(NSString *)name {
    if(_name != name) {
        [_name release];
        _name = [name retain];
    }
}
```

假如我们这么给`name`赋值`self.name = [NSString stringWithForamt:@"abcdefghijkl"]`，因为这个太大了，转不成`tagged pointer`，那么在多线程环境下，有可能会因为多次执行了`[_name release]`导致坏内存访问而崩溃

字符串其实还有其他样子，总的来说，除了`__NSCFString`，其他类型的字符串都不会调用`release`方法

- __NSCFConstantString

	字符串常量，是一种编译时常量，它的 retainCount 值很大，是 4294967295，在控制台打印出的数值则是 18446744073709551615==2^64-1，测试证明，即便对其进行 release 操作，retainCount 也不会产生任何变化。是创建之后便是放不掉的对象。**相同内容的 __NSCFConstantString 对象的地址相同，也就是说常量字符串对象是一种单例**。

	这种对象一般通过字面值 `@"..."`、`CFSTR("...")` 或者 `stringWithString`: 方法（需要说明的是，这个方法在 iOS6 SDK 中已经被称为redundant，使用这个方法会产生一条编译器警告。这个方法等同于字面值创建的方法）产生。

	这种对象存储在字符串常量区。

- __NSCFString

	和 `__NSCFConstantString` 不同， `__NSCFString`对象是在运行时创建的一种 `NSString`子类，他并不是一种字符串常量。所以和其他的对象一样在被创建时获得了 1 的引用计数。

	通过 NSString 的 stringWithFormat 等方法创建的 NSString 对象一般都是这种类型。

	这种对象被存储在堆上。

- NSTaggedPointerString

	理解这个类型，需要明白什么是`TaggedPointer`，这是苹果在 64 位环境下对 NSString,NSNumber 等对象做的一些优化。简单来讲可以理解为把指针指向的内容直接放在了指针变量的内存地址中，因为在 64 位环境下指针变量的大小达到了 8 位足以容纳一些长度较小的内容。于是使用了标签指针这种方式来优化数据的存储方式。从他的引用计数可以看出，这货也是一个释放不掉的单例常量对象。在运行时根据实际情况创建。

	对于 `NSString` 对象来讲，当非字面值常量的数字，英文字母字符串的长度小于等于 9 的时候会自动成为 `NSTaggedPointerString` 类型，如果有中文或其他特殊符号（可能是非 ASCII 字符）存在的话则会直接成为 ）`__NSCFString` 类型。

	这种对象被直接存储在指针的内容中，可以当作一种伪对象。
    
    当字符串的长度为10个以内时，字符串的类型都是`NSTaggedPointerString`类型，当超过10个时，字符串的类型才是`__NSCFString`
    
- 从`NSTaggedPointerString`中读取出字符串的值

```c
#   define _OBJC_TAG_MASK (1UL<<63)
#   define _OBJC_TAG_INDEX_SHIFT 0
#   define _OBJC_TAG_SLOT_SHIFT 0
#   define _OBJC_TAG_PAYLOAD_LSHIFT 1
#   define _OBJC_TAG_PAYLOAD_RSHIFT 4
#   define _OBJC_TAG_EXT_INDEX_SHIFT 55
#   define _OBJC_TAG_EXT_SLOT_SHIFT 55
#   define _OBJC_TAG_EXT_PAYLOAD_LSHIFT 9
#   define _OBJC_TAG_EXT_PAYLOAD_RSHIFT 12

static inline bool _objc_isTaggedPointer(const void * _Nullable ptr)
{
    return ((uintptr_t)ptr & _OBJC_TAG_MASK) == _OBJC_TAG_MASK;
}

static inline uintptr_t _objc_decodeTaggedPointer(const void * _Nullable ptr)
{
    return (uintptr_t)ptr ^ objc_debug_taggedpointer_obfuscator;
}

static inline uintptr_t _objc_getTaggedPointerValue(const void * _Nullable ptr) 
{
    // assert(_objc_isTaggedPointer(ptr));
    uintptr_t value = _objc_decodeTaggedPointer(ptr);
    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
    if (basicTag == _OBJC_TAG_INDEX_MASK) {
        return (value << _OBJC_TAG_EXT_PAYLOAD_LSHIFT) >> _OBJC_TAG_EXT_PAYLOAD_RSHIFT;
    } else {
        return (value << _OBJC_TAG_PAYLOAD_LSHIFT) >> _OBJC_TAG_PAYLOAD_RSHIFT;
    }
}

static inline intptr_t _objc_getTaggedPointerSignedValue(const void * _Nullable ptr) 
{
    // assert(_objc_isTaggedPointer(ptr));
    uintptr_t value = _objc_decodeTaggedPointer(ptr);
    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
    if (basicTag == _OBJC_TAG_INDEX_MASK) {
        return ((intptr_t)value << _OBJC_TAG_EXT_PAYLOAD_LSHIFT) >> _OBJC_TAG_EXT_PAYLOAD_RSHIFT;
    } else {
        return ((intptr_t)value << _OBJC_TAG_PAYLOAD_LSHIFT) >> _OBJC_TAG_PAYLOAD_RSHIFT;
    }
}
```

### NSNumber

```objectivec
NSNumber *number1 = @(0x1);
NSNumber *number2 = @(0x20);
NSNumber *number3 = @(0x3F);
NSNumber *numberFFFF = @(0xFFFFFFFFFFEFE);
NSNumber *maxNum = @(MAXFLOAT);
NSLog(@"number1 pointer is %p class is %@", number1, number1.class);
NSLog(@"number2 pointer is %p class is %@", number2, number2.class);
NSLog(@"number3 pointer is %p class is %@", number3, number3.class);
NSLog(@"numberffff pointer is %p class is %@", numberFFFF, numberFFFF.class);
NSLog(@"maxNum pointer is %p class is %@", maxNum, maxNum.class);

```

```objectivec
TaggedPointerDemo[59218:2167895] number1 pointer is 0xf7cb914ffb51479a class is __NSCFNumber
TaggedPointerDemo[59218:2167895] number2 pointer is 0xf7cb914ffb51458a class is __NSCFNumber
TaggedPointerDemo[59218:2167895] number3 pointer is 0xf7cb914ffb51447a class is __NSCFNumber
TaggedPointerDemo[59218:2167895] numberffff pointer is 0xf7346eb004aea86b class is __NSCFNumber
TaggedPointerDemo[59218:2167895] maxNum pointer is 0x28172a0c0 class is __NSCFNumber
```

我们发现对于`NSNumber`，我们打印出来的数据类型均为`__NSCFNumber`,但是我们发现对于MAXFLOAT打印出的地址显然与其他几项不符，上面几个`NSNumber`的地址以0xf开头，根据字符串地址的经验我们可以看出`f = 1111`,首位标记位为1，表示这个数据类型属于`TaggedPointer`。而`MAXFLOAT`不是。

    
## MRC

- 在iOS中，使用`引用计数`来管理OC对象的内存
- 一个新创建的OC对象的引用计数默认是1，当引用计数减为0，OC对象就会销毁，释放其占用的内存空间
- 调用retain会让OC对象的引用计数+1，调用release会让OC对象的引用计数-1

- 内存管理的经验总结：
	- 当调用`alloc`、`new`、`copy`、`mutableCopy`方法返回了一个对象，在不需要这个对象时，要调用`release`或者`autorelease`释放它
    - 想拥有某个对象，就让它的引用计数+1;不想再拥有某个对象，就让它的引用计数-1
    
- 可以通过以下私有函数来查看自动释放池的情况

	`extern void _objc_autoreleasePoolPrint(void); `

在ARC中声明`@property(nonatomic,assign) int age;` 其set方法相当于MRC中的

```objectivec
- (void)setAge:(int)age {
    _age = age;
}
```

在ARC中声明`@property(nonatomic,strong) NSObject *age;` 其set方法相当于MRC中的

```objectivec
- (void)setAge:(NSObject *)age {
    if (_age != age) { // 防止同个对象释放后引用计数变成0，就不能再retain了
        [_age release]; // 防止新对象进来之后，旧对象的引用计数多出了1导致释放不掉
        _age = [age reatin]; // 引用计数+1，防止被外部一不小心释放了
    }
}
```

- 关于Autorelease

  ```	
  self.data = [NSMutableArray array]; // 自动进行了autorelease
  ```
  等同于
  ```
  self.data = [[[NSMutableArray alloc] init] autorelease];
  ```
  等同于
  ```
  self.data = [[NSMutableArray alloc] init];
  [self.data release];
  ```
  等同于
  ```
  NSMutableArray *data = [[NSMutableArray alloc] init];
  self.data = data;
  [data release];
  ```
  
## 引用计数的存储

在64bit中，引用计数可以直接存储在优化过的isa指针中，如果isa指针不够存的话就存储在`SiteTable`类中（最终的引用计数是两个存储的地方都会取出来值，然后求和）

```c
struct SideTable {
    spinlock_t slock;
    RefcountMap refcnts;
    weak_table_t weak_table;
};
```

- refcnts是一个存放着对象引用计数的散列表

在SiteTable中获取到`retainCount`的核心代码如下

```c
size_t objc_object::sidetable_getExtraRC_nolock()
{
    ASSERT(isa.nonpointer);
    SideTable& table = SideTables()[this];
    RefcountMap::iterator it = table.refcnts.find(this); 
    if (it == table.refcnts.end()) return 0; // 遍历refcnts
    else return it->second >> SIDE_TABLE_RC_SHIFT; // 进行位运算取出retainCount
}
```
  
## Weak

 weak指针能够在对象释放的时候把指针清空，具体是怎么做到的。我们需要看一下对象`dealloc`的过程
 
 ```c
inline void objc_object::rootDealloc()
{
    if (isTaggedPointer()) return;  // fixme necessary?

    if (fastpath(isa.nonpointer                     && // 0代表普通的指针，1代表优化过的指针，使用位域存储信息
                 !isa.weakly_referenced             && // 是否有弱引用指针
                 !isa.has_assoc                     && // 是否有设置关联对象
                 !isa.has_cxx_dtor                  && // 是否有C++即构函数
                 !isa.has_sidetable_rc))			   // 引用计数器是不是过大而无法存放在isa中，如果为1，那引用计数会存储在SideTable的类的属性中
    {
        assert(!sidetable_present());
        free(this);
    } 
    else {
        object_dispose((id)this); // 显然弱引用指针指向的对象会进入这里
    }
}
 ```
 
 ```c
id  object_dispose(id obj) {
    if (!obj) return nil;

    objc_destructInstance(obj); // 释放前做一些事情
    free(obj); // 这里才释放

    return nil;
 }
 ```
 
 ```c
void *objc_destructInstance(id obj) 
{
    if (obj) {
        // Read all of the flags at once for performance.
        bool cxx = obj->hasCxxDtor();
        bool assoc = obj->hasAssociatedObjects();

        // This order is important.
        if (cxx) object_cxxDestruct(obj); // 清除成员变量
        if (assoc) _object_remove_assocations(obj, /*deallocating*/true); // 移除关联对象
        obj->clearDeallocating(); // 将指向当前对象的弱指针置为nil
    }

    return obj;
}
 ```
 
 ```c
inline void objc_object::clearDeallocating()
{
    if (slowpath(!isa.nonpointer)) {
        // Slow path for raw pointer isa.
        sidetable_clearDeallocating();
    }
    else if (slowpath(isa.weakly_referenced  ||  isa.has_sidetable_rc)) {
        // Slow path for non-pointer isa with weak refs and/or side table data.
        clearDeallocating_slow(); // 再进入这里
    }
    assert(!sidetable_present());
}
 ```
 
 
 ```c
 NEVER_INLINE void objc_object::clearDeallocating_slow()
{
    ASSERT(isa.nonpointer  &&  (isa.weakly_referenced || isa.has_sidetable_rc));

    SideTable& table = SideTables()[this]; // 拿出SiteTables数组，然后取出对应的SiteTable对象
    table.lock();
    if (isa.weakly_referenced) {
        weak_clear_no_lock(&table.weak_table, (id)this); // 清除弱引用指针 
    }
    if (isa.has_sidetable_rc) {
        table.refcnts.erase(this); // 清除引用计数表
    }
    table.unlock();
}
```

```c
void  weak_clear_no_lock(weak_table_t *weak_table, id referent_id) 
{
    objc_object *referent = (objc_object *)referent_id;

	/// 把SiteTable里面的weakTable和指针传进去
    weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);
    if (entry == nil) {
        /// XXX shouldn't happen, but does with mismatched CF/objc
        //printf("XXX no entry for clear deallocating %p\n", referent);
        return;
    }

    // zero out references
    weak_referrer_t *referrers;
    size_t count;
    
    if (entry->out_of_line()) {
        referrers = entry->referrers;
        count = TABLE_SIZE(entry);
    } 
    else {
        referrers = entry->inline_referrers;
        count = WEAK_INLINE_COUNT;
    }
    
    for (size_t i = 0; i < count; ++i) {
        objc_object **referrer = referrers[i];
        if (referrer) {
            if (*referrer == referent) {
                *referrer = nil;
            }
            else if (*referrer) {
                _objc_inform("__weak variable at %p holds %p instead of %p. "
                             "This is probably incorrect use of "
                             "objc_storeWeak() and objc_loadWeak(). "
                             "Break on objc_weak_error to debug.\n", 
                             referrer, (void*)*referrer, (void*)referent);
                objc_weak_error();
            }
        }
    }
    
    weak_entry_remove(weak_table, entry);
}
```

```c
static inline uintptr_t hash_pointer(objc_object *key) {
    return ptr_hash((uintptr_t)key);
}

static weak_entry_t * weak_entry_for_referent(weak_table_t *weak_table, objc_object *referent)
{
    ASSERT(referent);

    weak_entry_t *weak_entries = weak_table->weak_entries;

    if (!weak_entries) return nil;

	/// 通过与运算得到索引
    size_t begin = hash_pointer(referent) & weak_table->mask;
    size_t index = begin;
    size_t hash_displacement = 0;
    while (weak_table->weak_entries[index].referent != referent) {
        index = (index+1) & weak_table->mask;
        if (index == begin) bad_weak_table(weak_table->weak_entries);
        hash_displacement++;
        if (hash_displacement > weak_table->max_hash_displacement) {
            return nil;
        }
    }
    
    return &weak_table->weak_entries[index];
}
```

总结：

Weak指针指向的对象释放流程如下

1. 清除成员变量，移除关联对象
2. 拿到对象对应的SiteTable，再取出里面的weak_table
3. 通过hash后的对象的指针和weak_table进行一次与运算，得到索引，在weak_table中通过索引取出弱引用指针
4. 置空取出的所有的弱引用指针
5. 清除引用计数表
6. 释放对象

## Copy和MutableCopy

拷贝的目的：产生一个副本对象，跟源对象互不影响
修改了源对象，不会影响副本对象
修改了副本对象，不会影响源对象

iOS提供了2个拷贝方法
1. copy ，不可变拷贝，产生不可变副本。
2. mutableCopy，可变拷贝，产生可变副本。
3. 浅拷贝：指针拷贝，没有产生新的对象。（不可变对象copy）
4. 深拷贝：内容拷贝，产生新的对象。(可变、不可变对象调用mutableCopy或者可变对象调用copy)

```objectivec
NSString *str1 = [NSString stringWithFormat:@"test"];
NSString *str2 = [str1 copy]; // 返回的是NSString
NSMutableString *str3 = [str1 mutableCopy]; // 返回的是NSMutableString
```

当`copy`方法被不可变对象调用的话，不会发生什么变化，直接还是返回原来的对象，但是这时候引用计数会加1，相当于`retain`了一下，所以上面的代码要释放对象的时候，除了调用`[str1 release];`，那么还得调用`[str2 release]；`

在ARC中声明`@property(nonatomic,copy) NSString *age;` 其set方法相当于MRC中的

```objectivec
- (void)setAge:(NSString *)age {
    if (_age != age) {
        [_age release];
        _age = [age copy];
    }
}
```

## AutoRelease

```objectivec
@autoreleasepool {
    Student *student = [[[Student alloc] init] autorelease];
}
```

```c
struct __AtAutoreleasePool {
  __AtAutoreleasePool() { // 构造函数
      atautoreleasepoolobj = objc_autoreleasePoolPush();
  }
  ~__AtAutoreleasePool() { // 析构函数
      objc_autoreleasePoolPop(atautoreleasepoolobj);
  }
  void * atautoreleasepoolobj;
};
```

```c
{ 
    __AtAutoreleasePool __autoreleasepool; // 创建一个结构体变量
    Student *student = objc_msgSend(objc_msgSend(objc_msgSend(objc_getClass("Student"), sel_registerName("alloc")), sel_registerName("init")), sel_registerName("autorelease"));
}
```

相当于


```objectivec
{ 
    atautoreleasepoolobj = objc_autoreleasePoolPush();
    Student *student = objc_msgSend(objc_msgSend(objc_msgSend(objc_getClass("Student"), sel_registerName("alloc")), sel_registerName("init")), sel_registerName("autorelease"));
    objc_autoreleasePoolPop(atautoreleasepoolobj);
}
```

自动释放池的主要底层数据结构是: `__AtAutoreleasePool`、`AutoreleasePoolPage`

调用了`autorelease`的对象最终都是通过`AutoreleasePoolPage`对象来管的


源码分析
	- clang重写@autoreleasepool
    - objc4源码：NSobject.mm

## AutoreleasePoolPage的结构

```c
class AutoreleasePage
{
    magic_t const magic;
    id *next;
    pthread_t const thread;
    AutoreleasePoolPage *const parent;
    AutoreleasePoolPage *const child;
    uint32_t depth;
    uint32_t hiwat;
}
```

- 每个AutoreleasePoolPage对象占用4096字节内存，除了用来存放它内部的成员变量，剩下的空间用来存放`autorelease`对象的地址
- 所有的`AutoreleasePoolPage`对象通过双向链表的形式连接在一起

- 调用push方法会将一个POOL_BOUNDARY入栈，并且返回其存放的内存地址
- 调用pop方法时传入一个POOL_BOUNDARY的内存地址，会从最后一个入栈的对象开始发送release对象，直到遇到这个POOL_BOUNDARY

- `id *next`指向了下一个能存放`autorelease`对象地址的区域

```c
static inline void *push()  {
    id *dest;
    if (slowpath(DebugPoolAllocation)) {
        // Each autorelease pool starts on a new pool page.
        dest = autoreleaseNewPage(POOL_BOUNDARY);
    } else {
        dest = autoreleaseFast(POOL_BOUNDARY);
    }
    ASSERT(dest == EMPTY_POOL_PLACEHOLDER || *dest == POOL_BOUNDARY);
    return dest;
}
```

```c
static inline void pop(void *token) {
    AutoreleasePoolPage *page;
    id *stop;
    if (token == (void*)EMPTY_POOL_PLACEHOLDER) {
        // Popping the top-level placeholder pool.
        page = hotPage();
        if (!page) {
            // Pool was never used. Clear the placeholder.
            return setHotPage(nil);
        }
        // Pool was used. Pop its contents normally.
        // Pool pages remain allocated for re-use as usual.
        page = coldPage();
        token = page->begin();
    } else {
        page = pageForPointer(token);
    }

    stop = (id *)token;
    if (*stop != POOL_BOUNDARY) {
        if (stop == page->begin()  &&  !page->parent) {
            // Start of coldest page may correctly not be POOL_BOUNDARY:
            // 1. top-level pool is popped, leaving the cold page in place
            // 2. an object is autoreleased with no pool
        } else {
            // Error. For bincompat purposes this is not 
            // fatal in executables built with old SDKs.
            return badPop(token);
        }
    }

    if (slowpath(PrintPoolHiwat || DebugPoolAllocation || DebugMissingPools)) {
        return popPageDebug(token, page, stop);
    }

    return popPage<false>(token, page, stop);
}
```

### Runloop和Autorelease

- iOS在主线程的Runloop中注册了两个Observer
- 第1个Observer监听了`kCFRunLoopEntry`事件，会调用`objc_autoreleasePoolPush()`
- 第2个Observer
	- 监听了`kCFRunLoopBeforeWaiting`会调用`objc_autoreleasePoolPop()`、`objc_autoreleasePoolPush()`
	- 监听了`kCFRunloopBeforeExit`事件，会调用`objc_autoreleasePoolPop()`