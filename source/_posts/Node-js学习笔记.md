---
title: Node.js学习笔记
author: Arclin
tags:
  - Node.js
categories:
  - Node.js
abbrlink: 1aafa723
date: 2017-03-06 00:00:00
---
Node.js的学习笔记,持续更新

<!-- more -->

> Node.js 是一个基于 Chrome V8 引擎的 JavaScript 运行环境。Node.js 使用了一个事件驱动、非阻塞式 I/O 的模型
>
> 事件驱动
>> 所谓事件驱动，简单地说就是你点什么按钮（即产生什么事件），电脑执行什么操作（即调用什么函数）.当然事件不仅限于用户的操作. 事件驱动的核心自然是事件。从事件角度说，事件驱动程序的基本结构是由一个事件收集器、一个事件发送器和一个_事件处理器组成。

>> 事件收集器专门负责收集所有事件，包括来自用户的（如鼠标、键盘事件等）、来自硬件的（如时钟事件等）和来自软件的（如操作系统、应用程序本身等）。
事件发送器负责将收集器收集到的事件分发到目标对象中。
事件处理器做具体的事件响应工作，它往往要到实现阶段才完全确定，因而需要运用虚函数机制（函数名往往取为类似于HandleMsg的一个名字）。对于框架的使用者来说，他们唯一能够看到的是事件处理器。这也是他们所关心的内容。

> 非阻塞式 I/O

>> I/O 即Input/Output 的缩写

>> 阻塞和非阻塞关注的是程序在等待调用结果（消息，返回值）时的状态.

>> 阻塞调用是指调用结果返回之前，当前线程会被挂起。调用线程只有在得到结果之后才会返回。
非阻塞调用指在不能立刻得到结果之前，该调用不会阻塞当前线程。

>>你打电话问书店老板有没有《分布式系统》这本书，你如果是阻塞式调用，你会一直把自己“挂起”，直到得到这本书有没有的结果，如果是非阻塞式调用，你不管老板有没有告诉你，你自己先一边去玩了， 当然你也要偶尔过几分钟check一下老板有没有返回结果。
在这里阻塞与非阻塞与是否同步异步无关。跟老板通过什么方式回答你结果无关。

## let var const

`let` 允许把变量的作用域限制在块级域中。与 `var` 不同处是：`var` 申明变量要么是全局的，要么是函数级的，而无法是块级的。

`let`的作用域是块，而`var`的作用域是函数

```
'use strict';
for (let i = 0; i < 10; i++) {
  console.log(i); // 0, 1, 2, 3, 4 ... 9
}
console.log(i); // i is not defined
const这个声明创建一个常量,可以全局或局部的函数声明,不可以被重新赋值.
```

## Map WeakMap Set WeakSet

### Map
Map原生提供三个遍历器生成函数和一个遍历方法。

`keys()` 返回键名的遍历器。
`values()` 返回键值的遍历器。
`entries()` 返回所有成员的遍历器。
`forEach()` 遍历Map的所有成员。

```
var myMap = new Map();
myMap.set(0, "zero");
myMap.set(1, "one");
 
for (var key of myMap.keys()) {
  console.log(key);
}
// 0 1
 
for (var value of myMap.values()) {
  console.log(value);
}
// zero one
 
for (var item of myMap.entries()) {
  console.log(item[0] + " = " + item[1]);
}
// 0 = zero 1 = one
 
myMap.forEach(function(value, key) {
  console.log(key + " = " + value);
}, myMap)
// 0 = zero 1 = one
```

### WeakMap
WeakMap结构与Map结构基本类似，唯一的区别是它只接受对象作为键名（null除外），不接受其他类型的值作为键名，而且键名所指向的对象，不计入垃圾回收机制。
WeakMap与Map在API上的区别主要是两个，一是没有遍历操作（即没有key()、values()和entries()方法），也没有size属性；二是无法清空，即不支持clear方法。这与WeakMap的键不被计入引用、被垃圾回收机制忽略有关。
WeakMap只有四个方法可用：get()、set()、has()、delete()。

### Set
`add(value)` 添加某个值，返回Set结构本身。
`delete(value)` 删除某个值，返回一个布尔值，表示删除是否成功。
`has(value)` 返回一个布尔值，表示该值是否为Set的成员。
`clear()` 清除所有成员，没有返回值。 上面这些属性和方法的实例如下。

