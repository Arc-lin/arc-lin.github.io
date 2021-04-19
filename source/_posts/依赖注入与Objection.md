---
title: 依赖注入与Objection
tags:
  - iOS
  - 架构
categories:
  - iOS
abbrlink: 6ae5f77f
date: 2020-05-01 10:44:01
---

本文会说明iOS内依赖注入的概念和依赖注入框架Objection的一般使用

<!--more-->

#### 依赖注入

首先先说明什么叫做依赖注入

比如AController跳转到BController,那么这时候BController就需要在AController内部进行实例化，如下

```
@implementation AController : UIViewController

...

- (void)jump 
{
	BController *bController = [[BController alloc] init];
    [self.navigationController pushViewController:bController animated:YES];
}

@end

```

这么做的话，当AController被封装成组件之后，BController的配置将会被限制，外部无法改变BController任何细节，所以我们 ** 稍 加 改 进 **

```
@implementation AController : UIViewController

...

- (instancetype)initWithCreateBlock:(UIViewController *(^)(void))createBViewControllerBlock {
	....
	self.createBViewControllerBlock = createBViewControllerBlock;
	...
}

- (void)jump 
{
	UIViewController *bController = self.createBViewControllerBlock();
    [self.navigationController pushViewController:bController animated:YES];
}

@end

```

```
[[AController alloc] initWithCreateBlock:UIViewController* ^{
	BController *bController = [[BController alloc] initWithTitle:@"xxx"];
	return bController;
}];
```

将BController的创建通过Block暴露出来，AController内部不关心BController是如何被创建的，那么AController对BController的依赖将通过外部的Block进行注入。

这，就是依赖注入。


当然这是最简单的依赖注入，无法满足我们复杂的需求，所以有时候我们需要使用第三方框架，如`Objection`和`Typhoon`

#### Objection

接下来说明一下Objection的使用

Objection 是一个依赖注入框架，能够在你获取一个类的实例的时候，这个类内部的属性也同时会被实例化。举个例子：

```
//Car.h

@class Engine,Break;

@interface Car : NSObject

@property (nonatomic, strong) Engine *engine;

@property (nonatomic, strong) Break *breaks;

@end

```

```
//Car.m

#import <Objection/Objection.h>

@implementation Car
objection_requires(@"engine", @"breaks")

@end

```

创建一个默认注射器

```
JSObjectionInjector *injector = [JSObjection createInjector];
[JSObjection setDefaultInjector:injector];
```

实例化Car对象
```
Car *car = [[JSObjection defaultInjector] getObject:[Car class]];
```

这时候所依赖的`engine`对象和`breaks`对象都会通过`init`方法实例化

最后打印属性

```
car <Car: 0x6000006d8480> engine <Engine: 0x6000004841b0> breaks <Break: 0x6000004841e0>
```

假如说Car对象不能通过`init`或者`initWithXXX`等自定义构造方法去实例化，那么我们需要指定方法，让注射器在指定的方法构建依赖

```
@implementation Car
objection_requires(@"engine", @"breaks")
- (void)awakeFromNib {
  [[JSObjection defaultInjector] injectDependencies:self];
}
@end
```

当Car被注射器初始化完成之后，会调用`- awakeFromObjection`方法，这里可以额外赋一些值

```
- (void)awakeFromObjection 
{
	self.test = @"111";
}
```

上面的说的都是直接init出来的对象，但是更多情况下我们需要指定构造方法

```
@implementation Car
objection_initializer_sel(@selector(initWithObject:)) // 该宏只需且只能出现一次

- (instancetype)initWithObject:(id)object
{
    if (self = [super init]) {
        self.test = object;
    }
    return self;
}
@end
```

取出的时候加上`argumentList:`参数即可
```
 Car *car = [[JSObjection defaultInjector] getObject:[Car class] argumentList:@[@"aaaa"]];
```

或者不想写`objection_initializer_sel()`宏的话
可以直接在取的方法那里改动一下变成

```
Car *car = [[JSObjection defaultInjector] getObject:[Car class] initializer:@selector(initWithObject:) argumentList:@[@"aaaa"]];
```

效果也是一样的

##### 对象工厂

在Car中添加一个对象工厂属性

```
@property(nonatomic, strong) JSObjectFactory *objectFactory;
```

然后标记注入里面加多一个`objectFactory`

```
objection_requires(@"engine", @"breaks",@"objectFactory")
```

