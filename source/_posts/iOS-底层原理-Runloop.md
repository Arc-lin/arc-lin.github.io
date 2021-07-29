title: iOS 底层原理 -- Runloop
author: Arclin
abbrlink: fee6666f
tags:
  - iOS
  - 底层原理
categories:
  - iOS
date: 2021-07-21 22:10:50
---
本文讲述iOS中Runloop的一些使用以及原理

<!--more-->

## Runloop对象

- iOS中有两套API来访问和使用Runloop
	- Foundation : NSRunLoop
    - Core Foundation : CFRunloopRef
 
- NSRunloop和CFRunloopRef都代表着Runloop对象
- NSRunloop是基于CFRunloopRef的一层OC包装
- CFRunloopRef是开源的

获取当前Runloop的两个方法

```
NSRunLoop *runloop = [NSRunLoop currentRunLoop];
CFRunLoopRef runloopRef = CFRunLoopGetCurrent();
```

打印runloop可以发现类型是`<CFRunLoop 0x600001994300 [0x101405a98]>`，跟runloopRef一致，但是打印地址不一样，原因是`NSRunLoop`是对`CFRunLoopRef`的封装，`CFRunLoopRef`是存储在其内部，所以会不一样

## Runloop与线程

- 每条线程都有唯一的一个与之对应的Runloop对象

- Runloop保存在一个全局的Dictionary里，线程作为key，Runloop作为Value
	- Runloop源码 `CFRunloop.c`中我们可以找到`CFRunLoopGetCurrent()`内调用了`_CFRunLoopGet0()`，在这里面可以看到这行代码得以验证
    
    ```
    CFRunLoopRef loop = (CFRunLoopRef)CFDictionaryGetValue(__CFRunLoops, pthreadPointer(t));
    ```

- 线程刚创建的时候并没有Runloop对象，Runloop会在第一次获取它时创建

	- 主线程一开始也是没有Runloop的，只是因为在`main.m`中调用了`UIApplicationMain`函数，在这里面回去获取Runloop从而创建了Runloop
    - 对应源码如下
    
    ```
    CF_EXPORT CFRunLoopRef _CFRunLoopGet0(pthread_t t) {
        ...
         if (!loop) {
            CFRunLoopRef newLoop = __CFRunLoopCreate(t);
            __CFLock(&loopsLock);
            loop = (CFRunLoopRef)CFDictionaryGetValue(__CFRunLoops,pthreadPointer(t));
            if (!loop) {
                CFDictionarySetValue(__CFRunLoops, pthreadPointer(t), newLoop);
                loop = newLoop;
            }
             __CFUnlock(&loopsLock);
	 	    CFRelease(newLoop);
        }
        ...
    }
    ```
   
- Runloop会在线程结束时销毁
- 主线程的Runloop已经自动获取（创建），子线程默认没有开启Runloop


## Runloop相关的类

Core Foundation 中关于Runloop的5个类

- CFRunloopRef
- CFRunloopModeRef
- CFRunloopSourceRef
- CFRunloopTimerRef
- CFRunloopObserverRef

```
typedef struct __CFRunLoop * CFRunloopRef;

struct __CFRunLoop {
    ...
    pthread_t _pthread;
    CFMutableSetRef _commonModes;
    CFMutableSetRef _commonModeItems;
    CFRunloopModeRef _currentMode;
    CFMutableSetRef _modes;
    ...
};

typedef struct __CFRunLoopMode *CFRunLoopModeRef;

struct __CFRunLoopMode {
    ...
    CFStringRef _name;
    CFMutableSetRef _sources0; // CFRunloopSourceRef数组
    CFMutableSetRef _sources1; // CFRunloopSourceRef数组
    CFMutableArrayRef _observers; // CFRunloopObserverRef数组
    CFMutableArrayRef _timers; // CFRunloopTimerRef数组 
    ...
}
```