```
var s = new Set();
s.add(1).add(2).add(2);
// 注意2被加入了两次
console.log(s.size); // 2
console.log(s.has(1)); // true
console.log(s.has(2)); // true
console.log(s.has(3)); // false
console.log(s.delete(2));
console.log(s.has(2)); // false
```

Set的遍历跟Map差不多,但是如果使用`set.entries()`去遍历的话,出来的结果会是像这样子["red", "red"] ["green", "green"] ["blue", "blue"],包括键名和键值，所以每次输出一个数组，它的两个成员完全相等。
### WeakSet
weakSet和WeakMap的道理也差不多,WeakSet的成员只能是对象，而不能是其他类型的值.WeakSet中的对象都是弱引用，即垃圾回收机制不考虑WeakSet对该对象的引用
WeakSet不能遍历，是因为成员都是弱引用，随时可能消失，遍历机制无法保存成员的存在，很可能刚刚遍历结束，成员就取不到了。WeakSet的一个用处，是储存DOM节点，而不用担心这些节点从文档移除时，会引发内存泄漏。

```
var ws = new WeakSet();
var obj = {};
var foo = {};
ws.add(obj);
ws.has(foo);    // false
WeakSet没有size属性，没有办法遍历它的成员。
ws.size // undefined
ws.forEach // undefined
ws.forEach(function(item){ console.log('WeakSet has ' + item)})
```

```
// TypeError: undefined is not a function
```
## Generator Promise Symbol
### Generator
Generator函数有多种理解角度。从语法上，首先可以把它理解成，Generator函数是一个状态机，封装了多个内部状态。

执行Generator函数会返回一个遍历器对象，也就是说，Generator函数除了状态机，还是一个遍历器对象生成函数。返回的遍历器对象，可以依次遍历Generator函数内部的每一个状态。

```
function* helloWorldGenerator() {
  yield 'hello';
  yield 'world';
  return 'ending';
}
var hw = helloWorldGenerator();
console.log(hw.next()); \\ { value: 'hello', done: false }
console.log(hw.next()); \\ { value: 'world', done: false }
console.log(hw.next()); \\ { value: 'ending', done: true }
console.log(hw.next()); \\ { value: undefined, done: true }
```

`yield` 意为’产出’ 是用来定义不同的内部状态,调用next()方法的时候会返回Generator的下一个状态,直到return为止,输出的done中的值表示Generator函数是否已经执行结束.

`yield *` 语句 : 用来在一个Generator中执行另外一个Generator函数

```
function* anotherGenerator(i) {
  yield i + 1;
  yield i + 2;
  yield i + 3;
}
function* generator(i){
  yield i;
  yield* anotherGenerator(i);
  yield i + 10;
}
var gen = generator(10);
console.log(gen.next().value); // 10
console.log(gen.next().value); // 11
console.log(gen.next().value); // 12
console.log(gen.next().value); // 13
console.log(gen.next().value); // 20
```
运行结果就是使用一个遍历器，遍历了多个Generator函数，有递归的效果。

### Promise
Promise 是一个构造函数

```
var promise = new Promise(function(resolve, reject) {
  // ... some code
  if (/* 异步操作成功 */){
    resolve(value);
  } else {
    reject(error);
  }
});
```

Promise函数自带两个参数: `resolve`意为返回一个成功的回调,`reject`意为返回一个错误的回调
然后订阅回调的方法如下

```
promise.then(function(value) {
  // success
}, function(value) {
  // failure
});
```

PS: 这个函数很像OC的block方法,上面的函数就类似OC的如下写法

```
- (void)promise:(void(^)(id success))resolve failure:(void(^)(id failure))reject {
	if(...){
		resolve(resolveValue);
	}else {
		reject(rejectValue);
	}
} 

//订阅
[self promise:^(id success){
	NSLog(success);
} failure:^(id failure){
	NSLog(failure);
}];
// 纯脑补,也不知道有没有写对
```

#### catch() 方法
专门用来捕获异常的回调,会捕获到`then()`的第二个参数的回调

如果在`then()`中使用了throw xxx;语句,那么也会走`catch()`回调

