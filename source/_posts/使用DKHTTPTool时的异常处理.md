title: 使用DKHTTPTool时的异常处理
author: Arclin
tags:
  - iOS
categories:
  - iOS
date: 2017-01-05 00:00:00
---
本文主要讲述的是在使用 DKHTTPTool 时，返回异常数据时的处理

<!-- more -->

如果是普通调用情况的话,也即是调用这个方法
```
- (NSInteger)requestForMethod:(NSString *)method
                cacheStragety:(DKCacheStrategy)strategy
                          url:(NSString *)URLString
                       header:(NSDictionary *)header
                       params:(NSDictionary *)params
                       filter:(DKHTTPRequestFilterBlock)filterBlock
                 verifyParams:(DKHTTPParamsVarifyBlock)verifyBlock
                responseBlock:(DKHTTPResponseBlock)block;
```

那么捕获异常只需要拿到回调中的DKResponse中的error属性即可

如果是用链式调用的方法`RACSignal`回调的话，那么就得看情况了，如果你是用 `RACCommand` 去启用网络请求的话，那么记得 `RACCommand` 是用 `errors` 属性去存储错误信号的，如果你有多个 `RACCommand` 对象建议你在 `ViewModel` 里创建一个 `RACSubject` 去统一处理错误信号，然后你可以这么写`[[RACSignal merge:@[_addParamCommand.errors,_removeParamCommand.errors,_sendCommand.errors]] subscribe:self.errors];`

如果你直接取得网络请求回调中的`RACSignal`对象的话 ，直接`subscribeError:`就可以得到`NSError`对象
关于提示错误信息，从交互的角度上来讲，我觉得友好程度

`TopBarMessage(TWMessageBarManager) > HUD > ALERT`

当然实际运用的时候还是得看情况，不同情况使用不同的提示方式