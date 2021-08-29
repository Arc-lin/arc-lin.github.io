title: AppDelegate事件分发
tags:
  - iOS
  - 架构
categories:
  - iOS
abbrlink: 7e5c9fa9
date: 2020-03-22 11:27:11
---
## 引言

当App发展庞大的时候，势必会导致AppDelegate类的庞大，所以如何去优化AppDelegate成为组件化工作中的主要部分之一。

<!--more-->

## 现状

举个例子，比如App中拥有
1. 用户管理组件
2. 首页组件
3. 消息组件

那么他们分别需要在`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`中实现

1. 访问接口更新用户信息
2. 配置首页弹窗
3. 访问接口获取用户未读消息数

假设这三个事件之间无关联，只是在初始化自己的模块后做准备工作，但是同时他们堆叠在同一个方法内，必然会导致方法臃肿。设想另外一个场景，假如开发者A只负责维护AppDelegate及主工程项目，开发者B只负责维护用户管理组件，那么开发者B要在App初始化的时候，再加入一个`将用户信息传到大数据中心统计`的功能，那么由于他不拥有`AppDelegate`的修改权限，只能让A排期去协助工作，同理可得，当组件变多，团队庞大的时候，开发者A将会有很多协助工作要做，这就是这次要讨论的问题。

## 想法

是否可以将组件的初始化安排到组件内部中，而不在AppDelegate类中直接进行维护呢？

想法1. 组件新增一个类，然后在该类里面进行初始化。AppDelegate import 这个类，调用这个类中的方法。

缺点：AppDelegate需要耦合该组件，如果要去掉该组件或者新增别的组件，AppDelegate需要增加维护成本。

想法2. AppDelegate主动分发事件，用通知的形式分发给每个组件消息。

缺点：由于组件无法依赖主工程，所以通知名无法维护，另外通知会分发到不需要在AppDelgate初始化的组件，属于通知滥用。

想法3. AppDelegate主动分发事件，组件新增一个类，将AppDelegate事件通过协议的方式分发到这个类中，类遵循该协议。

缺点：技术上不可行，无法得知哪些类实现了协议。

想法4. 组件新增一个类，在`+ (void)load`中将类名注册进入管理类，AppDelegate执行的时候取出所有类名，进行实例化和事件分发。

缺点：在`+ (void)load`中进行工作会增加App启动耗时

想法5. 组件新增一个类，在主工程维护一个plist，将类名写进该plist，AppDelegate执行的时候取出所有类名，进行实例化和事件分发。

缺点：plist在主工程，同样无法满足无缝对接的需求，A同事仍然需要对接维护。

## 解决方案

目前能得出的最优解决方案：

将类名注入mach-o文件中，在编译期写入，在AppDelegate事件分发的时候取出并实例化，不占用App启动耗时，也不用维护多一个plist文件。

## 试验

1. 新建 MacOS - Command Line Tool 项目，命名为`TestC`
2. 加入我们想注入字符串`ModuleAModule`,将其存储在名为`TestModes`的section内，那么在main.m中写如下代码：

	```
	char * kModuleAModule_mod __attribute((used, section("__DATA, ""TestModes"" "))) = """ModuleAModule""";

	int main(int argc, const char * argv[]) {
		// insert code here...
		printf("Hello, World!\n");
		return 0;
	}

	```
3. 输出这个mach-o文件的所有segment和section`otool -l TestC`
	
	部分结果：

	```
	Section
	  sectname TestModes
	   segname __DATA
		  addr 0x0000000100002008
		  size 0x0000000000000008
		offset 8200
		 align 2^3 (8)
		reloff 0
		nreloc 0
		 flags 0x00000000
	 reserved1 0
	 reserved2 0
	```
	
	看到了`Test Modes`了，继续看一下section的内容`otool -s __DATA TestModes TestC`
	
	结果
	
	```
	TestC:
Contents of (__DATA,TestModes) section
0000000100002008	92 0f 00 00 01 00 00 00 
	```
	发现`0000000100002008`这个地址可能是我们要的东西，再看看这个地址里有啥
	`otool -V -s __TEXT __cstring TestC `打印所有字符串数据内容
	看到了
	
	```
	Contents of (__TEXT,__cstring) section
		0000000100000f92  ModuleAModule
		0000000100000fa0  Hello, World!\n
	```
	找到了我们想注入的类名`ModuleAModule`
	这样，类名就被存储在mach-o文件的section中了。
	
