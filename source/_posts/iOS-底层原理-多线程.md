title: iOS 底层原理 --- 多线程
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: f4b0e2bd
date: 2021-08-29 21:49:00
---
本文主要简述iOS中多线程的使用及其原理
<!--more-->

## 常见的多线程方案

|技术方案|简介|语言|线程生命周期|使用频率|
|:---:|:---|:---:|:---:|:---:|
|pthread|<ul><li>一套通用的多线程API</li><li>适用于Unix\Linux\Windows等系统</li><li>跨平台\可移植</li><li>使用难度大</li></ul>|C|程序员管理|几乎不用|
|NSThread|<ul><li>使用更加面向对象</li><li>简单易用，可直接操作线程对象</li></ul>|OC|程序员管理|偶尔使用|
|GCD|<ul><li>旨在替代NSThread等线程技术</li><li>充分利用设备的多核</li></ul>|C|自动管理|经常使用|
|NSOperation|<ul><li>基于GCD</li><li>比GCD多了一些简单实用的功能</li><li>使用更加面向对象</li></ul>|OC|自动管理|经常使用|

### 一些多线程术语

- 同步、异步：能不能开启新的线程
	- 同步：在当前线程中执行任务，不具备开启新线程的能力
    - 异步：在新的线程中执行任务，具备开启新线程的能力
- 并发、串行：任务的执行方式
	- 并发：多个任务并发（同时）执行
    - 串行：一个任务执行完毕后，再执行下一个任务

### 各种队列的执行效果

||并发队列|手动创建的串行队列|主队列|
|---|---|---|---|
|同步（sync）|没有开启新线程<br>串行执行任务|没有开启新线程<br>串行执行任务|没有开启新线程<br>串行执行任务|
|异步（async）|有开启新线程<br>并发执行任务|有开启新线程<br>串行执行任务|没有开启新线程<br>串行执行任务|

- 使用`sync`函数往当前串行队列中添加任务，会卡住当前的串行队列（产生死锁）

- 死锁问题主要产生在串行队列中。由于串行队列的FIFO（First in first out）性质，如果串行队列中有同步函数，那么同步函数要等待串行队列执行完才能执行，又因为同步函数的性质是在当前线程立马执行函数体，所以同步函数后面的代码要等待同步函数执行完才能执行，在这种情况下就会出现死锁

- 因为并发队列允许同时执行多个任务，所以不存在等待队列中其他人完成后才能开始执行的情况，所以一般情况下并发队列不会产生环路等待死锁

## GCD

### GCD的常用函数

- 用同步的方式执行任务

```objectivec
/// queue 队列
/// block 任务
dispatch_sync(dispatch_queue_t queue,dispatch_block_t block);
```

- 用异步的方式执行任务

```objectivec
/// queue 队列
/// block 任务
dispatch_sync(dispatch_queue_t queue,dispatch_block_t block);
```

### GCD的队列

GCD的队列可以分为2大类型

- 并发队列（Concurrent Dispatch Queue）

	- 可以让多个任务并发（同时）执行（自动开启多个线程同时执行任务）
    - 并发功能只有在异步（dispatch_async）函数下才有效
    
- 串行队列（Serial Dispatch Queue）

	- 让任务一个接着一个执行（一个任务执行完毕后，在执行下一个任务）
    
    
### GCD的队列组

```objectivec
// 创建队列组
dispatch_group_t group = dispatch_group_create();

// 创建并发队列
dispatch_queue_t queue = dispatch_queue_create("my_queue", DISPATCH_QUEUE_CONCURRENT);

// 添加异步任务
dispatch_group_async(group, queue, ^{
    for (int i = 0; i < 5; i++) {
        NSLog(@"任务1-%@",[NSThread currentThread]);
    }
});
dispatch_group_async(group, queue, ^{
    for (int i = 0; i < 5; i++) {
        NSLog(@"任务2-%@",[NSThread currentThread]);
    }
});

// 等前面的任务执行完毕后，会自动执行这个任务
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    for (int i = 0; i < 5; i++) {
        NSLog(@"任务3-%@",[NSThread currentThread]);
    }
});
```

## 多线程的安全隐患

