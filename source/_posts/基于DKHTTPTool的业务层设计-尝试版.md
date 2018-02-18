title: 基于DKHTTPTool的业务层设计_尝试版
author: Arclin
tags:
  - iOS
  - 杂谈
categories:
  - iOS
date: 2016-11-30 00:00:00
---
基于DKHTTPTool的业务层设计_尝试版

由于是尝试版,所以这里只是简单讲下思路.

<!-- more -->

- 首先 DKHTTPTool提供了缓存策略的选择,让方法调用和缓存可以进行统一的处理
然后业务层进行缓存策略的选择, 但由于 ViewModel实际需要的是一个模型(数组) ,而 `DKHTTPTool`返回的是一个 `DKResponse` 对象,所以业务层除了进行缓存策略的选择外,还需要进行对 `DKResponse`的处理.

- DKResponse 里面有一个成员属性result用来储存后台返回的 json 数据,所以业务层(以下称 Service)需要去对这个属性值进行封装 , 封装的方法我们选择使用 MJExtension 的方法就可以了

- 对于一些数据量比较大,数据结构比较复杂的模型, `MJExtension` 处理之后应该还需要存入数据库,便于日后的筛选,排序等操作.那么,此时逻辑就出现了变化

	- 对于简单的数据,处理流程是 VM调用Service方法 -> Service 调用 HTTP方法 -> 返回原始数据 -> `MJExtension`处理数据 -> 返回给 VM
	- 对于复杂的数据,处理流程是 VM调用Service方法 -> Service 调用 HTTP方法 -> 返回原始数据 -> `MJExtension`处理数据 -> 插入 or 更新 数据库表 - -> 同时返回处理好的数据给 VM
- 当然第一种是最好处理的,只要套一层方法就可以把数组返回回去了(如果要进行比较简单的数据筛选操作,用 `NSPredicate`,排序用`NSSortDescriptor`也是可以实现的),但是对于第二种方法,那就需要我们新增一个 Service基类去统一处理取数据库数据的操作,包括条件筛选,排序 ,去重的等等的操作