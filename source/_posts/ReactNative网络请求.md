---
title: ReactNative网络请求
author: Arclin
tags:
  - React Native
categories:
  - React Native
abbrlink: b6bd206a
date: 2017-03-15 00:00:00
---
关于React Native 的网络请求的总结

<!-- more -->

因为这里使用的是`fetch()`方法,返回的是一个`Promise`对象,所以可以使用`then()`和`catch()`方法进行链式调用,也可以用`all()`,`race()` 去包装多个请求

具体的话可以看这里

### GET
```
fetch("http://localhost:3000/get")
	.then((response) => response.json()) // 这里取出响应体的JSON数据并返回
	.then((responseJSON) => { // 处理上面返回的JSON数据
		// do something
		
	})
	.catch((err) => { // 捕获错误
		// catch err
	});
```
### POST
网上说有两种,不过我一般用第二种比较多

#### application/json
```
var fetchOptions = {
           method: 'POST',
           headers: {
               'Accept': 'application/json',
               //json形式
               'Content-Type': 'application/json'
           },
           body:JSON.stringify('data=test') // 这里是请求参数,键值对形式
       };

fetch("http://localhost:3000/post", fetchOptions)
   .then((response) => response.json())
   .then((responseText) => {
        console.log(responseText);
   });
```

#### application/x-www-form-urlencoded

```
 var fetchOptions = {
           method: 'POST',
           headers: {
               'Accept': 'application/json',
               //表单
               'Content-Type': 'application/x-www-form-urlencoded'
           },
           body:'data=test' // 这里是请求参数,键值对形式
       };

fetch("http://localhost:3000/post", fetchOptions)
   .then((response) => response.json())
   .then((responseText) => {
        console.log(responseText);
   });
```
如果使用的是Restful的API的话,那么只要把上面`fetchOption`里面的`method`改成对应的方法就好.

当然,封装一个网络请求工具是有必要的,等我有时间写一下.