abbrlink: '0'
tags:
  - iOS
categories:
  - iOS
author: Arclin
title: iOS12 新玩具ShortCut(捷径)使用
date: 2018-09-28 13:05:00
---

### 介绍

升级iOS12之后可以在`设置-Siri`与搜索 中发现一个 `捷径` 功能, 所谓ShortCut就是其英文翻译
其作用就是让用户自定义一个一句话或者短语, 然后可以触发app做一系列动作

<!-- more -->

### 接入

ShortCut分为两种, 一种是在手机的`Spotlight`上搜索某个关键字的时候可以搜索到你的app, 这个关键字就是ShortCut的一种(文字输入), 你需要使用`NSUserActivity`去实现这个功能
> 依赖 `CoreSpotlight` `CoreServices`

另外一种叫做 `Intent`(语音输入), 需要添加一个IntentExtension和IntentExtensionUI, 然后在主Target添加一个intentdefinition文件, 详细的配置大家可以参考
[文章1](https://juejin.im/post/5b2077d8f265da6e45549c68)
[文章2](http://www.cnblogs.com/czjie2010/p/czjie.html)

> 依赖`Intents` `IntentsUI`


### 最简单的配置操作步骤

1. 项目的`Capabilities`打开`Siri`
2. 授权
	```
	if (@available(iOS 10.0, *)) {
		[INPreferences requestSiriAuthorization:^(INSiriAuthorizationStatus status) {
			switch (status) {
				case INSiriAuthorizationStatusNotDetermined:
					NSLog(@"用户尚未对该应用程序作出选择。");
					break;
				case INSiriAuthorizationStatusRestricted:
					NSLog(@"此应用程序无权使用Siri服务");
					break;
				case INSiriAuthorizationStatusDenied:
					NSLog(@"用户已明确拒绝此应用程序的授权");
					break;
				case INSiriAuthorizationStatusAuthorized:
					NSLog(@"用户可以使用此应用程序的授权");
					break;
				default:
					break;
			}
		}];
	}
	```
	- 新建一个`intentdefinition`，比如`A.intentdefinition`
	- 新建一个`Target`,`Intent Extension`有需要的话把`Intent UI Extension`也加上，`General`中配置相关证书
	- 进入`A.intentdefinition`，界面左下角`+`号点一下，点击`new intent`
	- 界面右边`Target Membership`，把`步骤2`中新增的`Target`给勾上
	-  界面中间`Title`填写需要展示的标题，`Descripion` 写描述
	- Build一下，系统自动生成头文件，头文件名字在界面右测的导航页的第三个按钮的`Custom Class`里
	- 找个控制器，导入`步骤8`生成的头文件，添加个按钮，比如

	```
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"捷径" style:UIBarButtonItemStylePlain target:self action:@selector(siri:)];
	```

3. 点击按钮召唤添加Shortcut的控制器

	```
	- (void)siri:(UIBarButtonItem *)item {
	    if (@available(iOS 12.0, *)) {
	    	 // 这个类名具体看你生成了叫什么名字的头文件
	        ZeRiIntent *intent = [[ZeRiIntent alloc] init];
	        intent.suggestedInvocationPhrase = @"打开xxx"; // 引导用户说的语句
	        INShortcut *shortCur = [[INShortcut alloc] initWithIntent:intent];
	        INUIAddVoiceShortcutViewController *vc = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCur];
	        vc.delegate = self;
	        [self presentViewController:vc animated:YES completion:nil];
	    } else {
	        // Fallback on earlier versions
	    }
	}
	```

4. 同个地方实现代理方法

	```
	#pragma mark - INUIAddVoiceShortcutViewControllerDelegate
	- (void)addVoiceShortcutViewControllerDidCancel:(INUIAddVoiceShortcutViewController *)controller  API_AVAILABLE(ios(12.0)){
		[controller dismissViewControllerAnimated:YES completion:nil];
	}
	- (void)addVoiceShortcutViewController:(INUIAddVoiceShortcutViewController *)controller didFinishWithVoiceShortcut:(INVoiceShortcut *)voiceShortcut error:(NSError *)error  API_AVAILABLE(ios(12.0)){
		[controller dismissViewControllerAnimated:YES completion:nil];
	}
	```

5. 进入`Intent` target中的`IntentHandler`类，导入`步骤8`生成的头文件，要是头文件找不到，在这个target的`info.plist`中`NSExtension`下的`IntentsSupported`下添加一个名为那个头文件的值，主target的`info.plist`的`NSUserActivityTypes`下也加一个一样的

6. `IntentHandler.m`遵循协议`XXXIntentHandling`（具体协议名看你的类名），实现两个方法

	```
		// 用户说了那句话之后要Siri做什么事情
	- (void)handleZeRiIntent:(ZeRiIntent *)intent completion:(void (^)(ZeRiIntentResponse * _Nonnull))completion {
		completion([[ZeRiIntentResponse alloc] initWithCode:ZeRiIntentResponseCodeContinueInApp userActivity:nil]);
	}
	  // 用户确认了之后要Siri做什么事情
	- (void)confirmZeRiIntent:(ZeRiIntent *)intent completion:(void (^)(ZeRiIntentResponse * _Nonnull))completion {
		completion([[ZeRiIntentResponse alloc] initWithCode:ZeRiIntentResponseCodeContinueInApp userActivity:nil]);
	}
	```

	  `ZeRiIntentResponseCodeContinueInApp`只是枚举中其中一个值，使用不同的值会有不同     效果，自己探索一下，这里的值指的是打开app(具体方法名看协议)

7. 进入`AppDelegate`，实现方法如下，根据`Intent`类名判断用户想要的操作

	```
	- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
	if ([userActivity.activityType isEqualToString:@"XXXIntent"]) {
	}
    return YES;
}
```
8. 结束