- 资源共享
	- 1块资源可能会被多个线程共享，也就是多个线程可能会访问同一块资源
    - 比如多个线程访问同一个对象，同一个变量，同一个文件
    
- 当多个线程访问同一块资源时，很容易引发数据错乱和数据安全问题


解决方案：使用线程同步技术（同步，就是协同步调，按预定的先后持续进行）

- 常见的线程同步技术是：加锁，常见线程同步方案如下
	- OSSpinLock
    - os_unfair_lock
    - pthread_mutex
    - dispatch_semaphore
    - dispatch_queue(DISPATCH_QUEUE_SERIAL)
    - NSLock
    - NSRecursiveLock
    - NSCondition
    - NSConditionLock
    - @synchronized
    
### 串行队列

线程同步的最直接的方案就是串行队列，让多条线程按顺序执行

```
dispatch_queue_t queue = dispatch_queue_create("queue",DISPATCH_QUEUE_SERIAL);

dispatch_sync(queue,^{
    xxxx
});

dispatch_sync(queue,^{
    xxxx
});
```

### OSSpinLock

> 这个锁在iOS 10之后被废弃了

自旋锁，等待锁的线程会处于忙等（busy-wait）状态，一直占用着CPU资源

> 忙等：一边等待一边忙着做事情，相当于while(1){xxx}。自旋：自己一直在那里旋转

> 需要导入头文件`<libkern/OSAtomic.h>`

初始化

```
OSSpinLock lock = OS_SPINLOCK_INIT;
```

加锁

```
OSSpinLockLock(&_lock);
```

尝试加锁：如果需要等待就返回false，不加锁；如果不需要等待就返回true，加锁。

```
Bool result = OSSpinLockTry(&_lock)
```

解锁

```
OSSpinLockUnlock(&_lock);
```

自旋锁现在已经不再安全，可能会出现优先级反转问题

如果等待锁的优先级线程较高，它会一直占用着CPU资源，优先级低的线程就无法释放锁


### os_unfair_lock

- `os_unfair_lock`用于取代不安全的`OSSpinLock`，从iOS10开始才支持
- 从底层调用看，等待`os_unfair_lock`锁的线程会处于休眠状态，并非忙等
- 需要导入头文件`<os/lock.h>`

初始化

```
os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
```

加锁

```objectivec
os_unfair_lock_lock(&lock);
```

解锁

```objectivec
os_unfair_lock_unlock(&lock);
```

### phread_mutex

- `mutex`叫做互斥锁，等待锁的线程会处于休眠状态
- 需要导入头文件`<pthread.h>`

初始化方法1

```
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
```

初始化方法2

```
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT);

/// 这里的第二个参数如果传NULL的话表示使用默认属性
pthread_mutex_init(&_mutex, &attr);

pthread_mutexattr_destory(&attr);
```

尝试加锁

```
pthread_mutex_trylock(&mutex);
```

加锁

```
pthread_mutex_lock(&mutex);
```

解锁

```
pthread_mutex_unlock(&mutex);
```


#### 递归锁 

锁的属性可以改为递归锁，即允许**同一个线程**对一把锁进行重复加锁
```
  pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
```

#### 条件锁

初始化条件

```
pthread_cond_t condition;
pthread_cond_init(&condition, NULL);
```

等待条件（进入休眠，放开mutex锁；被唤醒后，会再次对mutex加锁）

```
pthread_cond_wait(&condition, &mutex);
```

激活**一个**等待该条件的线程（如果这时候有多个在等待，那么也只会激活最先等待的那个）

```
pthread_cond_signal(&condition);
```

激活所有等待该条件的线程

```
pthread_cond_brodcast(&condition);
```

销毁资源

```
pthread_mutex_destory(&mutex);
pthread_cond_destory(&condition);
```

### NSLock

- `NSLock`是对`mutex`普通锁的封装，即`pthread_mutex_init(&_mutex, NULL);`

初始化

```objectivec
NSLock *lock = [[NSLock alloc] init];
```

加锁

```objectivec
- (void)lock;
```

尝试加锁(调用的瞬间立马去判断当前能不能加锁，能加就加，然后返回YES，然后继续往下走，如果不能加就返回NO，然后继续往下走)

