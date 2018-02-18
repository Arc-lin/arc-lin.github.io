title: 使用RAC+DKHTTPTool实践
author: Arclin
tags:
  - iOS
  - Reactive Cocoa
categories:
  - iOS
date: 2016-12-26 00:00:00
---
使用RAC+DKHTTP套件实践
- 这次通过一个简单的例子来解说DKHTTP套件与 RAC 结合的使用

<!-- more -->

![](https://github.com/Arc-lin/BlogImage/blob/master/444.png?raw=true)

- 首先简析下这个界面
	- 顶部搜索框部分的背景：广告栏位+图书推荐的图片，这里是一个获取图片的接口（接口 A）
	- 图书推荐： 这里也是一个接口，需要显示图书的封面（接口 B）
	- 笔记推荐： 这里也是一个接口，需要显示图书笔记的一些简介 （接口 C）
- 页面渲染

	- 同页面多接口的渲染方式有多种： 
    	-	一是接口的串联，也就是一个接口返回的数据交作为参数给下一个接口去发送请求 ；
    	- 二是同时发送请求，根据接口返回的顺序渲染页面；
    	- 三是同时请求，等所有的接口返回之后再一次性进行渲染。
	- 上面的三种渲染方式，RACSignal都有相应的解决方案，假设这里页面渲染的方式选择的是依次渲染，那么我们使用 DKHTTPChainTool 的executeSignal()来写个例子

```
 RACSignal *signalA = DKHTTPChainInstance.method(@"POST")
                                         .url(@"")
                                         .params(@{@"did":@"1",@"page":@"1",@"num":@"100"})
                                         .executeSignal();

RACSignal *signalB = DKHTTPChainInstance.method(@"POST")
                                        .url(@"")
                                        .params(@{@"dis_id":@"9"})
                                        .executeSignal();

RACSignal *signalC = DKHTTPChainInstance.method(@"POST")
                                        .url(@"")
                                        .params(@{@"dis_id":@"9"})
                                        .executeSignal();

RACSignal *mergeSignal = [RACSignal merge:@[signalA,signalB,signalC]];
[mergeSignal subscribeNext:^(DKResponse *x){
      DKLog(@"%zd  %@",x.taskIdentifier,x.rawData);
}];
```

上面这个例子的结果会依次执行三个接口，并且按照接口返回的顺序执行mergeSignal 的 subscribeNext 的 block

### 同时请求接口，等所有接口返回数据之后再进行渲染

> 上面的三个 Signal就不重复写了

```
RACSignal *mergeSignal  = [RACSignal zip:@[signalA,signalB,signalC]];
[mergeSignal subscribeNext:^(RACTuple *x){
     [x.rac_sequence.signal subscribeNext:^(DKResponse *x) {
         DKLog(@"%@",x.rawData);
     }];
}];
```

上面的 `mergeSignal` 里面会发送一个 `RACTuple` ,里面依次包装着三个请求 Signal的 `DKResponse`回调对象

### 接口串联，上一个接口响应的数据作为下一个接口的参数

```
 RACSignal *flattenSignal = [signalA flattenMap:^RACStream *(DKResponse *value) {
        NSString *did = value.result[@"content"][0][@"d_id"];
        return DKHTTPChainInstance.method(@"GET")
                                 .url(@"")
                                 .params(@{@"did":did,@"page":@"1",@"num":@"20"})
                                 .executeSignal();
}];
[flattenSignal subscribeNext:^(DKResponse *x) {
    DKLog(@"%@",x.rawData);
}];
```

平时常用的大概就这么几个，待补充吧，之后我会继续讲讲关于异常处理的问题。