然后你就可以通过

```
id obj = [self.objectFactory getObject:[Engine class]];
```

获取到对应的对象

##### 模块

你可以创建一个继承自`JSObjectionModule`的模块，在里面绑定相对应的`事物`，便可直接取到对应的值

例如  一个协议和一个模块类，对象绑定了类名和这个类所遵循的协议

```

@protocol APIService <NSObject>

- (void)api:(NSString *)params;

@end


@interface ModuleA : JSObjectionModule

@end

@implementation ModuleA

- (void)configure
{
    [self bindClass:[MyAPIService class] toProtocol:@protocol(APIService)];
}

@end

```

这时候注射器初始化方式改为

```
JSObjectionInjector *injectorA = [JSObjection createInjector:ModuleA.new]; [JSObjection setDefaultInjector:injectorA];
```

你就可以直接拿到对应遵循了这个协议的对象而不用通过ModuleA的实例对象

```
MyAPIService *delegate = [injectorA getObject:@protocol(APIService)];
```

**注意由于绑定的时候是用了bindClass:方法，所以每次取出都是不同的对象**

除了绑定对象类名和协议外，还可以绑定一个对象和绑定一个类名

```
@implementation ModuleA

- (void)configure
{
    [self bind:对象实例 toClass:[UIApplication class]];
    [self bind:对象实例 toProtocol:@protocol(UIApplicationDelegate)];
}

@end

```

**注意由于绑定的时候是用了bind:方法，所以每次取出都是相同的对象 **

当对象被创建的时候，可以通过bindBlock:方法进行干涉

```
@implementation ModuleA

- (void)configure
{
    [self bindClass:[MyAPIService class] toProtocol:@protocol(APIService)];
    [self bindBlock:^id(JSObjectionInjector *context) {
        MyAPIService *service = [[MyAPIService alloc] init];
        service.buildByMySelf = YES;
        return service;
    } toClass:[MyAPIService class]];
}

@end
```

上面这个例子表示MyAPIService被实例化后都会带上`buildByMySelf = YES`

但是用这种方法的话，假如用注射器取出对象的时候带上了参数，那我们就没办法拿到参数了，所以我们需要用到`ObjectionProvider`协议

```
@interface ProviderA : JSObjectionModule<JSObjectionProvider>

@end

@implementation ProviderA
- (id)provide:(JSObjectionInjector *)context arguments:(NSArray *)arguments
{
    MyAPIService *service = [[MyAPIService alloc] init];
    service.buildByProvider = YES;
    service.arguments = arguments;
    return service;
}

- (void)configure
{
	[self bindProvider:[ModuleA new] toClass:MyAPIService.class];
}

@end
```

这样子就能手动构建对象并且得到参数了

##### 作用域

上面提及的`bindClass:`、`bindBlock:`、`bindProvider:`这些方法，都有一个拓展参数`inScope:(JSObjectionScope)scope;`

比如：

```
[self bindClass:[MyAPIService class] toProtocol:@protocol(APIService) inScope:JSObjectionScopeSingleton named:@""];

[self bindBlock:^id(JSObjectionInjector *context) {
	MyAPIService *service = [[MyAPIService alloc] init];
	service.buildByMySelf = YES;
	return service;
} toClass:[MyAPIService class] inScope:JSObjectionScopeSingleton named:@""];

[self bindProvider:[ModuleA new] toClass:MyAPIService.class inScope:JSObjectionScopeSingleton];
```

`JSObjectionScopeSingleton`意味着注射器取出来的都是同个对象，
`JSObjectionScopeNormal`意味着注射器取出来的是不同对象。

##### 总结

Objection 帮助你实现** 依赖注入 **，你只需要完成两件事情，配置依赖关系和获取依赖对象。配置依赖关系时，你可以使用几个常用的宏来快速的完成依赖关系的配置，另外你还可以使用模块的概念来完成更多的绑定操作，它允许你将某些类或某些协议接口绑定到某个或某一类的对象上，在配置完成后，你就可以使用关键的 injector 注入器获取到你所需要的对象。

Objection 像是一种字典容器，通过多种形式将 value 和 key 关联起来，在完成配置之后，你只需要关注你通过何种 key 获取到需要的 value 即可。Objection 最主要的功能之一就是面向接口编程的实现，在上面的示例中也进行了演示，面向接口编程是一种非常重要的编程思想。