```objectivec
- (BOOL)tryLock;
```

等待锁（调用的时候先阻塞，如果现在能加锁，就返回YES，加锁成功，继续往下走；如果不能加锁，就阻塞，如果在limit之前，锁被放开了，那么就加锁，返回YES，代码继续往下走；如果直到limit到了，锁还没被放开，那么就返回NO，加锁失败，代码继续往下走）

```objectivec
- (BOOL)lockBeforeDate:(NSDate *)limit;
```

解锁

```objectivec
- (void)unlock;
```

### NSRecursiveLock

- `NSRecurseiveLock`也是对`mutex`递归锁的封装，API跟`NSLock`基本一致

### NSCondition

- `NSCondition`也是对`mutex`和`cont`的封装

等待锁

```objectivec
- (void)wait;
- (void)waitUtilDate:(NSDate *)limit;
```

激活锁

```objectivec
- (void)signal; // 激活单个
- (void)boardcast; // 激活多个
```

### NSConditionLock

- `NSConditionLock`是对`NSCondition`的进一步封装，可以设置具体的条件值

初始化设定一个条件值，如果直接`init`的话那么默认值是0

```
 - (instancetype)initWithCondition:(NSInteger)condition;
```

加锁并且设定条件值为`condition`

```objectivec
- (void)lockWhenCondition:(NSInteger)condition;
- (BOOL)tryLockWhenCondition:(NSInteger)condition; // 尝试加锁
- (BOOL)lockWhenCondition:(NSInteger)condition beforeDate:(NSDate *)limit; // 在指定时间到达之前等待条件成立加锁
```

如果直接使用`lock`方法，那么会无视条件值，直接加锁或者等待加锁

解当前的锁并且设置条件值为`condition`，如果这时候有条件值为`condition`的锁在加着，那么就会释放

```objectivec
- (void)unlockWhenCondition:(NSInteger)condition;
```

如果直接使用`unlock`方法，那么那些带条件的`lockWhenCondition`不会解锁

### dispatch_semaphore

- `semaphore`叫做信号量
- 信号量的初始值，可以用来控制线程并发访问的最大数量

初始化，传入一个允许的最大并发线程数`count`

```
dispatch_sempathore semaphore = dispatch_semaphore_create(count);
```

如果信号量的值<=0，当前线程就会进入休眠等待（直到信号量的值>0）
如果信号量的值>0，就减1，然后往下执行后面的代码

```
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
```

让信号量的值加1
```
dispatch_semaphore_signal(semaphore);
```

### @synchronized

- `@synchronized`是对`mutex`递归锁的封装

传入对象即可，用于标记是不是同个锁，一个对象标记一把锁 

```
@synchronized(xxx) {

}
```

### 线程同步方案性能比较

- 性能从高到低排序
	- os_unfair_lock
    - OSSpinLock
    - dispatch_semaphore
    - pthread_mutex
    - dispatch_queue(DISPATCH_QUEUE_SERIAL)
    - NSLock
    - NSCondition
    - pthread_mutex(recursive)
    - NSRecursiveLock
    - NSConditionLock
    - @synchronized

    
## 自旋锁、互斥锁比较

> iOS10之后已经不推荐使用自旋锁了

- 什么情况使用自旋锁比较划算？
	- 预计线程等待锁的时间很短
    - 加锁的代码（临界区）经常被调用，但竞争情况很少发生
    - CPU资源不紧张
    - 多核处理器
   
- 什么情况使用互斥锁比较划算？
	- 预计线程等待锁的时间较长
    - 单核处理器
    - 临界区有IO操作（因为比较占用CPU资源）
    - 临界区代码复杂或者循环量大
    

## 读写安全

### atomic

`nonatomic`和`atomic` ：给属性加上`atomic`修饰，可以保证属性的`setter`和`getter`都是原子性操作，也就是保证`setter`和`getter`内部是线程同步的
    
参照runtime源码中 `objc-accessors.mm`的`objc_getProperty`和`reallySetProperty`方法，分别是get方法和set方法的内部实现

