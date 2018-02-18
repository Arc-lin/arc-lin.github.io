title: iOS基于Navigation-Base-on-ViewModel的路由搭建——HOOK方式实现
author: Arclin
tags:
  - iOS
categories:
  - iOS
date: 2017-01-05 00:00:00
---
本文主要讲述的是在 iOS 中使用 MVVM 架构开发的情况下，将 ViewModel 作为行为驱动主体，通过 Hook 的方式，设计一个 App 的路由层

<!-- more -->

- 什么是路由

	- 路由在服务端指的是url请求的分层解析，将一个请求分发到对应的应用处理程序。
在移动端指的是将 App 内页面访问、H5与App之间和访问请求和 App之间的访问请求 进行分发的逻辑层。

- 在移动端中路由需要做什么事情

	- 针对网络上的各种说法，这里做一下简要说明：
		- 提供接口供外部访问，这里的”外部”指的可能是App内的一个ViewController，也有可能是其他应用（包括系统应用），也有可能是 H5页面。
分发资源。路由不需要依赖外部的资源的定义，就可以将资源传递给目的地。（‘资源’在这里指的是原生页面、模块、组件等等）
		- 统一的标识符（或者统一格式的标识符）去标识资源，并且可以通过这些标示符去统一访问请求的过程。
		- 解决安全访问的问题，如果是外部的H5、App去访问你的 App,那么就得特别注意这个问题。（本文暂不提及这个问题）

- 在移动端中路由的使用场景

	- 原生界面之间，模块之间与组件之间的交互（例如页面的跳转之类）
	- H5页面与原生界面之间的交互
	- 解除业务依赖
	- 组件化开发

- iOS自带的系统访问方式、统一的连接协议

	- 苹果开发了[URLScheme](https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007899)这种东西，使得 App 能够在沙盒机制的前提下互相调用，定义URL-Scheme的方式如下
> - 协议部分来标示App应用
> - 主机Host部分用于标示业务线或者是应用提供的划分好的服务实体，比方说index、discover是业务条线，api-asycn是对外提供的api，pushService是App内部的推送服务等。
> - 路径部分则可以是细分的页面、组件或者服务的标示
> - 参数定义有一些是必要的，比如说action来标示动作，比方说可以使用get标示获取、insert增加，userToken表示安全的用户令牌，source表示来源，当然像是userToken与source这些都是路由层需要进行解析和验证的，而action则是业务相关的参数，这一点在路由曾设计的时候需要进行详细区分

- 讲完了路由的概念，接下来谈谈 路由设计
	- 我们先抽取最常见的页面跳转来讲，因为我们使用的是 MVVM,那么从理论上来讲，我们就应该让App以 ViewModel为驱动进行运作，而不是用 ViewController,之前说 ViewController 在跳转的时候只需要关心跳转过去的界面是否是一个 UIViewController 的子类，而不需要关心这个 viewController的具体细节,所以考虑用 ViewModel把 目的 ViewController 传递到当前 ViewController，但是ViewModel 严格来讲不能引入任何 UIKit 的任何内容，不然ViewModel级就会失去其可测试性，所以我们通过引入服务总线的概念，维护一个NavigationController 的堆栈（这个思想来自于雷纯锋的博客中的一篇文章[MVVM With ReactiveCocoa](http://blog.leichunfeng.com/blog/2016/02/27/mvvm-with-reactivecocoa/)）具体实现如下

```
//这个是协议声明部分
@protocol MRCNavigationProtocol <NSObject>
- (void)pushViewModel:(MRCViewModel *)viewModel animated:(BOOL)animated;
- (void)popViewModelAnimated:(BOOL)animated;
- (void)popToRootViewModelAnimated:(BOOL)animated;
- (void)presentViewModel:(MRCViewModel *)viewModel animated:(BOOL)animated completion:(VoidBlock)completion;
- (void)dismissViewModelAnimated:(BOOL)animated completion:(VoidBlock)completion;
- (void)resetRootViewModel:(MRCViewModel *)viewModel;
@end
```
  
以下是方法的实现部分，没有写任何方法的实现过程，只是进行了空操作，目的是使用 Hook 思想去捕获操作
  
```
- (void)pushViewModel:(MRCViewModel *)viewModel animated:(BOOL)animated {}
- (void)popViewModelAnimated:(BOOL)animated {}
- (void)popToRootViewModelAnimated:(BOOL)animated {}
- (void)presentViewModel:(MRCViewModel *)viewModel animated:(BOOL)animated completion:(VoidBlock)completion {}
- (void)dismissViewModelAnimated:(BOOL)animated completion:(VoidBlock)completion {}
- (void)resetRootViewModel:(MRCViewModel *)viewModel {}
```

栈顶的 NavigationController 进行 Hook 并执行真正的跳转操作(使用到了 ReactiveCocoa， 因为要捕获的方法太多，这里只列举两条)

```
- (void)registerNavigationHooks {
  	 @weakify(self)
    [[(NSObject *)self.services
        rac_signalForSelector:@selector(pushViewModel:animated:)]
        subscribeNext:^(RACTuple *tuple) {
            @strongify(self)
            UIViewController *viewController = (UIViewController *)[MRCRouter.sharedInstance viewControllerForViewModel:tuple.first];
            [self.navigationControllers.lastObject pushViewController:viewController animated:[tuple.second boolValue]];
        }];
    [[(NSObject *)self.services
        rac_signalForSelector:@selector(popViewModelAnimated:)]
        subscribeNext:^(RACTuple *tuple) {
          @strongify(self)
            [self.navigationControllers.lastObject popViewControllerAnimated:[tuple.first boolValue]];
    }];
}
```

实际在 ViewController 里面调用起来就会是这种感觉

```
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        MRCTrendingViewModel *trendingViewModel = [[MRCTrendingViewModel alloc] initWithServices:self.viewModel.services params:nil];
        [self.viewModel.services pushViewModel:trendingViewModel animated:YES];
    }
}
```

然后看下将ViewModel与 ViewController 关联起来的 路由内的映射(截取部分)

```
- (NSDictionary *)viewModelViewMappings {
   return @{
   	   @"MRCLoginViewModel": @"MRCLoginViewController",
      @"MRCHomepageViewModel": @"MRCHomepageViewController",
      @"MRCRepoDetailViewModel": @"MRCRepoDetailViewController",
      @"MRCWebViewModel": @"MRCWebViewController",
   };
}
```

当然这上面的只是路由的实现方案1，纯粹地将 ViewController 与 ViewModel 关联起来，方案2是 建立一个路由层通过URL 的方式进行路由交互参考[一步步构建iOS路由](http://www.jianshu.com/p/3a902f274a3d)这部分我后面会讲讲我的思考。