通过源码我们可以得知，一个Runloop对象里面有多个mode，存放在`_modes`成员属性里面。其中有一个mode是`_currentMode`。 然后每个mode都有`name`、`source0`、`source1`等数组属性

- CFRunloopModeRef 代表Runloop的运行模式
- Runloop启动只能选择其中一个Mode作为currentMode
- 如果需要切换Mode，只能退出当前Loop，再重新选择一个Mode进入
	- 不同组的Source0/Source1/Timer/Observer能分隔开来，互不影响
- 如果Mode里面没有任何Source0/Source1/Timer/Observer，Runloop会立马退出

### CFRunloopModeRef

- 两种常见的Mode
	- `kCFRunLoopDefaultMode`（`NSDefaultRunloopMode`）: App的默认Mode，通常主线程是在这个Mode下运行
    - `UITrackingRunLoopMode`界面跟踪Mode，用于ScrollView追踪触摸滑动，保证界面滑动时不受其他Mode影响

- Source0
	- 触摸事件处理
    - `performSelector:onThread:`

- Source1
	- 基于Port的线程间通信
    - 系统事件捕捉（捕捉后到Source0去处理）
    
- Timers
	- NSTimer
    - `performSelector:withObject:afterDelay:`

- Observers
	- 用于监听Runloop的状态
    - UI刷新（BeforeWaiting）在Runloop休眠之前会执行一次UI刷新
    - Autorelease pool 在Runloop休眠之前自动释放某些内存
    
    
### CFRunloopObserverRef

Runloop的几种状态

```
/* Run Loop Observer Activities */
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    kCFRunLoopEntry = (1UL << 0),         // 即将进入Loop 
    kCFRunLoopBeforeTimers = (1UL << 1),  // 即将处理Timer
    kCFRunLoopBeforeSources = (1UL << 2), // 即将处理Source
    kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠
    kCFRunLoopAfterWaiting = (1UL << 6),  // 刚从休眠中唤醒
    kCFRunLoopExit = (1UL << 7),          // 即将退出Loop
    kCFRunLoopAllActivities = 0x0FFFFFFFU
};
```

我们可以自己添加一个监听者来监听Runloop的状态变化

1. 定义监听回调

  ```
  void observeRunLoopActivities(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
      switch (activity) {
          case kCFRunLoopEntry:
              NSLog(@"kCFRunLoopEntry");
              break;
          case kCFRunLoopBeforeTimers:
              NSLog(@"kCFRunLoopBeforeTimers");
              break;
          case kCFRunLoopBeforeSources:
              NSLog(@"kCFRunLoopBeforeSources");
              break;
          case kCFRunLoopBeforeWaiting:
              NSLog(@"kCFRunLoopBeforeWaiting");
              break;
          case kCFRunLoopAfterWaiting:
              NSLog(@"kCFRunLoopAfterWaiting");
              break;
          case kCFRunLoopExit:
              NSLog(@"kCFRunLoopExit");
              break;
          default:
              break;
      }
  }
  ```

2. 创建监听者

  ```
  /// 创建Observer
  CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, observeRunLoopActivities, NULL);
  /// 添加Observer
  CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
  CFRelease(observer);
  ```
  
## Runloop的运行逻辑


### 流程分析

1. 通知Observers：进入Loop
2. 通知Observers：即将处理Timers
3. 通知Observers：即将处理Sources
4. 处理Blocks（特指执行CFRunLoopPerformBlock内的block参数）
	```
    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopCommonModes, ^{
        
    });
    ```
5. 处理Source0（可能会再次处理Blocks，因为有可能在处理Source0的时候添加了Blocks）
6. 如果存在Source1，就跳转到第8步
7. 通知Observers：开始休眠（等待消息唤醒）
8. 通知Observers：结束休眠（被某个消息唤醒，被什么东西唤醒就处理什么东西）
	- 处理Timer
    - 处理GCD Async To Main Queue
    - 处理Source1
