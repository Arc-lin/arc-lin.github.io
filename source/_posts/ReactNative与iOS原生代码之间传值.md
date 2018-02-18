title: ReactNative与iOS原生代码之间传值
author: Arclin
tags:
  - React Native
categories:
  - React Native
date: 2017-02-26 00:00:00
---
本文包含两部分:

- 原生传值到RN
- RN传值到原生

<!-- more -->

### 原生传值到RN

加载`RCTRootView`的时候在`initialProperties`内传值

```
NSDictionary *params = @{@"image":@"https://dn-coding-net-production-static.qbox.me/ac823dee-6303-4745-9216-711ab4d83753.png?imageMogr2/auto-orient/format/png/crop/!651x651a0a0"};

RCTRootView * rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                         moduleName:@"Test"
                                                  initialProperties:params
                                                      launchOptions:nil];
```

发送的值可以在`this.props`内得到,像上面的例子就是`this.props.image`

```
<View style={[styles.tabContent,{backgroundColor:color}]}>
            <Text style={styles.tabText}>{pageText}</Text>
            <Text style={styles.tabText}>第{num}次重复渲染{pageText}</Text>
            <Text stype={styles.tabText}>{this._renderImage(this.props.image)}</Text>
</View>
```

### RN传值到原生

原生代码实现协议`RCTBridgeModule`,如下

```
#import <React/RCTBridgeModule.h>

@interface ReactViewController : UIViewController<RCTBridgeModule>

@end
```

添加方法,下面代码中的`testPassValue`给这个Controller声明一个`testPassValue`方法,在RN中可以调用这个方法

```
// 导出模块
RCT_EXPORT_MODULE(); // 此处不添加参数默认为这个类的类名

RCT_EXPORT_METHOD(testPassValue:(NSString *)value)
{
    NSLog(@"%@",value);
}
```

RN中调用原生的`testPassValue`方法

```
import {
    NativeModules,
} from 'react-native';

var ReactViewController = NativeModules.ReactViewController;

//方法调用
ReactViewController.testPassValue('I pass this value to controller');
```

注意: RN调用原生方法的时候,如果涉及到UI操作,记得使用`dispatch_async(dispatch_get_main_queue(), ^{});`拉回主线程,另外在被调用方法中调用的self的地址和真正的这个controller的地址是不一样的,所以在进入RN的controller的时候要把self保存起来,比如另外创建一个单例之类的,然后RN回调原生的时候取出控制器对象才可使用.

类似下面这个例子是pop掉RN所在的控制器

```
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 保存到单例
    [RNSingleton sharedInstance].rnvc = self;
    
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    NSString * strUrl = @"http://localhost:8081/index.ios.bundle?platform=ios&dev=true";
    NSURL * jsCodeLocation = [NSURL URLWithString:strUrl];
    
    RCTRootView * rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                         moduleName:@"Test"
                                                  initialProperties:self.params
                                                      launchOptions:nil];
    self.view = rootView;
}

// 导出模块
RCT_EXPORT_MODULE(); // 此处不添加参数默认为这个类的类名

RCT_EXPORT_METHOD(testPassValue:(NSString *)value)
{
    NSLog(@"%@",value);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RNSingleton sharedInstance].rnvc.navigationController popViewControllerAnimated:YES];
    });
}

```