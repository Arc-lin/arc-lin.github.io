---
title: What's new in Swift 5.7
abbrlink: 89a7f98f
date: 2022-07-06 16:59:46
tags:
   - iOS
   - Swift
categories:
   - iOS
---

本文总结自WWDC 2022 [《What's new in Swift》](https://developer.apple.com/videos/play/wwdc2022/110354/)

<!-- more -->

## Optional unwrapping

在对可选值进行解包的时候，可以用一种更简便的方式

Swift 5.5

```swift
var name : String? = "Linda"
```

```swift
if let name = name {
   print("Hello, \(name)!")
}
```

Swift 5.7

```swift
if let name {
   print("Hello, \(name)!")
}
```

## Multi-statement closure type inference

当闭包表达式内有多行语句的时候，可以不用显式声明返回值类型

```swift
let scores = [100,80, 85]
```

Swift 5.5 

```swift
let oldResults = scores.map { score -> String in
   if score > 85 {
      return  "\(score)%: Pass"
   } else {
      return  "\(score)%: Fail"
   }
}
```

Swift 5.7

```swift
let results = scores.map { score in
   if score >= 85 {
      return  "\(score)%: Pass"
   } else {
      return  "\(score)%: Fail"
   }
}
```

## Regular expressions

新增正则表达式工具 `Regex`，支持正则语法检查

举例：取出句子中的"at"的range

```swift
let message = "the cat sat on the mat"
print(message.range(of:"at"))
```

Swift 5.7 使用字符串初始化Regex，若传入不符合语法规则的正则表达式，则会throw error

```swift
do {
   let atSearch = try Regex("[a-z]at")
   print(message.range(of:atSearch))
} catch {
   print("Failed to create regex")
}
```

另外可以使用`/ /`包裹正则表达式（字面量语法），当传入不符合语法规则的正则表达式的时候，编译器将会报错

```swift
print(message.ranges(of: /[a-z]at/))
```

此外，Swift  5.7还新增了一种DSL的语法去做类似正则表达式的事情，如下:

```swift
let search = /My name is (.+?) and I'm (\d+) years old./
let greeting = "My name is Taylor and I'm 26 years old"
```

等价于

```swift
let search = Regex {
   "My name is"
   
   Capture {
      OneOrMore(.word)
   }
   
   "and I'm"
   
   Capture {
      OneOrMore(.digit)
   }
   
   " years old."
}
```

## Protocol and generics

针对泛型协议，可以使用`any`和`some`关键字来简洁编码

```swift
protocol Pizza {
   var size : Int { get }
   var name : String { get }
}
```

Swift 5.5 

这里传入的参数可以是任意遵循了`Pizza`的类或者结构体的实例

```swift
func receivePizza(_ pizza: Pizza) {
   print("Nice \(pizza.name)")
}
```

Swift 5.7
```swift
func receivePizza(_ pizza: any Pizza) {
   print("Nice \(pizza.name)")
}
```

Swift 5.5 

这里传入的参数可以是某一个遵循了`Pizza`的类或者结构体的任意实例，类型T需要确定

```swift
func receivePizza<T : Pizza>(_ pizza: Pizza) {
   print("Nice \(pizza.name)")
}
```

Swift 5.7
```swift
func receivePizza(_ pizza: some Pizza) {
   print("Nice \(pizza.name)")
}
```

### Some 和 Any

`some`和`any`其实是以前就有的关键字

some : 指定某种遵循了协议A的类型

any : 任意遵循了协议A的类型

举例：

下面代码会报错，提示Cat不能复制给animal，因为animal已经被指定为Dog类型了

```swift
var animal : some Animal = Dog()
animal = Cat()
```

下面代码不会报错，因为animal可以是任意遵循了Animal协议的类的实例

```swift
var animal : any Animal = Dog()
animal = Cat()
```

同理，会报错，因为some只能指定一种类型

```swift
let animals : [some Animal] = [Dog(),Cat()]
```

不会报错，因为any能指定任意遵循了Animal协议的类型

```swift
let animals : [some Animal] = [Dog(),Cat()]
```

那到底什么时候用`some`，什么时候用`any`呢？

答：当你在设计接口的时候就已经默认是某个类型的时候，就用`some`，当不符合上述要求的时候就用`any`

## Swift Package Plugins

Swift新增的插件，就是可以用swift写脚本，然后可以在Xcode构建的时候运行。比如代码格式化，产出代码统计报告等

## Swift Concurrency Instrument

在Instrument里面新增了针对`awiat`相关代码的性能检测