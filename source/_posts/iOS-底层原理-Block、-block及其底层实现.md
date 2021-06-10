title: iOS 底层原理 --- Block、__block及其底层实现
author: Arclin
abbrlink: 8275b854
tags:
  - iOS
  - 底层原理
categories:
  - iOS
date: 2021-06-07 23:50:00
---
本文主要简述Block、__block的本质是什么东西，文章涉及循环引用等开发常见问题，需要重点关注。

<!--more-->

## block的底层结构

ARC环境下，会自动会block进行一次copy操作，将block从栈拷贝到堆上面

## __block

- 注意 MRC环境下，__block 不会对变量造成强引用，即以下情况person会提前释放

	```
	__block Person *person = [Person new];
	void(^block)(void) = ^{
		NSLog(@"%@",person);
	};
	block(); /// 这时候person已经释放了
	```

## 循环引用

- 以下代码会产生循环引用
	
	```
	Person *person = [Person alloc] init];
	person.age = 10;
	person.block = ^{
		NSLog(@"age is %d",person.age);
	};
	```

- __weak: 不会产生强引用，指向的对象销毁时，会自动让指针至nil
- __unsafe_unretain: 不会产生强引用，不安全，指向的对象销毁时，指针存储的地址值不变