9. 处理Blocks
10. 根据前面的执行结果，决定如何操作（如下几种可能）
	1. 回到第2步
    2. 退出Loop
11. 通知Observers：退出Loop

### 源码分析

通过在控制台执行命令`bt`我们可以看到开始是调用了`CFRunLoopRunSpecific`函数，核心源码如下

```
SInt32 CFRunLoopRunSpecific(CFRunLoopRef rl, CFStringRef modeName, CFTimeInterval seconds, Boolean returnAfterSourceHandled) {     /* DOES CALLOUT */
    
    ...
    /// 通知Observers：进入Loop
	__CFRunLoopDoObservers(rl, currentMode, kCFRunLoopEntry);
    
    /// 具体要做的事情
	result = __CFRunLoopRun(rl, currentMode, seconds, returnAfterSourceHandled, previousMode);
	
    /// 通知Observers：退出Loop
    __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);

    ...
    return result;
}

```

然后查看一下`__CFRunLoopRun`内的核心处理代码

```
static int32_t __CFRunLoopRun(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFTimeInterval seconds, Boolean stopAfterHandle, CFRunLoopModeRef previousMode) {
    ...
    int32_t retVal = 0;
    do {
        
        /// 通知Observers：即将处理Timers
        __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeTimers);
        
        /// 通知Observers：即将处理Sources
         __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeSources);
        
        /// 处理Blocks
        __CFRunLoopDoBlocks(rl, rlm);
        
        /// 处理Source0
        Boolean sourceHandledThisLoop = __CFRunLoopDoSources0(rl, rlm, stopAfterHandle);
        if (sourceHandledThisLoop) {
            /// 处理Blocks
            __CFRunLoopDoBlocks(rl, rlm);
        }
        
        Boolean poll = sourceHandledThisLoop || (0ULL == timeout_context->termTSR);
        
        /// 判断有无Source1
        if (__CFRunLoopServiceMachPort(dispatchPort, &msg, sizeof(msg_buffer), &livePort, 0, &voucherState, NULL)) {
            /// 如果有Source1，就跳转到handle_msg
            goto handle_msg;
        }
        
        /// 通知Observers：即将休眠
        __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeWaiting);
        __CFRunLoopSetSleeping(rl);
        
        do {
            /// 等待别的消息来唤醒当前线程
            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);
        } while (1);
        
        __CFRunLoopSetIgnoreWakeUps(rl);
        
        __CFRunLoopUnsetSleeping(rl);
        /// 通知Observers：结束休眠
        __CFRunLoopDoObservers(rl, rlm, kCFRunLoopAfterWaiting);
        
    handle_msg:;
        /// 被Timer唤醒
        if (modeQueuePort != MACH_PORT_NULL && livePort == modeQueuePort) {
            CFRUNLOOP_WAKEUP_FOR_TIMER();
            /// 处理Timers
            if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time())) {
                // Re-arm the next timer, because we apparently fired early
                __CFArmNextTimerInMode(rlm, rl);
            }
        /// 被GCD唤醒
        } else if (livePort == dispatchPort) {
            CFRUNLOOP_WAKEUP_FOR_DISPATCH();
            /// 处理GCD
            __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
        } else { /// 被Source1唤醒
            CFRUNLOOP_WAKEUP_FOR_SOURCE();
            /// 处理Source1
            __CFRunLoopDoSource1(rl, rlm, rls, msg, msg->msgh_size, &reply) || sourceHandledThisLoop;
            
        }
        
        /// 处理Blocks
        __CFRunLoopDoBlocks(rl, rlm);
        
        /// 设置返回值
        if (sourceHandledThisLoop && stopAfterHandle) {
            retVal = kCFRunLoopRunHandledSource;
        } else if (timeout_context->termTSR < mach_absolute_time()) {
            retVal = kCFRunLoopRunTimedOut;
        } else if (__CFRunLoopIsStopped(rl)) {
            __CFRunLoopUnsetStopped(rl);
            retVal = kCFRunLoopRunStopped;
        } else if (rlm->_stopped) {
            rlm->_stopped = false;
            retVal = kCFRunLoopRunStopped;
        } else if (__CFRunLoopModeIsEmpty(rl, rlm, previousMode)) {
            retVal = kCFRunLoopRunFinished;
        }
        
    } while (0 == retVal);
    
    return retVal;
}
```

