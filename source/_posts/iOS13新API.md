title: iOS 13新API
author: Arclin
abbrlink: f356f3c1
tags:
  - iOS
  - feature
categories:
  - iOS
date: 2019-10-24 13:18:00
---

可能会用到的iOS13新Api

<!-- more -->

## 接口类

### 截图转PDF

safari可以长截图了
<img width=20% src="https://i.loli.net/2019/10/24/iHxWAqL63E2ZfMY.jpg">

然后我们可以把`UIScrollView`的截图转成PDF

[文档](https://developer.apple.com/documentation/uikit/uiscreenshotservicedelegate)

### 双指滑动手势

![](https://i.loli.net/2019/10/24/FbSEV8WCXcQRrf9.gif)

```
/// 是否允许多指选中
optional func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAtIndexPath indexPath: IndexPath) -> Bool

///多指选中开始，这里可以做一些UI修改，比如修改导航栏上按钮的文本
optional func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAtIndexPath indexPath: IndexPath) 
```

### 深色模式

见[文章](https://www.jianshu.com/p/176537b0d9dd)

## Framework类

### Multiple UI Instances

可以支持一个界面同时展示多个控制器（不是父子控制器那种）
在iPad上可以使用

![](https://docs-assets.developer.apple.com/published/8ce996907a/fc0975ae-c186-438c-abdd-5280f650c377.png)

主要类`UIScene`

[文档](https://developer.apple.com/documentation/uikit/app_and_environment)


### BackgroundTasks

好消息~ 现在维持后台不被杀可以直接用这个API了，以前的会用后台获取定位和播放静音音乐的方式，但是现在只要注册后台就可以了，但是还是只有短期，长时间的话可能会要求充电状态或者持续的网络状态。

[文档](https://developer.apple.com/documentation/backgroundtasks/)

### Camera Capture

现在可以同时使用前后摄像头，可以进行分割遮罩，可以识别出头发，皮肤，牙齿

[文档1](https://developer.apple.com/documentation/avfoundation/avcapturemulticamsession/)

[文档2](https://developer.apple.com/documentation/avfoundation/avsemanticsegmentationmatte/)

### Combine

官方版RxSwift，主要是配合SwiftUI使用

[文档](https://developer.apple.com/documentation/combine/)

### Core Haptics

可以在UI交互的时候给点小触觉反馈，比如打开关闭UISwitch的时候小震动一下，或者播放点声音之类的

[文档](https://developer.apple.com/documentation/corehaptics/)

### Apple CryptoKit

好消息，苹果自带HMAC、SHA、AES、NIST加密算法啦

[文档](https://developer.apple.com/documentation/cryptokit/)

### VisionKit

好消息，苹果自带图片转文字功能啦

[文档](https://developer.apple.com/documentation/visionkit/)

### MetricKit

用来收集用户设备信息的，主要是使用App的过程中的耗电，CPU等等性能指标，可以依据这些优化你的App

[文档](https://developer.apple.com/documentation/metrickit/)

### PencilKit

iPad上跟Apple Pencil交互的API

[文档](https://developer.apple.com/documentation/pencilkit/)

### Vision

图像识别相关framework
iOS11的功能：面部和面部界标检测，条形码识别，图像配准以及一般特征跟踪。

iOS13的新功能：
1. 对图像进行显著性分析。
2. 在图像中检测人类和动物。
3. 对图像进行分类和搜索。
4. 分析图像与特征打印的相似性。
5. 对文档执行文本识别。

[文档](https://developer.apple.com/documentation/vision/)

### Sign in with Apple

苹果登录

[文档](https://developer.apple.com/sign-in-with-apple/get-started/)

### SF Symbols

可以用来显示矢量图

[文档](https://developer.apple.com/documentation/uikit/uiimage/configuring_and_displaying_symbol_images_in_your_ui/)

### Bring Your iPad App to Mac

直接把iPad App 迁移到 Mac，不过还是要做适配的，下面文档会有一些适配规则，以兼容两个端

[参考](https://developer.apple.com/design/human-interface-guidelines/ios/overview/mac-catalyst/)

[文档1](https://developer.apple.com/documentation/xcode/creating_a_mac_version_of_your_ipad_app)

[文档2](https://developer.apple.com/documentation/uikit/mac_catalyst/optimizing_your_ipad_app_for_mac)

### ARKit 3

应该大家都知道ARKit，这次主要是多了些新特性，包括动态捕捉动作，同时捕捉多个面部，同时开启前后摄像头等。

[文档](https://developer.apple.com/documentation/arkit/)

### RealityKit

3D模型搭建、展示用

[文档](https://developer.apple.com/documentation/realitykit/)

### Core ML 3

升级版机器学习套件

[文档](https://developer.apple.com/documentation/coreml/)

