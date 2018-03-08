title: 利用MJExtension取出模型数组中的某个属性组成数组
author: Arclin
tags:
  - iOS
categories:
  - iOS
date: 2016-10-17 00:00:00
---
利用MJExtension取出模型数组中的某个属性组成数组

<!-- more -->

在做otg的时候想做这么一件事，就是遍历模型数组然后取出里面的属性值然后再保存到数组里，后来翻了翻MJExtension好像有类似的方法声明，试了一下果然可以

```
MJProperty *p = [[MJProperty alloc] init];
[p setValue:@"text" forKey:@"name"]; \\ 因为name是readonly，所以我就只能用keyValue的方式去给他赋值了
NSArray *arr = [p valueForObject:self.topics];
NSLog(@"%@",arr);
```

如果包装一下大概就是这样子

```
- (NSArray *)fetchPropertys:(NSString *)propertyName fromObjects:(NSArray *)objects{
	MJProperty *p = [[MJProperty alloc] init];
	[p setValue:propertyName forKey:@"name"]; 
	return [p valueForObject:objects];
}
```

弄个分类可能会比较方便吧

```
- (NSArray *)fetchPropertys:(NSString *)propertyName{
	MJProperty *p = [[MJProperty alloc] init];
	[p setValue:propertyName forKey:@"name"]; 
	return [p valueForObject:self];
}
```