执行顺序跟我们上面提及的执行流程是相似的，最后的返回值如果是0的话，那么就继续循环，如果是其他值，那么就会退出循环，继而退出Runloop


上面提及的处理Timers函数，处理GCD函数和处理Source1的函数，都会调用到`__CFRUNLOOP_IS_CALLING_OUT_TO_A_xxx_FUNCTION__`这个函数(这个xxx代表Observer、Block、Source0或者Timer等，见下表)，在这个函数里面，再去执行对应的操作，比如UIKit的界面刷新、Foundation定时器的执行

|执行的事情|调用的函数|
|---|---|
|进入Loop|__CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__|
|处理Blocks|__CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__|
|处理Source0|__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__|
|处理Timer|__CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__|
|处理GCD|__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__|
|处理SOURCE1|__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__|

GCD只有在回调到主线程的时候才会调用到Runloop的函数，比如下面这种情况 

```
dispatch_async(dispatch_get_global_queue(0,0), ^{
    dispatch_async(dispatch_get_main_queue(), ^{
    	...
    });
});
```

### Runloop休眠的实现原理

当Runloop需要休眠的时候，会调用用户态的API，然后内部调用mach_msg()切换到内核态，当有消息的时候，就会从内核态切换回用户态的API去处理消息

用户态 ： mach_msg() -> 内核态： mach_msg() -> 用户态：处理消息

内核态：
1. 等待消息
2. 没有消息就让线程休眠
3. 有消息就唤醒线程

## NSTimer

由于NSTimer默认是运行在`NSDefaultRunloopMode`的，所以在滚动的时候不会执行定时器，因为滚动的时候系统会切换到`UITrackingRunLoopMode`

这时候我们需要把NSTimer设置到`NSRunLoopCommonModes`里，如下

```
static int count = 0;
NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
    NSLog(@"%d",++count);
}];
[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
```

`NSDefaultRunloopMode`、`UITrackingRunLoopMode`才是真正存在的模式

`NSRunLoopCommonModes`并不是一个真的模式，它只是一个标记

timer能在`_commonModes`数组中存放的模式下工作

```
struct __CFRunLoop {
    ...
    pthread_t _pthread;
    CFMutableSetRef _commonModes; // 存放着NSDefaultRunloopMod，UITrackingRunLoopMode
    CFMutableSetRef _commonModeItems; // 存放着common模式下要处理的对象，比如上面的timer
    CFRunloopModeRef _currentMode;
    CFMutableSetRef _modes; 	// 存放着所有的模式
    ...
};
```

## 线程保活

### 基本原理


一般情况下，我们创建线程后，当线程的任务执行完了，线程就会销毁，所以有时候我们需要让线程执行完任务后依旧存在，等到我们主动让他销毁他才会销毁。

首先我们创建一条线程

```
self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
```

要让这条线程一直活着，我们可以让这个`run`方法不要结束

这里添加一个Runloop，由于获取Runloop的时候就会创建Runloop，所以我们获取Runloop即可，然后调用`addPort:forMode:`方法，添加一个`Source0`

这样子线程就会卡在`[[NSRunLoop currentRunLoop] run];`这一行中，不会让方法执行完，线程也就不会销毁

```
- (void)run {
    NSLog(@"%@ %s begin",NSThread.currentThread,__func__);
    [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc] init] forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
    /// 不会走到这里
    NSLog(@"%@ %s end",NSThread.currentThread,__func__);
}
```

