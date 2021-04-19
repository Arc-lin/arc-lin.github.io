---
title: iOS 14 App Clips
author: Arclin
abbrlink: a44df9c3
date: 2020-11-25 10:08:18
tags:
  - iOS
  - feature
categories:
  - iOS
---

本文将主要探讨App Clips开发流程 和 组件化、非组件化两种开发方式下如何复用代码的问题。

<!-- more -->

App Clips是iOS14系统的新特性之一，类似于小程序，用户可以在不下载App的情况下体验到App的部分功能，如网易严选的商品详情功能（[https://m.you.163.com/item/detail?id=1615007#/?_k=yz97vw](https://m.you.163.com/item/detail?id=1615007#/?_k=yz97vw)），该功能适合做一些推广和引流的运营工作，另外苹果也提供的原生的浮窗样式，可以引导用户下载完整版App。

苹果官方文档：[https://developer.apple.com/app-clips/](https://developer.apple.com/app-clips/)

### 目前已知的触发方式

- 二维码
	
	必须使用iOS 14系统相机或者使用控制中心的读取二维码组件来扫码才能触发App Clips。

- NFC Tags
	
	NFC标签感应，比如星巴克桌面内嵌的NFC Tags。

- Safari App Banner
	
	当用户用iOS的Safari浏览器浏览相应的网址后，页面顶部会出现一个横幅，提示用户有App Clips可以用。

- 信息
	
	iOS系统自带的iMessage，当你在iMessage发送一个App Clips链接时，系统会自动把信息显示成一个App Clips的卡片。
    
![](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a13d29c7a17d471dbc551c416ce2ed57~tplv-k3u1fbpfcp-watermark.image)

### 开发前置工作

#### 申请证书

##### 创建App Clips ID

1. 点击新增APP ID
	
<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d62145df226549428f600ace6f1b44cb~tplv-k3u1fbpfcp-zoom-1.image" >

2. 选择App Clip
	
	<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f93a07c34f7249b982f0cbca84bfcafe~tplv-k3u1fbpfcp-zoom-1.image" >
<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1da0c96044db46bb897aab6f71543c8d~tplv-k3u1fbpfcp-zoom-1.image" >


3. 输入一串英文名，用于拼接在主工程的bundle id的后面，生成该clip的bundle id
	<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a2ae0fb422f149d98589f36c80123315~tplv-k3u1fbpfcp-zoom-1.image" >
	
4. 在Description内输入描述（不能使用特殊符号），并且在下方勾选App Clip能力，比如Apple Pay，Sign in with Apple，Push等等，**Associated Domains必须勾选**
<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/33e78440190242efaa8dac9b47004393~tplv-k3u1fbpfcp-zoom-1.image" >
	
5. 最后确认并点击右上方Register即可

##### 创建Profiles

流程跟创建App的Profiles一样，就是选择bundle id的时候改成Clip的bundle id 即可，同样有Development、AdHoc、Distribution三种类型

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/68bfe6ee218047b7a3232058dcc2e006~tplv-k3u1fbpfcp-zoom-1.image" >

##### 其他配置

如果需要其他NFC、地点等等的一些方式触发App Clip配置的话，参考这个苹果的文档[https://help.apple.com/app-store-connect/#/dev5b665db74](https://help.apple.com/app-store-connect/#/dev5b665db74)

#### Apple Store Connect 配置图片和标题，描述

1. 需要一张1800 * 1200 的图片，用于显示在Clip的卡片上
2. 副标题用于显示在卡片标题下的小字，如图所示<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/4b3e18f56f6d49219fc46f77dab1cef2~tplv-k3u1fbpfcp-zoom-1.image" width=30%>
3. 操作包括“打开”“查看”“开始游戏”，体现在卡片右边的蓝色按钮内的文案，根据你的产品类型进行选择就好

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0c14c35967084886bc3f4fce6e985fcb~tplv-k3u1fbpfcp-zoom-1.image" >


#### 配置apple-app-site-association.json

假设你的开发者账号的Team Id是`A123`，Clips的bundle id是`com.abc.def.clips`，主工程的bundle id 是`com.abc.def`，则配置如下

```
{
    "appclips":{
        "apps":["A123.com.abc.def.clips"]
    },
    "applinks":{
        "apps":[
        ],
        "details":{
            "A123.com.abc.def":{
                "paths":[
                    "*" // 这里的Path根据实际情况配置即可
                ]
            }
        }
    },
    "webcredentials":{
        "apps":[
            "A123.com.abc.def",
        ]
    },
    "activitycontinuation":{
        "apps":[
            "A123.com.abc.def",
        ]
    }
}
```

配置完成后部署到你自己域名的根目录下，配置方法网上很多教程，这里贴上[苹果官方文档](https://developer.apple.com/documentation/safariservices/supporting_associated_domains?language=objc)

如果配置错了，那么上传包到苹果后台之后，就会显示无效域名
![](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/05ddb4d106a349d28c1504762697a9eb~tplv-k3u1fbpfcp-zoom-1.image)

如果是json配置错误，那么配置正确后不用重新传包，等待苹果那边刷新缓存就好。

App Clip支持最多在三个域名的网页显示入口，到后面的工程配置那里会说明。

#### 前端页面添加meta标签

如果要在H5页面显示Clips入口，加上一段meta标签即可

如果你的应用市场App id是 `123456`, Clips的bundle id 是 `com.abc.clips` 则应该配置

```
<meta name="apple-itunes-app" content="app-id=123456,app-clip-bundle-id=com.abc.clips">
```

### 开发工作

#### 新建App Clip Target

这里以OC工程为例

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/9edc6108c0b64885b708ef5c9de8e1d0~tplv-k3u1fbpfcp-zoom-1.image" >
<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/fa5c9c1032174d77a4db0518029b78dd~tplv-k3u1fbpfcp-zoom-1.image" >

#### 配置证书和Associated Domains

用刚才生成的证书去配置一下即可

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5fbccb4eee1445ca9b680200358535e0~tplv-k3u1fbpfcp-zoom-1.image" >

添加Associated Domains，目的是打开对应域名网页后，页面上方能够出现Clip的入口。

**这里可以添加多个域名，注意每个域名都需要配置apple-app-site-association！！！**

**主工程的Target和Clip的Target都需要配置！！！**

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a5125ca96f15433b8205294e48906e13~tplv-k3u1fbpfcp-zoom-1.image" >

#### 编写代码

创建完之后就会生成一个文件夹，里面就是我们熟悉的AppDelegate、SecneDelegate、Main.storyboard、Info.plist等文件，如果你不使用Storyboard进行界面搭建，那么也是跟之前的开发模式一样，删除info.plist内Application Scene Manifest，修改General-Deployment info - Main interface 为空，修改AppDelegate.m，在里面创建根控制器。

之后的操作就跟普通开发一样了，调试的话可以直接在Xcode上左上角选择Clip的target，然后就可以跑起来了。

另外，AppIcon是需要独立配置的，同样也是在Clip项目工程文件夹内Assets.xcassets。

##### 非组件化开发模式

一般情况下我们是需要复用代码的，将代码内某些模块功能进行复用，然后直接用在Clip，这时候我们只需要在右侧Target Membership勾选新建的Clip Target即可。

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0c2847eb910740229f410d0aa29f7bb5~tplv-k3u1fbpfcp-zoom-1.image" width=30%>

同样的 相关的依赖到的文件也需要勾选Clip Target

##### 组件化开发模式 和 Podfile的配置

如果是在组件化开发模式下，那么就需要配置Podfile

在Podfile 底部新增代码

```
source 'https://github.com/CocoaPods/Specs.git'
# 你的私有pod仓库
source 'https://git.xxx.com/yourprivatepodspec/Podspec.git'

target 'YourApp’ do
    platform :ios, '10.3'
    pod "AFNetworking"
    pod "SDWebImage"
    # 等等
end

target 'YourApp_Clips' do
    platform :ios, '10.3'
    pod 'ComponentA',           :path=> '../ComponentA'
    pod "ComponentB",           :path=>"../ComponentB"
    pod "AFNetworking"
    pod "SDWebImage"
    # 等等
end

```

但是这样子相同的第三方pod会写两遍，所以我们可以优化成

```
source 'https://github.com/CocoaPods/Specs.git'
# 你的私有pod仓库
source 'https://git.xxx.com/yourprivatepodspec/Podspec.git'

def common_pods
    pod "AFNetworking"
    pod "SDWebImage"
end

target 'YourApp’ do
    platform :ios, '10.3'
    common_pods
end

target 'YourApp_Clips' do
    platform :ios, '14.0'
    pod 'ComponentA',           :path=> '../ComponentA'
    pod "ComponentB",           :path=>"../ComponentB"
    common_pods
end

```

##### 抽离模块时不同环境的代码复用问题

假如说A功能需要抽离出来放到Clip，但是A模块里面有需求是会跳转到B模块的，但是我并不希望Clip引入B模块，希望他能在这个地方提示用户下载完整App，那应该怎么做呢？

首先第一个事情，苹果提供了一个Api可以引导弹窗引导用户下载APP

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3fec69fde9e64618819b1b526034d23b~tplv-k3u1fbpfcp-zoom-1.image" width=40%>

```
UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes.allObjects firstObject];
SKOverlayAppConfiguration *config = [[SKOverlayAppConfiguration alloc] initWithAppIdentifier:@"你的AppID" position:SKOverlayPositionBottomRaised];
SKOverlay *overlay = [[SKOverlay alloc] initWithConfiguration:config];
overlay.delegate = self; // 添加代理后可以监听弹窗的弹出和消失，可以在代理内添加埋点。
[overlay presentInScene:scene];

// 主动让弹窗消失
// [SKOverlay dismissOverlayInScene:scene];
```

第二. 如何在模块内划分环境，区分是主App还是Clip

方法一：设计一个单例，添加一个枚举属性，分别在`主工程`的AppDelegate和`Clip`的AppDelegate内给单例的属性赋值，标记当前环境。然后在业务代码中获取单例的环境属性后进行判断。

方法二：有时候我们在Clip复用的模块代码内不需要import某些头文件，因为我们不需要这个功能，这时候单例的方法就不管用了，我们需要通过宏去判断。

如果代码不在pod组件内的话，只需要在Clip Target的`Build Settings` - `Preprocessor Macros`添加`APP_CLIPS`宏即可。

<img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/7708c16f9c4247a9ab9ec393d01420b1~tplv-k3u1fbpfcp-zoom-1.image" >

如果是组件化的开发模式，代码在pod内部，那么就稍微有点麻烦，需要在对应podspec新增一个subspec，专门提供给clip使用，然后配置上宏定义

`ComponentA.podspec`

```

s.subspec "App" do |ss|
    ss.source_files = "xxxxxx"
end

s.subspec "AppClip" do |ss|
    ss.source_files = "xxxxxx"
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'APP_CLIPS=1'}
end
```

> 这里为什么要弄多一个App的subspec，因为如果主工程直接`pod ComponentA`的话，所有的subspec都会被引入，所以这里为了区分开，就加多了一个专门给主工程用的subspec

`Podfile`

```
def common_pods
    pod "AFNetworking"
    pod "SDWebImage"
end

target 'YourApp’ do
    platform :ios, '10.3'
    common_pods
    pod 'ComponentA/App',           :path=> '../ComponentA'
end

target 'YourApp_Clips' do
    platform :ios, '14.0'
    pod 'ComponentA/AppClip',   :path=> '../ComponentA'
    pod "ComponentB",           :path=>"../ComponentB"
    common_pods
end
```

通过以上方法，就可以用如下方式进行宏判断，区分当前环境

```
#ifdef APP_CLIPS

#else

#endif
```

### 测试工作

#### 开发调试

- 可以选择Clip Target直接使用Xcode编译运行

- 可以使用真机扫描二维码，调起Clip卡片，但是前提是Clip要先在真机跑一遍。
	
	1. 手机点击`设置-开发者-Local Experiences-Register Local Experience`
	2. 输入域名、Clip的bundle id、标题、子标题，选择按钮标题、选择Clip弹出的卡片上的图片，然后点击存储即可。
	3. 将刚才输入的域名，去草料二维码等二维码生成网站生成一个二维码，然后手机相机扫描即可弹出卡片样式。
	4. 具体内容可以参考[官方文档](https://developer.apple.com/documentation/app_clips/testing_your_app_clip_s_launch_experience?language=objc)
	

#### 外部测试

1. 可以通过Archive打Release环境的包（Debug状态下没有选择导出Clip ipa的选项，不知道是哪里配置问题，如果有知道的小伙伴可以评论区分享一下），然后单独导出Clip的ipa，上传到蒲公英或者Fir等分发平台，测试同事就可以下载安装测试了。
2. 如果已经传到了TestFlight，那么也可以在TestFlight上直接点击打开小程序进行测试。

### 苹果官方提及的产品要求

原文：[https://developer.apple.com/design/human-interface-guidelines/app-clips/overview/](https://developer.apple.com/design/human-interface-guidelines/app-clips/overview/)

划重点：

1. 请勿仅将App Clip用作营销用途，不能显示广告。
 
2. 避免登录，避免不了的话尽可能使用Apple id登录

3. Clips启动后只有在8小时内才能接收推送

### Q&A

1. 苹果文档说的App Clips 10M限制指的是哪个文件的10M
	
	经过测试后发现，应该是Release环境下Archive后，导出的Clips的ipa的大小，如果有误欢迎评论区指正。
	
2. Clips可以有登录功能吗？

	可以，但是苹果希望用户能不登录就使用App，如果要登录也首选Sign in with Apple登录的方式(iOS13特性)，但是我们可以学网易严选那样子苹果ID登录之后再弹出手机验证码绑定功能。
	
3. 可以有内购吗？

	可以。
	
4. 用户使用完Clips后，如果想再次进入，入口在哪儿？

	假如是网页打开的Clips，那么离开网页后，在桌面的"资源库"里可以找到这个Clips并重新打开。如果找不到就搜索资源库，总能搜到的。