`catch()`和`then()`方法都会返回Promise对象,所以可以链式调用

```
promise.then(function(value) {
    console.log(value);      
},null).catch(function(value){
	console.log(value);
});
```

OR

```
p1.then(function(value) {
  console.log(value); // "成功!"
  throw "哦，不!";
}).catch(function(e) {
  console.log(e); // "哦，不!"
});
```

你还可以`then()`完再`then()`

```
var p2 = new Promise(function(resolve, reject) {
  resolve(1);
});

p2.then(function(value) {
  console.log(value); // 1
  return value + 1;
}).then(function(value) {
  console.log(value); // 2
});
```
#### all() 方法

Promise.all方法用于将多个Promise实例，包装成一个新的Promise实例。

```
var p = Promise.all([p1,p2,p3]);
```

只要有一个reject了,那么p就会抛出失败的回调,只有全部都resolve了,才会抛出成功的回调

#### race() 方法
顾名思义 赛跑

同样是来绑定多个Promise实例,不同的是谁先返回就走谁的回调,如果p1五秒后发失败回调,p2一秒后发成功回调,那么Promise.race([p1, p2])就等于p2.

```
Promise.race([p1, p2]).then(function(value) {
  console.log(value); // "two"
  // Both resolve, but p2 is faster
});
```

### Symbol
符号

用Symbol生成的对象,绝对不会重复!!!

```
var s1 = Symbol("foo");
var s2 = Symbol("foo");
console.log(s1 === s2); // false
getOwnPropertySymbols()
```

这个方法可以获得对象的所有Symbol类型的成员属性名

```
var obj = {};
var a = Symbol('a');
var b = Symbol('b');
 
obj[a] = 'Hello';
obj[b] = 'World';
var objectSymbols = Object.getOwnPropertySymbols(obj);
console.log(objectSymbols);
// [Symbol(a), Symbol(b)]
```

#### Symbol.for()
这个方法用来搜索之前有没有定义过某个Symbol名,如果有的话就返回值没有的话就就新建一个Symbol,有种取缓存的感觉

```
var s1 = Symbol.for('foo'); // 定义一下
var s2 = Symbol.for('foo'); // 取出之前定义的值
console.log(s1 === s2); // true
Symbol.keyFor()
跟上面的是相反的,通过值来取键

var s1 = Symbol.for("foo");
Symbol.keyFor(s1) // "foo"
 
var s2 = Symbol("foo");
Symbol.keyFor(s2) // undefined
```

## 箭头函数
其实就是简写方法而已

```
var  f = function(v1,v2) {
	return v1+v2;
}
```

等同于

```
var f = (v1,v2) => v1+v2;
```

### 注意事项

函数体内的this对象，绑定定义时所在的对象，而不是使用时所在的对象。
不可以当作构造函数，也就是说，不可以使用`new`命令，否则会抛出一个错误。
不可以使用`arguments`对象，该对象在函数体内不存在。如果要用，可以用`Rest`参数代替。
不可以使用`yield`命令，因此箭头函数不能用作Generator函数。

## 网络请求

### 方式一 使用 http.request()

```
var http = require('http');  
  
var qs = require('querystring');  
  
var data = {  
    a: 123,  
    time: new Date().getTime()};//这是需要提交的数据  
    
var content = qs.stringify(data);   
var options = {  
    hostname: '127.0.0.1',  
    port: 10086,  
    path: '/pay/pay_callback?' + content,  
    method: 'GET'  
};  
  
var req = http.request(options, function (res) {  
    console.log('STATUS: ' + res.statusCode);  
    console.log('HEADERS: ' + JSON.stringify(res.headers));  
    res.setEncoding('utf8');  
    res.on('data', function (chunk) {  
        console.log('BODY: ' + chunk);  
    });  
});  
  
req.on('error', function (e) {  
    console.log('problem with request: ' + e.message);  
});  
  
req.end();
```

### 方式二 使用 http.get() 发送GET请求

```
var httpRequest = http.get('http://localhost:8088/tempFile/LocalData.json',function(request,response){
      var html='';
      request.on('data',function(data){
        	html+=data;
      });
      request.on('end',function(){
			console.log(html);
      });
  });
```

> 学习资料来自:[http://www.hubwiz.com](http://www.hubwiz.com) 等