4. 取出类名， 代码如下

	```objectivec
	NSArray<NSString *>* readConfiguration(char *sectionName,const struct mach_header *mhp)
	{
		NSMutableArray *configs = [NSMutableArray array];
		unsigned long size = 0;
	#ifndef __LP64__
		uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
	#else
		const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
		uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
	#endif

		unsigned long counter = size/sizeof(void*);
		for(int idx = 0; idx < counter; ++idx){
			char *string = (char*)memory[idx];
			NSString *str = [NSString stringWithUTF8String:string];
			if(!str)continue;
			if(str) [configs addObject:str];
		}

		return configs;
	}
	
	static void dyld_callback(const struct mach_header *mhp, intptr_t vmaddr_slide)
	{
		NSArray *mods = readConfiguration("TestModes", mhp);
		for (NSString *modName in mods) {
			if (modName) {
				NSLog(@"取得：%@",modName);
			}
		}
	}

	__attribute__((constructor))
	void initProphet() {
		_dyld_register_func_for_add_image(dyld_callback);
	}
	```
	
	当一个函数被`__attribute__((constructor))`修饰时，表示这个函数是这个镜像的初始化函数，在镜像被加载时，首先会调用这个函数。（镜像指的是mach-o和动态共享库，在工程运行时，可以使用lldb命令`image list`查看这个工程中加载的所有镜像。）
上述代码表示`initProphet`函数被指定为mach-o的初始化函数，当dyld（动态链接器）加载mach-o时，执行`initProphet`函数，其执行时机在main函数和类的load方法之前。

	当`_dyld_register_func_for_add_image(dyld_callback);`被执行时，如果已经加载了镜像，则每存在一个已经加载的镜像就执行一次`dyld_callback`函数，在此之后，每当有一个新的镜像被加载时，也会执行一次`dyld_callback`函数。
（`dyld_callback`函数在镜像的初始化函数之前被调用，mach-o是第一个被加载的镜像，调用顺序是：`load mach-o -> initProphet -> dyld_callback -> load other_image -> dyld_callback -> other_image_initializers -> ......`）

	所以，当程序启动时，会多次调用dyld_callback函数。
	在dyld_callback函数中，使用下列函数来获取[步骤2]中存储的类名
	```
	extern uint8_t *getsectiondata(
    const struct mach_header_64 *mhp,
    const char *segname,
    const char *sectname,
    unsigned long *size);
	```
	segname的值为`__DATA`，sectname的值为`TestMods`
	
## 封装组件

有了上面的指导思想，那么我们就可以封装组件了，具体内容见[ALComponentManager](https://github.com/Arc-lin/ALComponentManager)

### 使用方法

#### AppDelegate继承自ALAppDelegate

只需要在实现`UIApplicationDelegate`的方法内部调用super方法即可，如

```objectivec
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [super applicationWillResignActive:application];
}

```

#### AppDelegate继承自UIResponder

在AppDelegate的各个方法做分发埋点，触发到埋点后事件会分发到各个组件类里面
	
如
```objectivec
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
```
埋点如下
```objectivec
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
  {
      [[ALComponentManager sharedManager] triggerEvent:ALSetupEvent];
      [[ALComponentManager sharedManager] triggerEvent:ALInitEvent];

      dispatch_async(dispatch_get_main_queue(), ^{
          [[ALComponentManager sharedManager] triggerEvent:ALSplashEvent];
      });
  #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
      if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0f) {
          [UNUserNotificationCenter currentNotificationCenter].delegate = self;
      }
  #endif
      return YES;
  }
  ```
	
其他埋点见组件Demo
	
#### 给每个组件创建组件管理类

1. 给每个组件创建一个类并写上注解，如`ALComponentA.m`

	```objectivec
	@ALMod(ALComponentA);
	@interface ALComponentA()<ALComponentProtocol>

	@end

	@implementation ALComponentA

	@end
	```
	
2. 实现协议`ALComponentProtocol`和需要的协议方法。
	这个协议里面蕴含了基本所有的`AppDelegate`方法，当然要触发这些方法都是要预先在AppDelegate写上埋点。
	
	```objectivec
	@implementation ALComponentA

	+ (void)load
	{
		NSLog(@"Component A Load");    
	}

	- (instancetype)init
	{
		if (self = [super init]) {
			NSLog(@"ComponentA Init");
		}
		return self;
	}

	- (void)modSetUp:(ALContext *)context
	{
		NSLog(@"ComponentA setup");
	}

	@end
	```
	
3. 接下来你就可以尝试使用了。

## 疑问

要是组件间的初始化互相依赖怎么办？

还能怎么办，已经违背了组件隔离的原则，就只能按原来的方法处理了。

## 参考

[BeeHive](https://github.com/alibaba/BeeHive)