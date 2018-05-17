---
title: ReactiveCocoa解决异步串行任务执行中多层嵌套/递归的问题
author: Arclin
tags:
  - iOS
  - Reactive Cocoa
categories:
  - iOS
abbrlink: 5f5664e4
date: 2017-03-20 00:00:00
---

因为在项目中遇到了一个异步的串行任务执行的问题,通过ReactiveCocoa解决了,所以在这里记录一下

<!-- more -->

首先是一个第三方的API,这个API会进行一个网络请求,并且使用block进行回调.批量执行并且是串行执行.
如果不用RAC,我们可以通过递归,当任务一结束的时候递归执行任务二,以达到串行的效果,然后判断索引达到最后的时候跳出递归,但这种操作如果一多容易造成栈溢出,所以用RAC的优化如下.

首先使用一个`RACSignal`包装API,如下

```
- (RACSignal *)deleteWithId:(NSString *)identifier
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        GTLQueryDrive *query = [GTLQueryDrive queryForFilesDeleteWithFileId:identifier];
        [self.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if(!error) {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }else {
                [subscriber sendError:error]; // 失败的时候抛出异常
            }
        }];
        return nil;
    }];
    return signal;
}
```
  
接下来把多个任务组装成一个数组

```
NSMutableArray *signals = [NSMutableArray array];
for (NSString *identifier in identifiers) {
    RACSignal * signal = [self deleteWithId:identifier];
    [signals addObject:signal];
}
```
然后使用`RACSignal`的`concat`方法

`concat`会顺序执行数组中的信号内容,上一个signal的信号`sendComplete`之后下一个信号内容才会开始执行

因为我们要在任务全部执行完成的时候发送一个回调和任务执行到一半的时候抛出异常停止任务和队列.
所以我们顺便加一个`doCompleted`和`catch`

```
RACSignal *concatSignal = [[[RACSignal concat:signals] doCompleted:^{
       completeBlock(nil); // 回调告诉前台说所有任务都完成了
   }] catch:^RACSignal *(NSError *error) {
       completeBlock(error); // 回调告诉前台说异常了
       return [RACSignal empty]; // 停止当前和接下来的任务的执行
   }];
```

如果你要订阅concatSignal信号的时候用到了UI刷新或者其他需要在主线程执行的任务,那么这里可以加多一个`deliverOn:[RACScheduler mainThreadScheduler]]`

所以最后的信号可能是这样子

```
RACSignal *concatSignal = [[[[RACSignal concat:signals] doCompleted:^{
    completeBlock(nil);
}] catch:^RACSignal *(NSError *error) {
    completeBlock(error);
    return [RACSignal empty];
}] deliverOn:[RACScheduler mainThreadScheduler]];
```

那订阅信号就简单了

```
[concatSignal subscribeNext:^(id x) {
    DKLog(@"%@",x);
}];
```
执行的时候他会根据数组的顺序一个个执行信号内的内容,这样子写起来也好看了很多.
