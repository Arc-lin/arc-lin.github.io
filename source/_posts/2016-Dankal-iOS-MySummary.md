---
title: 2016-Dankal-iOS-MySummary
author: Arclin
tags:
  - iOS
  - 杂谈
categories:
  - iOS
abbrlink: 61929cc2
date: 2017-01-24 00:00:00
---
总结2016在 Dankal 工作过程中学习到的东西

<!-- more -->

### Main Argument 主要论点
中介者
组件化
封装
MVVM
ReactiveCocoa

### 基于MVC的组件化设计 CTMediator + （CTNetworking -> DKNetworking -> DKHTTPTool）
CTMediator和CTNetworking 是我在5-6月份左右看的一套源码，出处是这里,然后去年年底作者又发布了[基于 CTMediator工程实践](http://casatwy.com/modulization_in_action.html)。总的设计思想如下：

### 组件逻辑

- CTMediator 是一种组件化方案，主要是针对大型项目多人开发情况下的一种方案。路由方式是 Targer-Action，通过这种方式进行模块之间的沟通，模块使用私有 pod 进行封装（这个是在第二篇的实践中提出来的），因为目前我们还没接触过这种大型的项目，所以一直停留在理论阶段（也就是虽然我看懂了源码的设计思想但是却没得地方实现），后来启动了觅书项目，打算尝试这种设计，结果发现过于大材小用了。模块的创建要先通过中介者进行注册，调用要通过中介者进行调用，总结一下大概就像这样子：

```
             --------------------------------------
             | [CTMediator sharedInstance]        |
             |                                    |
             |                openUrl:       <<<<<<<<<  (AppDelegate)  <<<<  Call From Other App With URL
             |                                    |
             |                   |                |
             |                   |/               |
             |                parseUrl            |
             |                                    |
             |                   |                |
.................................|...............................
             |                   |                |
             |                   |/               |
             |  performTarget:action:params: <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  Call From Native Module
             |                   |/               |
             |             -------------          |
             |             |  runtime  |          |
             |             -------------          |
             ---------------.---------.------------
                           .           .
                          .             .
-------------------------------      --------------------------------
|                       ·     |      |    ·                         |
|                     ·       |      |     ·                        |
|           Target            |      |           Target             |
|                             |      |                              |
|         /   |   \           |      |         /   |   \            |
|        /    |    \          |      |        /    |    \           |
|                             |      |                              |
|   Action Action Action ...  |      |   Action Action Action ...   |
|                             |      |                              |
|Service  A                   |      | Service  B                   |
-------------------------------      --------------------------------
```

这里面包括了内部调用和远程应用调用，远程应用调用因为我们目前还用不着所以先不管，内部调用的流程为了方便理解我举个例子，fromController通过performTarget:action:params:方法传入toController类名和在toController要执行的方法和所需的参数，这样子组件之间就实现了解耦，fromController 只需要知道他想去的地方是 toController和要给什么值出去，甚至这个 controller 存不存在都无所谓，而 toController 只需要遵循协议方法/重写父类方法去的到参数即可，然后里面就可以直接调这个参数，并且这一系列跳转规则和传参规则都通过 CTMediator 中介者去控制。

### 服务层（Service Layer） 或者叫 业务层（Business Layer）

刚刚总结了一下CTMediator的组件间的逻辑,现在来总结一下业务层与 ViewController 层之间的设计.因为虽然是 MVC，那当然也得尽量避免 Mess View Controller ,Service 在这里可以理解为数据仓库+业务逻辑仓库，为的是令ViewController中避免出现像数据 A处理判断完才显示到控件上的情况，尽量能把最直接的数据给 ViewController 显示,利用像下图这种方式，业务层暴露出 Target 和 action供外界调用，调用方法后就进入了CTMediator 进行处理，接下来的事情就像我上面说的一样了。

```
         --------------------------------
         |           Service  A         |
         ---  ----------  ----------  ---
           |  |        |  |        |  |
...........|  |........|  |........|  |...........
.          |  |        |  |        |  |          .
.        ---  ---    ---  ---    ---  ---        .
.        |action|    |action|    |action|        .
.        ---|----    -----|--    --|-----        .
.           |             |        |             .
.           |             |        |             .
.       ----|------     --|--------|--           .
.       |Target_A1|     |  Target_A2 |           .
.       -----------     --------------           .
..................................................
```

### CTNetworking -> DKNetworking -> DKHTTPTool

- CTNetworking 是一个基于AFNetworking的开源网络层组件，经过改装之后我组装出了 DKNetworking（虽然后面发现有 RAC神器之后就觉得这个东西不够轻便了）。

- CTNetworking 解决了以下几个问题
	- 使用哪种交互模式来跟业务层做对接？
	- 是否有必要将API返回的数据封装成对象然后再交付给业务层？
	- 使用集约化调用方式还是离散型调用方式去调用API？

- 上面三个问题分别给出的答案是
	- 代理模式
	- 没必要
	- 离散型

- CTNetworking考虑的东西相当地多，除了上面几个问题之外，还考虑到了网络层安全机制（数据传输，HTTPS）,链接环节的优化（链接传输量和链接复用）等，一开始看源码也是看的很懵逼
- 通过协议的方式进行组件内的方法封装

|协议名|解释|
|----|----|
|CTAPIManagerApiCallBackDelegate|回调协议|
|CTAPIManagerCallbackDataReformer|负责重新组装API数据的对象|
|CTAPIManagerValidator|验证器验证参数和返回|
|CTAPIManagerParamSourceDelegate|参数源|
|CTAPIManager|CTAPIBaseManager的派生类必须符合这个protocal|
|CTAPIManagerInterceptor|拦截器，拦截参数和回调|

- 用协议的好处就是各取所需。当你想要统一管理所有回调的时候，那你这个类只要遵循`CTAPIManagerApiCallBackDelegate`代理和实现对应的方法，如果你这个类想要拦截参数，那么就遵循`CTAPIManagerInterceptor`协议并实现对应的方法，大抵就是这种思想，然后底层就会进行各种判断并拼接各个协议的方法的返回值，最后发出请求，得到回调然后处理值并返回出去。

- CTNetworking 框架没有使用数据模型，原因就是认为模型嵌入模型的时候处理数据很麻烦，另外模型的复用性很差，容易出现类型爆炸，提高维护成本，还有就是不够NSDictionary、NSArray直观,最最重要的一点就是同一API的数据被不同View展示时，难以控制数据转化的代码，它们有可能会散落在任何需要的地方。所以框架使用了 Reformer 的方法去处理返回的数据（NSDictionary）转成 View 需要的数据（NSDictionary）。

- DKNetworking 把 Refromer 部分的实现给改了，依赖了 MJExtension，去实现数据模型数组，因为总感觉NSDictionary很麻烦，难维护就难维护吧，反正项目也不大。

- DKHTTPTool 是我在近期集成出来的框架，主要特性包括：
	- 支持缓存策略选择
	- 支持链式调用
	- 支持 RACSignal 返回
	- 支持拦截器、验证器
	- 支持直观的Logger输出
	- 支持全局请求头、请求参数
	- 服务器异常直接弹出异常数据而不是一坨 NSData
	- 支持错误码表，统一处理错误
    
还有其他的吗？忘记了
总的来说，这个还是挺管用的,毕竟能支持 RAC,符合我们现在的 
MVVM+ReactiveCocoa的架构

### MVVM+ReactiveCocoa

- ReactiveCocoa 博大精深，以致于现在都用不到它提供的功能的一半
- 第二份优秀的源码（虽然跑不起来）[MVVMReactiveCocoa](https://github.com/leichunfeng/MVVMReactiveCocoa)
- 产出成品[Poi](https://coding.net/u/Arclin/p/Poi/git)

### Navigation-With-ViewModel

 使用 MVVM 模式应该注意的问题

- 以 ViewModel 为驱动引导着整个应用而不是 ViewController
- ViewModel 中不应该引入任何 UIKit 框架
- 模块与模块间通过 服务总线 去沟通 , 减少模块之间的耦合

先看看用 ViewModel 进行 push操作的流程

 ```
--------------------------------    
|        ViewModel A           |   
---  ----------  ----------  ---   
	|
	| 
[- initWithService:params:]
	| ---------------
	| | service bus | --- > - pushViewModel: animated: 
	| ---------------                 |
	|			             （HOOK）[rac_responseToSelector:]
	|			                     |/
	|			               <DKNavigationProtocol>-- @{ viewModel:viewController}--->navigationController [pushViewController:animated:]
	|/
 --------------------------------
 |        ViewModel B           |
 ---  ----------  ----------  ---
```

说明： ViewModelA 与 ViewControllerA ，ViewModelB 与 ViewControllerB 在 Router 里面通过字典的方式绑定在了一起，然后通过 RAC的方法监听pushViewModel: animated: 方法的执行，然后通过字典得到viewController从而进行真正的 push 操作，大概就是这样子

### 抽出父类和ReactiveCocoa

MVVMReactiveCocoa 通过封装父类的方式来实现这个架构，这些父类已经被我抽出来了，过几天会传上去，然后先写一些使用说明

1. 每个 Vc 对应一个 ViewModel
2. TableViewController必须对应 ViewModel
3. ViewModel 的初始化方法在 - initliazed 中
4. 初始化之前添加一些额外的方法，需要重写 - initWithServer:params:
5. DKTableViewController是一个二维数组，里面封装的是 viewmodel
6. cell 要遵循 DKReactiveView 协议
7. 绑定 cell与 viewModel 就在 ViewController里面重写 configureCell:withObject
8. 待补充

ReativeCocoa 主要是用来实现 MVVM 的融合剂，当然也不一定要用 RAC去实现 MVVM,说实话 RAC 的学习成本还是相当高的，目前已经在尝试 DKRACHTTPTool,用纯 RAC 的方式去实现网络层和数据持久层的封装，另外还有些异常处理之类的,在这里面使用了filter: ignore: thottle: startWith: doNext: catch: try: doComplete: map: flattenMap: flatten: 等等的方法，非常好使，其他的可以看看我的几篇笔记"使用RAC-DKHTTPTool实践"、"RACCommand使用注意"

最近的一个个人项目 Poi 就实践了这个架构。UI 结构如下

```
   	    --------------------------------
            |     NavigationConroller0     |
            ---  ----------  ----------  ---
			    |
 	    --------------------------------
            |       TabBarController       |
            ---  ----------  ----------  ---
		|			 |
--------------------------------     --------------------------------   
|     NavigationConroller1     |     |     NavigationConroller2     |
---  ----------  ----------  ---     ---  ----------  ----------  ---
		|                   		    |
--------------------------------     --------------------------------
|       ViewConroller1         |     |       ViewConroller2         |
---  ----------  ----------  --      --------------------------------
```

默认整个应用的跳转用的是NavigationConroller0，这样子做的原因是使用了一个第三方框架，为了可以在TabBarController中滑动切换。
当 pushViewModel 执行的时候，有一个 NavigationStack 会拿到最底部的 NavigationController 进行 push，如果 modal 出一个 navigationController,那么这个 navigationcontroller 将会压入NavigationStack ,然后这个 modal 出来的 viewController 后面的页面跳转就用这个 stack最上层的 NavigationController，dismiss 之后就会就会从栈中移除这个 NavigationController

大概就是长这样子

```
--------------------------------
|     NavigationConroller0     |  
---  ----------  ----------  ---    
		 |	stack + 1	push
--------------------------------    
|       TabBarController       |    
---  ----------  ----------  ---  
		 |		           
--------------------------------   
|     NavigationConroller1     |    
---  ----------  ----------  ---    
		 |      nv0 push     
--------------------------------    
|       ViewConroller1         |    
---  ----------  ----------  ---	  
		 |   	v1 modal
--------------------------------    
|      NavigationConroller2    |    
---  ----------  ----------  ---	  
		 |     stack + 1  push   
--------------------------------    
|      ViewConroller2	       |    
---  ----------  ----------  ---	
		| dismiss
	stack - 1 pop
```

### MVVM WithOut ReacitveCocoa
用 Block 的方式代替 Reactive 的绑定功能。

### 其他
- BugReporter For iOS
	- 和思华一起开发的基于 iOS 的 bug自动反馈系统，一旦发生崩溃事故就会给开发者发送邮件
- 自动部署系统Jenkines
- JSPatch 热修复平台
- UMeng 用户数据统计
- 等等