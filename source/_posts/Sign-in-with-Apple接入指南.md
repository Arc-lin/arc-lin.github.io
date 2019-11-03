title: Sign in with Apple接入指南
author: Arclin
abbrlink: ac0a85bd
tags:
  - iOS
categories:
  - iOS
date: 2019-11-01 13:15:00
---
如果你的应用接入了第三方登陆，那么请同时接入苹果登录。

<!-- more -->

[苹果审核指南的相关内容](https://developer.apple.com/app-store/review/guidelines/#sign-in-with-apple)
[新闻：2020年4月前需要适配好苹果登录](https://developer.apple.com/news/?id=09122019b)

## 简单接入

[苹果登录官方文档](https://developer.apple.com/sign-in-with-apple/)

流程：

用户点击按钮 --- 调起苹果登录 --- 授权成功 --- 获取唯一标识符和其他信息 --- 返回给后端 --- 后端注册/登录 --- 返回token --- 登录成功

### 必要的工作

1. 首先去苹果后台开启`Sign in with apple`选项，然后重新导出`provisionprofile`证书

2. 授权
	```
	ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc] init];
	ASAuthorizationAppleIDRequest *request = [provider createRequest];
	request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];

	NSMutableArray <ASAuthorizationRequest *>* array = [NSMutableArray arrayWithCapacity:2];
	if (request) [array addObject:request];

	NSArray<ASAuthorizationRequest *> *requests = [array copy];
	ASAuthorizationController *authorizationController = [[ASAuthorizationController alloc] initWithAuthorizationRequests:requests];
	authorizationController.delegate = self;
	authorizationController.presentationContextProvider = input;
	[authorizationController performRequests];
	```

3. 回调，遵循回调`ASAuthorizationControllerPresentationContextProviding`

	```
	- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization API_AVAILABLE(ios(13.0))
	{
	if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
		// 用户登录使用ASAuthorizationAppleIDCredential
		ASAuthorizationAppleIDCredential *appleIDCredential = (ASAuthorizationAppleIDCredential *)authorization.credential;
		NSString *user = appleIDCredential.user;
		NSString *namePerfix = appleIDCredential.fullName.namePrefix;
		NSString *givenName = appleIDCredential.fullName.givenName;
		NSString *middleName = appleIDCredential.fullName.middleName;
		NSString *familyName = appleIDCredential.fullName.familyName;
		NSString *nameSuffix = appleIDCredential.fullName.nameSuffix;
		NSString *email = appleIDCredential.email;
		NSString *nickname = appleIDCredential.fullName.nickname;

		if (!nickname || nickname.length == 0) {
			nickname = [NSString stringWithFormat:@"%@%@%@%@%@",namePerfix?:@"",familyName?:@"",givenName?:@"",middleName?:@"",nameSuffix?:@""];
		}
	} else {
		[self.errorSubject sendNext:LMError(@"授权信息有误")];
	}
	}
	- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error API_AVAILABLE(ios(13.0))
	{
	NSString *errorMsg = nil;
	switch (error.code) {
		case ASAuthorizationErrorCanceled:
				errorMsg = @"用户取消了授权请求";
				return;
			case ASAuthorizationErrorFailed:
				errorMsg = @"授权请求失败";
				break;
			case ASAuthorizationErrorInvalidResponse:
				errorMsg = @"授权请求响应无效";
				break;
			case ASAuthorizationErrorNotHandled:
				errorMsg = @"未能处理授权请求";
				break;
			case ASAuthorizationErrorUnknown:
				errorMsg = @"授权请求失败未知原因";
				break;
		}
		[self.errorSubject sendNext:LMError(errorMsg)];
	}
	```

## 其他可选项

### 苹果提供的登录按钮

```
ASAuthorizationAppleIDButton *button = [ASAuthorizationAppleIDButton buttonWithType:ASAuthorizationAppleIDButtonTypeSignIn style:ASAuthorizationAppleIDButtonStyleWhiteOutline];
```

其中

```
typedef NS_ENUM(NSInteger, ASAuthorizationAppleIDButtonType) {
    ASAuthorizationAppleIDButtonTypeSignIn, // 按钮文字显示 ：通过Apple登录
    ASAuthorizationAppleIDButtonTypeContinue, // 按钮文字显示 ：通过Apple继续

    ASAuthorizationAppleIDButtonTypeDefault = // 默认第一个 ASAuthorizationAppleIDButtonTypeSignIn,
}

typedef NS_ENUM(NSInteger, ASAuthorizationAppleIDButtonStyle) {
    ASAuthorizationAppleIDButtonStyleWhite, // 白底黑字
    ASAuthorizationAppleIDButtonStyleWhiteOutline, // 黑字白框
    ASAuthorizationAppleIDButtonStyleBlack, // 黑底白字
}

```

### 授权成功的回调可以来自于其他地方

```
//! 授权成功地回调
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization  API_AVAILABLE(ios(13.0)){
    
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"%@", controller);
    NSLog(@"%@", authorization);
    
    NSLog(@"authorization.credential：%@", authorization.credential);
    
    NSMutableString *mStr = [NSMutableString string];
    mStr = [_appleIDInfoTextView.text mutableCopy];
    
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
        // 用户登录使用ASAuthorizationAppleIDCredential
        ASAuthorizationAppleIDCredential *appleIDCredential = authorization.credential;
        NSString *user = appleIDCredential.user;
        //  最好使用钥匙串的方式保存用户的唯一信息 这里暂且处于测试阶段，用NSUserDefaults
        [[NSUserDefaults standardUserDefaults] setValue:user forKey:QiShareCurrentIdentifier];
        [mStr appendString:user?:@""];
        NSString *familyName = appleIDCredential.fullName.familyName;
        [mStr appendString:familyName?:@""];
        NSString *givenName = appleIDCredential.fullName.givenName;
        [mStr appendString:givenName?:@""];
        NSString *email = appleIDCredential.email;
        [mStr appendString:email?:@""];
        NSLog(@"mStr：%@", mStr);
        [mStr appendString:@"\n"];
        _appleIDInfoTextView.text = mStr;
        
    } else if ([authorization.credential isKindOfClass:[ASPasswordCredential class]]) {
        // 用户登录使用现有的密码凭证
        ASPasswordCredential *passwordCredential = authorization.credential;
        // 密码凭证对象的用户标识 用户的唯一标识
        NSString *user = passwordCredential.user;
        // 密码凭证对象的密码
        NSString *password = passwordCredential.password;
        [mStr appendString:user?:@""];
        [mStr appendString:password?:@""];
        [mStr appendString:@"\n"];
        NSLog(@"mStr：%@", mStr);
        _appleIDInfoTextView.text = mStr;
    } else {
        NSLog(@"授权信息均不符");
        mStr = [@"授权信息均不符" mutableCopy];
        _appleIDInfoTextView.text = mStr;
    }
}
```

### 已经使用Sign In With Apple登录过app的用户

执行已经登录过的场景。如果设备中存在iCloud Keychain 凭证或者AppleID 凭证提示用户直接使用TouchID或FaceID登录即可。

```
- (void)perfomExistingAccountSetupFlows {
    if (@available(iOS 13.0, *)) {
        // A mechanism for generating requests to authenticate users based on their Apple ID.
        // 基于用户的Apple ID授权用户，生成用户授权请求的一种机制
        ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider new];
        // An OpenID authorization request that relies on the user’s Apple ID.
        // 授权请求依赖于用于的AppleID
        ASAuthorizationAppleIDRequest *authAppleIDRequest = [appleIDProvider createRequest];
        // A mechanism for generating requests to perform keychain credential sharing.
        // 为了执行钥匙串凭证分享生成请求的一种机制
        ASAuthorizationPasswordRequest *passwordRequest = [[ASAuthorizationPasswordProvider new] createRequest];
        
        NSMutableArray <ASAuthorizationRequest *>* mArr = [NSMutableArray arrayWithCapacity:2];
        if (authAppleIDRequest) {
            [mArr addObject:authAppleIDRequest];
        }
        if (passwordRequest) {
            [mArr addObject:passwordRequest];
        }
        // ASAuthorizationRequest：A base class for different kinds of authorization requests.
        // ASAuthorizationRequest：对于不同种类授权请求的基类
        NSArray <ASAuthorizationRequest *>* requests = [mArr copy];
        
        // A controller that manages authorization requests created by a provider.
        // 由ASAuthorizationAppleIDProvider创建的授权请求 管理授权请求的控制器
        // Creates a controller from a collection of authorization requests.
        // 从一系列授权请求中创建授权控制器
        ASAuthorizationController *authorizationController = [[ASAuthorizationController alloc] initWithAuthorizationRequests:requests];
        // A delegate that the authorization controller informs about the success or failure of an authorization attempt.
        // 设置授权控制器通知授权请求的成功与失败的代理
        authorizationController.delegate = self;
        // A delegate that provides a display context in which the system can present an authorization interface to the user.
        // 设置提供 展示上下文的代理，在这个上下文中 系统可以展示授权界面给用户
        authorizationController.presentationContextProvider = self;
        // starts the authorization flows named during controller initialization.
        // 在控制器初始化期间启动授权流
        [authorizationController performRequests];
    }
}
```

### 监听授权状态变化

监听授权状态改变，并且做出相应处理。授权状态有：

```
ASAuthorizationAppleIDProviderCredentialRevoked：授权状态失效（用户停止使用AppID 登录App）
ASAuthorizationAppleIDProviderCredentialAuthorized：已授权(已使用AppleID 登录过App）
ASAuthorizationAppleIDProviderCredentialNotFound：授权凭证缺失（可能是使用AppleID 登录过App）
```

```
//! 观察授权状态
- (void)observeAuthticationState {
    
    if (@available(iOS 13.0, *)) {
        // A mechanism for generating requests to authenticate users based on their Apple ID.
        // 基于用户的Apple ID 生成授权用户请求的机制
        ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider new];
        // 注意 存储用户标识信息需要使用钥匙串来存储 这里笔者简单期间 使用NSUserDefaults 做的简单示例
        NSString *userIdentifier = [[NSUserDefaults standardUserDefaults] valueForKey:QiShareCurrentIdentifier];
        
        if (userIdentifier) {
            NSString* __block errorMsg = nil;
            //Returns the credential state for the given user in a completion handler.
            // 在回调中返回用户的授权状态
            [appleIDProvider getCredentialStateForUserID:userIdentifier completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState, NSError * _Nullable error) {
                switch (credentialState) {
                        // 苹果证书的授权状态
                    case ASAuthorizationAppleIDProviderCredentialRevoked:
                        // 苹果授权凭证失效
                        errorMsg = @"苹果授权凭证失效";
                        break;
                    case ASAuthorizationAppleIDProviderCredentialAuthorized:
                        // 苹果授权凭证状态良好
                        errorMsg = @"苹果授权凭证状态良好";
                        break;
                    case ASAuthorizationAppleIDProviderCredentialNotFound:
                        // 未发现苹果授权凭证
                        errorMsg = @"未发现苹果授权凭证";
                        // 可以引导用户重新登录
                        break;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"SignInWithApple授权状态变化情况");
                    NSLog(@"%@", errorMsg);
                });
            }];
            
        }
    }
}
```

使用通知的方式检测是否授权应用支持Sign In With Apple变化情况。如下的代码可以根据自己的业务场景去考虑放置的位置。

```
//! 添加苹果登录的状态通知
- (void)observeAppleSignInState {
    if (@available(iOS 13.0, *)) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(handleSignInWithAppleStateChanged:) name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
    }
}
 
//! 观察SignInWithApple状态改变
- (void)handleSignInWithAppleStateChanged:(id)noti {
    
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"%@", noti);
}
 
- (void)dealloc {
    
    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
    }
}
```

## 重要（Important！）
1. 最好使用苹果提供的按钮 `ASAuthorizationAppleIDButton` （只有黑白两种颜色）
2. 不用他的按钮的话建议使用显眼的颜色 
3. 尽量放在显眼位置（第一位）
4. **不能比其他任何登录按钮要小**
5. 保证登录页面一屏就能看到苹果登录按钮，不能滚动后才能看到
6. 按钮的最小宽高有需求（看[苹果人机交互指南相关文档](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple/overview/)）
7. 如果登录后要绑定手机的话，就在备注里面写好 依据来源 http://www.cac.gov.cn/2016-11/07/c_1119867116_2.htm  指明(截图)第二十四条（苹果一般不会打开网页，建议下载个pdf给他）
8. 如果不好好跟苹果爸爸的规矩来，那么可能会吃到2.1和4.0 (不要问我为什么知道)

(更新至2019/11/01)

|  最小宽度 | 最小高度  | 最小间距|
| ------------ | ------------ | ------------ |
| 140pt (140px @1x, 280px @2x)  |  30pt (30px @1x, 60px @2x) | 1/10 of the button's height）| 

## 参考其他教程

[掘金](https://juejin.im/post/5d8c64d151882509606d6b17)