然后下一步我们需要调用一个方法去销毁这个线程，比如`CFRunLoopStop(CFRunLoopGetCurrent())`，但是如果我们这么做

```
- (void)stop {
    CFRunLoopStop(CFRunLoopGetCurrent());
}

/// 尝试在我们指定的线程上停止这个线程内的Runloop
[self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:NO];
```

发现线程不会销毁，原因是`[[NSRunLoop currentRunLoop] run];`执行后，会在一个死循环内执行Runloop的`runMode:beforeDate:`方法，类似于

```
while(1) {
    [[NSRunLoop currentRunLoop] runMode: beforeDate:xxx];
}
```

`CFRunLoopStop(CFRunLoopGetCurrent());`只是停止了其中的一次方法调用，进入下个循环后又会开启，所以用这个方法去完全停止Runloop是没用的

所以我们要使用别的方式去替代`[[NSRunLoop currentRunLoop] run];`开启线程，因为这个`run`方法是专门用于开启一个永不销毁的线程。

只需要改造一下上面那个while方法就好，给self添加一个bool属性

```

@property(nonatomic,assign) BOOL isStop;

- (void)run {
    NSLog(@"%@ %s begin",NSThread.currentThread,__func__);
    [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc] init] forMode:NSDefaultRunLoopMode];
    while(!self.isStop) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}
    NSLog(@"%@ %s end",NSThread.currentThread,__func__);
}

- (void)stop {
    self.isStop = YES;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

```

这样子我们调用run方法线程就会启动，调用stop方法，while循环就会退出，`CFRunLoopStop(CFRunLoopGetCurrent());`停止了本次RunLoop，Runloop退出，这样子就能走到打印end那里，线程的方法走完了，线程就可以销毁了

### 封装

```
@interface MyThread : NSObject

/// 开启线程
- (void)run;

/// 销毁线程
- (void)stop;

/// 执行任务
- (void)executeTask:(void(^)(void))block;

@end

@interface MyThread()

@property (nonatomic, strong) Thread *innerThread;

@property (nonatomic, assign, getter=isStopped) BOOL stopped;

@end

@implementation MyThread

- (instancetype)init {
    if (self = [super init]) {
        
        __weak typeof(self) weakSelf = self;
        
        /// 创建线程 开启Runloop
        self.innerThread = [[Thread alloc] initWithBlock:^{
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc] init] forMode:NSDefaultRunLoopMode];
            
            /// 因为dealloc的时候weakSelf已经空了，所以要明确self存在并且不停止时候，才循环启动Runloop
            while (weakSelf && !weakSelf.isStopped) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }];
    }
    return self;
}

- (void)run {
    if (!self.innerThread) return;
    
    /// 开启线程，启动Runloop
    [self.innerThread start];
}

- (void)stop {
    if (!self.innerThread) return;
    
    /// 停止线程
    [self performSelector:@selector(__stop) onThread:self.innerThread withObject:nil waitUntilDone:YES];
}

- (void)executeTask:(void (^)(void))block {
    if (!self.innerThread || !block) return;
    
    /// 执行子线程任务
    [self performSelector:@selector(__executeTask:) onThread:self.innerThread withObject:block waitUntilDone:NO];
}

#pragma mark - private method

- (void)__stop {

	/// 标记需要退出Runloop
    self.stopped = YES;
    
    /// 退出本次Runloop
    CFRunLoopStop(CFRunLoopGetCurrent());
    
    /// 取消强引用
    self.innerThread = nil;
}

- (void)__executeTask:(void (^)(void))block {
    block();
}

- (void)dealloc {
    /// 自动调用停止方法
    [self stop];
    NSLog(@"%s",__func__);
}

@end

/// 只是为了监听线程的销毁行为
@interface Thread : NSThread
@end

@implementation Thread

- (void)dealloc {
    NSLog(@"%s",__func__);
}

@end
```