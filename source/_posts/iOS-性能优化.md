title: iOS --- 性能优化
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: a2ff8280
date: 2021-08-31 21:42:00
---
本文主要介绍iOS内常用的性能优化方案

<!-- more -->

## CPU和GPU

- 在屏幕成像的过程中，CPU和GPU起着至关重要的作用
	- CPU 
		- 对象的创建和销毁，对象属性的调整、布局计算、文本的计算和排版、图片格式转换和解码、图像的绘制 
	- GPU
		- 纹理的渲染

- 在iOS中是双缓冲机制，有前帧缓存、后帧缓存（）
		
```
CPU->计算->GPU->渲染->帧缓存->读取->视频控制器->显示->屏幕   
```

## 屏幕成像原理

首先先发出一个垂直同步信号（VSync），然后再一行行发出水平同步信号（HSync），直到最后一行HSync发出之后，一帧就渲染完成，然后再次发出一个VSync，渲染下一帧。

<img src="https://i.loli.net/2021/08/31/hWqVypmfbtga4eK.png" >

## 卡顿

### 卡顿产生的原因

![1682758-5be402cc0ab5dc56.png](https://i.loli.net/2021/08/31/ZTNhbeyRiq8UgmV.png)

1. 首先第一个VSync进入，CPU开始计算处理，然后交给GPU渲染，然后显示到屏幕上
2. 然后第二个VSync进入，这时候CPU处理的时间比较长，交给GPU后， GPU还没处理完，第三个VSync就进来了，但是因为GPU没处理完。第二帧还不能显示，所以这时候直接取上一帧数据显示，造成第一帧长时间停留
3. 然后过了一段时间GPU终于处理完了，但是第四个VSync还没来，所以就等，等到第四个VSync进来了，就开始拿刚才生成好的那一帧去显示，然后开始继续第三帧的计算

- 解决卡顿的主要思路
	- 尽可能减少CPU、GPU资源损耗
- 按照60fps的刷新率，每个16ms就会有一次VSync信号 

### 卡顿检测

- 平时所说的__卡顿__主要是因为在主线程执行了比较耗时的操作
- 可以添加`Observer`到主线程`Runloop`中，通过监听`Runloop`状态切换的耗时，以达到监控卡顿的目的

> 参考：[LXDAppFluecyMonitor](https://github.com/UIControl/LXDAppFluecyMonitor/blob/master/LXDAppFluecyMonitor/LXDAppFluecyMonitor/LXDAppFluecyMonitor.m)

```objectivec
static void lxdRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void * info) {
     /// 更新当前Runloop状态
    SHAREDMONITOR.currentActivity = activity;
    dispatch_semaphore_signal(SHAREDMONITOR.semphore);
};

- (void)startMonitoring {
    if (_isMonitoring) { return; }
    _isMonitoring = YES;
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)self,
        NULL,
        NULL
    };
    /// 创建监听对象
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &lxdRunLoopObserverCallback, &context);
    /// 在CommonModes添加监听者
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    /// 子线程异步串行队列中添加死循环
    dispatch_async(lxd_event_monitor_queue(), ^{
        while (SHAREDMONITOR.isMonitoring) {
        	/// 如果当前状态是BeforeWaiting（即将进入休眠）的话
            if (SHAREDMONITOR.currentActivity == kCFRunLoopBeforeWaiting) {
                __block BOOL timeOut = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    timeOut = NO; // 即将休眠的时候回到主线程超时状态改为NO
                    dispatch_semaphore_signal(SHAREDMONITOR.eventSemphore); //解锁
                });
                [NSThread sleepForTimeInterval: lxd_time_out_interval]; // 子线程休眠一秒
                if (timeOut) {
                    [LXDBacktraceLogger lxd_logMain]; // 打印堆栈
                }
                dispatch_wait(SHAREDMONITOR.eventSemphore, DISPATCH_TIME_FOREVER); // 加锁
            }
        }
    });
    
    dispatch_async(lxd_fluecy_monitor_queue(), ^{
        while (SHAREDMONITOR.isMonitoring) {
            long waitTime = dispatch_semaphore_wait(self.semphore, dispatch_time(DISPATCH_TIME_NOW, lxd_wait_interval)); // 等待200纳秒，看是否能拿到锁
            if (waitTime != LXD_SEMPHORE_SUCCESS) { // 拿不到锁
                if (!SHAREDMONITOR.observer) {
                    SHAREDMONITOR.timeOut = 0;
                    [SHAREDMONITOR stopMonitoring];
                    continue;
                }
                /// Runloop 即将处理Source或者刚从休眠中唤醒
                if (SHAREDMONITOR.currentActivity == kCFRunLoopBeforeSources || SHAREDMONITOR.currentActivity == kCFRunLoopAfterWaiting) {
                    if (++SHAREDMONITOR.timeOut < 5) { // 超时次数+1，然后如果超时次数大于5次就打印堆栈
                        continue;
                    }
                    [LXDBacktraceLogger lxd_logMain];
                    [NSThread sleepForTimeInterval: lxd_restore_interval];
                }
            }
            SHAREDMONITOR.timeOut = 0;
        }
    });
}
```

### 卡顿优化 - CPU

- 尽量使用轻量级的对象，比如用不到事件处理的地方，可以考虑使用`CALayer`（只是拿来渲染）取代`UIView`（渲染+处理点击事件等）
- 不要频繁地调用`UIView`的相关属性，比如`frame`、`bounds`、`transform`等属性，尽量减少不必要的修改
- 尽量提前计算好布局，在有需要时一次性调整对应的属性，不要多次修改属性
- Autolayout会比直接设置frame消耗更多的CPU资源
- 图片的Size最好跟UIImageView的size保持一致
- 控制一下线程的最大并发数量
- 尽量把耗时操作放到子线程
	- 文本处理（尺寸计算、绘制）
	- 图片处理（解码、绘制）

图片子线程解码举例

```objectivec
- (void)renderImage {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        /// get CGImage
        CGImageRef cgImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:xxx]].CGImage;
        
        size_t width = CGImageGetWidth(cgImage);
        size_t height = CGImageGetHeight(cgImage);
        if (width == 0 || height == 0) return;
        
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
        BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                          alphaInfo == kCGImageAlphaNoneSkipFirst ||
                          alphaInfo == kCGImageAlphaNoneSkipLast);

        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo);
        if (!context) {
            return;
        }
        
        // Apply transform
        CGAffineTransform transform = CGAffineTransformIdentity;
        CGContextConcatCTM(context, transform);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage); // The rect is bounding box of CGImage, don't swap width & height
        CGImageRef newImageRef = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        
        // back to the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [[UIImage alloc] initWithCGImage:newImageRef];
            CGImageRelease(newImageRef);
        });
    });
}
```

### 卡顿优化 - GPU

- 尽量避免短时间内大量图片的显示，尽可能将多张图片合成一张进行显示
- GPU能处理的最大纹理尺寸是**4096*4096**，一旦超过这个尺寸，就会占用CPU资源进行处理，所以纹理尽量不要超过这个尺寸
- 尽量减少视图数量和层次
- 减少透明的视图（alpha < 1），不透明的就设置`opaque`为`YES`
- 尽量避免出现离屏渲染

#### 离屏渲染

- 在OpenGL中，GPU有2种渲染方式
	- On-Screen Rendering：当前离屏渲染，在当前用于显示屏幕缓冲区进行渲染操作
	- Off-Screen Rendering: 离屏渲染，在当前屏幕缓冲区以外开辟一个缓冲区进行渲染操作 

- 离屏渲染消耗性能的原因
	- 需要创建新的缓冲区
	- 离屏渲染的整个过程，需要多次切换上下文环境，先是从当前屏幕（On-Screen）切换到离屏（Off-Screen）;等到离屏渲染结束以后，将离屏缓冲区的渲染结果显示到屏幕上，又需要将上下文环境从离屏切换到当前屏幕上。

- 哪些操作会触发离屏渲染
	- 光栅化，`layer.shouldRasterize = YES`
	- 遮罩 `layer.mask`
	- 圆角，同时设置 `layouer.maskToBounds = YES`, `layer.cornerRadius`大于0
		- 考虑通过`CoreGraphics`绘制裁剪圆角，或者叫美工提供圆角图片
	- 阴影，`layer.shadowXXX`
		- 如果设置了`layer.shadowPath`就不会产生离屏渲染

## 耗电优化

### 主要来源

- CPU处理，Processing
- 网络，Networking
- 定位，Location
- 图像，Graphics

### 优化

- 尽可能降低CPU、GPU功耗
- 少用定时器
- 优化I/O操作
	- 尽量不要频繁写入小数据，最好批量一次性写入 
	- 读写大量重要数据时，考虑使用`dispatch_io`，其提供了基于GCD的异步操作文件的I/O的API.用`dispatch_io`系统会优化磁盘访问
	- 数据量比较大的，建议使用数据库(SQLite、CoreData)

- 网络优化
	- 减少、压缩网络数据
	- 如果多次请求结果是相同的，尽量使用缓存
	- 使用断点续传，否则网络不稳定时可能多次传输相同的内容
	- 网络不可用时，不要尝试执行网络请求
	- 让用户可以取消长时间运行或者速度很慢的网络操作，设置合适的超时时间
	- 批量传输，比如，下载视频流时，不要传输很小的数据包，直接下载整个文件或者一大块一大块地下载，如果下载广告，一次性多下载一些，然后再慢慢展示，如果下载电子邮件，一次下载多封，不要一封一封地下载

- 定位优化
	- 如果只是需要快速确定用户当前位置，最好用`CLLocationManager`的`requestLocation`方法，定位完成后，会自动让定位硬件断电
	- 如果不是导航应用， 尽量不要实时更新位置，定位关闭就关掉定位服务
	- 尽量降低定位精度，比如尽量不要使用精度最高的`kCLLocationAccuracyBest`
	- 需要后台定位时，尽量设置`pausesLocationUpdatesAutomatically`为YES，如果用户不太可能移动的时候，系统会自动暂停位置更新
	- 尽量不要使用`startMonitoringSignificantLocationChanges`，优先考虑`startMonitoringForRegion:`

- 硬件检测优化
	- 用户移动、摇晃、倾斜设备时，会产生动作(motion)事件，这些事件由加速度计、陀螺仪、磁力计等硬件检测。在不需要检测的场合，应该及时关闭这些硬件。

## App启动优化

- App的启动可以分为2种
	- 冷启动（Code Launch）：从零开始启动App
	- 热启动（Warm Launch）：App已经在内存中，在后台存活着，再次点击图标

- App启动时间的优化，主要是针对冷启动进行优化
- 通过添加环境变量可以打印出App的启动时间分析（Edit Scheme -> Run -> Arguments）
	- `DYLD_PRINT_STATISTICS`设置为1 或者 `DYLD_PRINT_STATISTICS_DETAILS` （更加详细 ）
 	
- App的冷启动可以概括为3大阶段
	- dyld
	- runtime
	- main
	<img src="https://i.loli.net/2021/08/31/ldg1cjZCUPe5Gk6.png" >
	

  - dyld（dynamic link editor），Apple的动态链接器，可以用来装在Mach-O文件（可执行文件、动态库等 ）
  - 启动App时，dyld所做的事情有
      - 装载App的可执行文件，同时会递归加载所有依赖的动态库
      - 当dyld把可执行文件、动态库都装载到内存完毕后，会通知Runtime进行下一步的处理
  - 启动App时，runtime所做的事情有
      - 调用`map_images`进行可执行文件内容的解析和处理
      - 在`load_images`中调用`call_load_methods`,调用所有`Class`和`Category`的`+load`方法
      - 进行各种objc结构的初始化（注册Objc类，初始化类对象等等）
      - 调用C++静态初始化器和`__attribute((constructor))`修饰的函数
  - 到此为止，可执行文件和动态库中所有的符号（Class、Protocol、Selector、IMP、...）都已经按格式成功加载到内存中，被`runtime`所管理
  -  总结
      - App的启动由dyld主导，将可执行文件加载到内存，顺便加载所有依赖的动态库
      - 并由runtime负责加载成objc定义的结构
      - 所有初始化工作结束后，dyld就会调用main函数
      - 接下来就是`UIApplicationMain`函数，AppDelegate的`application:didFinishLaunchingWithOptions:`方法

### 优化方案

- 按照不同的阶段
	- dyld 
		- 减少动态库，合并一些动态库（定期清理不必要的动态库）
		- 减少Objc类，分类的数量，减少selector的数量（定期清理不必要的类，分类）
		- 减少C++虚函数数量
		- Swift尽量使用struct
	- runtime
		- 用`+initialize`和`dispatch_once`取代所有的`__attribute((constructor))`、C++静态构造器 、ObjC的`+load`
	- main
		- 在不影响用户体验的前提下，尽可能将一些操作延迟，不要全部都放在`finishLaunch`方法中
		- 按需加载 

## 安装包瘦身

- 安装包（IPA）主要由可执行文件、资源组成

- 资源（图片、视频、音频等）
	- 采取无损压缩
	- 去除没有用到的资源(github :LSUnusedResources）

- 可执行文件瘦身
	- 编译器优化 
		- Strip Linked Product 、 Make Strings Read-Only、 Symbols Hidden By Defaults设置为YES
		- 去掉异常支持，Enable C++ Exceptions、Enable Objective-C Exceptions 设置为NO，Other C Flags  添加 -fno-exceptions
	- 利用AppCode([https://www.jetbrains.com/objc](https://www.jetbrains.com/objc))检测未使用的代码：菜单栏 -> Code -> Inspect Code
	- 编写LLVM插件检测出重复代码，未被调用的代码
	- 生成Link Map文件，可以查看可执行文件的具体组成（在Build Setting->Write Link Map File 改为true，就可以在Path to link map file 看到这个文件）
	- 可以借助第三方工具解析LinkMap文件：[https://github.com/huanxsd/LinkMap](https://github.com/huanxsd/LinkMap)