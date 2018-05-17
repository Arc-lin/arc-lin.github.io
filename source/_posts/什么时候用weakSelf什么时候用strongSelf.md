---
title: 什么时候用weakSelf什么时候用strongSelf
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: f9b1d95c
date: 2016-10-17 00:00:00
---
#### 什么时候用weakSelf 什么时候用 strongSelf

 - Objective C 的 Block 是一个很实用的语法，特别是与GCD结合使用，可以很方便地实现并发、异步任务。但是，如果使用不当，Block 也会引起一些循环引用问题(retain cycle)—— Block 会 retain ‘self’，而 ‘self‘ 又 retain 了 Block。因为在 ObjC 中，直接调用一个实例变量，会被编译器处理成 ‘self->theVar’，’self’ 是一个 strong 类型的变量，引用计数会加 1，于是，self retains queue， queue retains block，block retains self。

 - 解决 retain circle

 	- Apple 官方的建议是，传进 Block 之前，把 ‘self’ 转换成 weak automatic 的变量，这样在 Block 中就不会出现对 self 的强引用。如果在 Block 执行完成之前，self 被释放了，weakSelf 也会变为 nil。
示例代码：

```
__weak typeof(self) weakSelf = self;
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ 
	[weakSelf doSomething]; 
});
```

 - clang 的文档表示，在 doSomething 内，weakSelf 不会被释放。但，下面的情况除外：

```
__weak typeof(self) weakSelf = self;
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 	[weakSelf doSomething]; 
 	[weakSelf doOtherThing]; 
});
```

 - 在 doSomething 中，weakSelf 不会变成 nil，不过在 doSomething 执行完成，调用第二个方法 doOtherThing 的时候，weakSelf 有可能被释放，于是，strongSelf 就派上用场了：

```
__weak __typeof__(self) weakSelf = self;
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 	__strong typeof(self) strongSelf = weakSelf;
   [strongSelf doSomething];
   [strongSelf doOtherThing];
 });
```

 - __strong 确保在 Block 内，strongSelf 不会被释放。

- 总结

	- 在 Block 内如果需要访问 self 的方法、变量，建议使用 weakSelf。

	- 如果在 Block 内需要多次 访问 self，则需要使用 strongSelf。