```objectivec
id objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic) {
    if (offset == 0) {
        return object_getClass(self);
    }

    // Retain release world
    id *slot = (id*) ((char*)self + offset);
    if (!atomic) return *slot;
    
    // 如果是atomic的时候，会加上锁
    
    // Atomic retain release world
    spinlock_t& slotlock = PropertyLocks[slot];
    slotlock.lock();
    id value = objc_retain(*slot);
    slotlock.unlock();
    
    // for performance, we (safely) issue the autorelease OUTSIDE of the spinlock.
    return objc_autoreleaseReturnValue(value);
}

```

```objectivec
static inline void reallySetProperty(id self, SEL _cmd, id newValue, ptrdiff_t offset, bool atomic, bool copy, bool mutableCopy)
{
    if (offset == 0) {
        object_setClass(self, newValue);
        return;
    }

    id oldValue;
    id *slot = (id*) ((char*)self + offset);

    if (copy) {
        newValue = [newValue copyWithZone:nil];
    } else if (mutableCopy) {
        newValue = [newValue mutableCopyWithZone:nil];
    } else {
        if (*slot == newValue) return;
        newValue = objc_retain(newValue);
    }

    if (!atomic) {
        oldValue = *slot;
        *slot = newValue;
    } else {
    	/// 这里可以看出如果是atomic的时候，是会加上锁的
        spinlock_t& slotlock = PropertyLocks[slot];
        slotlock.lock();
        oldValue = *slot;
        *slot = newValue;        
        slotlock.unlock();
    }

    objc_release(oldValue);
}
```

`atmoic`是不能保证使用属性的过程中是线程安全的，即虽然他的setter和getter是线程安全的，但是用这个属性去调用其他方法的时候依旧不一定属性安全，比如`[self.array addObject:xxx]`，这里只能保证取出array属性的时候线程安全，但是添加对象进去的时候就有可能出现线程同步问题

### 读写安全方案

#### 多读单写

- 同一时间，只能有1条线程进行写的操作
- 同一时间，允许有多条线程进行读的操作
- 同一时间，不允许既有写的操作，又有读的操作

- pthread_rwlock：读写锁
- dispatch_barrier_async：异步栅栏调用

#### pthread_rwlock

- 等待锁的线程会进入休眠
- 需要引入头文件<pthread.h>

初始化锁

```objectivec
pthread_rwlock_t lock;
pthread_rwlock_init(&lock,NULL);
```

读-加锁/尝试加锁

```objectivec
pthread_rwlock_rdlock(&lock);
pthread_rwlock_tryrdlock(&lock);
```

写-加锁/尝试加锁

```objectivec
pthread_rwlock_wrlock(&lock);
pthread_rwlock_trywrlock(&lock);
```

解锁

```objectivec
pthread_rwlock_unlock(&lock);
```

销毁

```objectivec
pthread_rwlock_destory(&lock);
```

#### dispatch_barrier_async

- 这个函数传入的并发队列必须是自己通过`dispatch_queue_create`创建的
- 如果传入的是一个串行或是一个全局的并发队列，那这个函数便等同于`dispatch_async`函数的效果

```objctivec
// 初始化队列
dispatch_queue_t queue = dispatch_queue_create("rw_queue",DISPATCH_QUEUE_CONCURRENT);

// 读
dispatch_async(queue,^{
	
});

// 写
dispatch_barrier_async(queue, ^{

});
```



    
## 其他

1. 子线程中，`performSelector:withObject:afterDelay:`不起作用的原因
	```objectivec
    dispatch_queue_t queue = dispatch_get_global_queue(0,0);
    dispatch_async(queue, ^{
        NSLog(@"1");
        [self performSelector:@selector(test) withObject:nil afterDelay:.0];
        NSLog(@"3");
    });
    ```
	- `performSelector:withObject:afterDelay:` 的本质是往Runloop中添加定时器
	- 子线程中默认没有启动`Runloop`
    - 补充代码启动Runloop即可
    	```objectivec
        [[NSRunloop currentRunloop] addPort:[[NSPort alloc] init] forMode:NSDefaultRunloopMode];
        [[NSRunloop currentRunloop] runMode:NSDefaultRunloopMode beforeDate:[NSDate distantFeature]];
    	```