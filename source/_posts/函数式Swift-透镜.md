title: 函数式Swift --- 透镜
author: Arclin
abbrlink: c5814bfc
tags:
  - iOS
  - Swift
categories:
  - iOS
date: 2021-09-25 23:29:00
---
Swift是实现函数式思想的一门好语言，这里简要讲述一下函数式中透镜的Swift实现

<!-- more -->

## 举个例子

首先我们先创建一个结构体

```swift
struct Point {
    let x : CGFloat
    let y : CGFloat
}

var point = Point(x: 1, y: 2)
point.x = 2
```

一般情况下这时候会报错`Cannot assign to property: 'x' is a 'let' constant`，因为`x`是一个常量，所以无法修改

那么有时候我们如果需要改变一个不可变的属性的值，那么一般我们会选择再创建一个对象去覆盖

```swift
struct Point {
    let x : CGFloat
    let y : CGFloat
}

var point = Point(x: 1, y: 2)
let tempPoint = Point(x: 2, y: point.y)
point = tempPoint
```

但是这样子做未免显得有点麻烦，假如你觉得这样子还能接受，那么我再举个例子

```swift
struct Point {
    let x : CGFloat
    let y : CGFloat
}

struct Line {
    let start : Point
    let end : Point
}

struct Square {
    let line : Line // 通过线段我们可以计算出正方形的边长
    let origin : Point
}

let start = Point(x: 1, y: 1)
let end = Point(x: 10, y: 10)

let line = Line(start: start, end: end)

let origin = Point(x: 5, y: 5)
let square = Square(line: line, origin: origin)

square.line.start.x = 20 // Error : Cannot assign to property: 'x' is a 'let' constant
```

假如这时候我们希望把`square.line.start.x`设置为20，那么按照常规的写法就显得很麻烦了，更何况实际开发中可能还存在着更深的嵌套

## 方案

我们可以使用函数式的方案去解决上面的问题，首先我们先把问题简化，先考虑如何把`Point`的`x`属性优雅地去进行更改

### 基本原理

首先我们定义一个函数签名，取名为`Lens`(透镜)

```swift
typealias Lens<Subpart,Whole> = (@escaping (Subpart) -> Subpart) -> (Whole) -> Whole
```

其中`Subpart`表示要修改的属性的值，`Whole`表示被修改的这个对象

整个定义的含义是
1. 传入闭包表达式，这个闭包表达式会带入参数，参数值为被修改的属性的当前值，比如`x`的当前值1，然后闭包表达式修改这个值之后再次返回出去。
2. 返回一个对象的闭包，这个闭包会带入参数，参数值为当前被修改的对象，闭包表达式返回一个新的对象，比如`Point`

为了方便构建一个透镜，我们再添加一个方法用于初始化一个透镜

```swift
func lens<Subpart,Whole>(view: @escaping (Whole) -> Subpart, set: @escaping (Subpart,Whole) -> Whole) -> Lens<Subpart,Whole> {
    /// 缩减写法
    return { mapper in { set(mapper(view($0)), $0) } }
}
```

这个方法传入两个参数

1. 闭包表达式`view`表示传入一个对象，返回这个对象要被修改的那个属性当前值，比如我们上面提到的`x`，相当于一个`get`操作
2. 闭包表达式`set`表示传入要被修改属性的新值和要被修改的对象，然后返回包含新值的属性的新对象，相当于一个`set`操作

最后把闭包表达式返回出去就是我们所要的透镜，也可以理解为一个修改器。这个修改器内定好了哪个属性要被修改成哪个值，然后这个修改器最后返回一个闭包表达式，传入一个旧对象，返回一个带有新值的新对象

如果觉得上面的缩减写法有点晦涩，那我们展开来描述

```swift
return { mapper in // mapper是用于修改属性值的一个闭包表达式
    return {
        let subpart = view($0) // 拿到某个属性当前的值
        let newSubpart = mapper(subpart) // 处理成新值
        return set(newSubpart, $0) // 返回一个新对象
    }
}
```

### 使用

接下来我们就可以用上面定义好的方法来构件我们的`x`属性透镜和`y`属性透镜

```swift
extension Point {
    static let xL : Lens<CGFloat,Point> = lens(
        view: { $0.x },
        set: { Point(x: $0, y: $1.y) }
    )
    
    static let yL : Lens<CGFloat,Point> = lens(
        view: { $0.y },	// 即将要被修改的值是y
        set: { Point(x: $1.x, y: $0) } // 新值为$0，旧值
x依旧还是从原来对象里面取    
    )
}

// 定义一个能把x改成10的透镜
let xLens = Point.xL { _ in 10 }

var point1 = Point(x: 1, y: 1)
var point2 = Point(x: 2, y: 2)

point1 = xLens(point1)
point2 = xLens(point2)

print(point1) // Point(x: 10.0, y: 1.0)
print(point2) // Point(x: 10.0, y: 2.0)
```

### 改进

但是这样子的使用方法还是不够方便，所以我们定义多两个方法封装一下

```swift
func over<Subpart,Whole>(mapper: @escaping (Subpart) -> Subpart, lens: Lens<Subpart,Whole>) -> (Whole) -> Whole {
    return lens(mapper)
}

func set<Subpart,Whole>(value: Subpart,lens: Lens<Subpart,Whole>) -> (Whole) -> Whole {
    return over( mapper: { _ in value }, lens: lens)
}
```

`over`方法传入一个闭包表达式和一个透镜，闭包表达式参数是用来修改属性值，跟透镜结合使用，返回新对象

`set`方法传入一个新值和一个透镜，新值是用于构建修改属性的闭包，跟传入的透镜结合，调用`over`方法

有了这两个方法，我们就可以把之前的写法进行修改

```swift
let xLens = set(value: 10, lens: Point.xL) // 等价于下面的写法
// let xLens = Point.xL { _ in 10 } 
```

这么一看貌似只是简单地把闭包表达式变成了函数调用，也就是花括号变成了括号而已

但实际上变成了函数调用的方式之后我们就可以做更多的事情了

比如说：

```
infix operator %~
infix operator .~

func %~ <Subpart, Whole>(lhs: Lens<Subpart, Whole>, rhs: @escaping (Subpart) -> Subpart) -> (Whole) -> Whole {
    return over(mapper: rhs, lens: lhs)
}

func .~ <Subpart, Whole>(lhs: Lens<Subpart, Whole>, rhs: Subpart) -> (Whole) -> Whole {
    return set(value: rhs, lens: lhs)
}
```

这时候我们的调用方式就变成了

```swift
let xLens = Point.xL .~ 10
```

还不够，再加一个定义，我们把对象的修改方式给改了

```swift
precedencegroup LensPrecedence {
    higherThan : AdditionPrecedence
}

infix operator .~ : LensPrecedence
infix operator %~ : LensPrecedence
infix operator |> : AdditionPrecedence


func %~ <Subpart, Whole>(lhs: Lens<Subpart, Whole>, rhs: @escaping (Subpart) -> Subpart) -> (Whole) -> Whole {
    return over(mapper: rhs, lens: lhs)
}

func .~ <Subpart, Whole>(lhs: Lens<Subpart, Whole>, rhs: Subpart) -> (Whole) -> Whole {
    return set(value: rhs, lens: lhs)
}

func |> <A, B> (lhs: A, rhs: (A) -> B) -> B {
    return rhs(lhs)
}
```

这样子当我们想要修改一个点的x值和y值的时候，就可以这么写了

```swift
var point = Point(x: 1, y: 1)

point = point
    |> Point.xL .~ 10
    |> Point.yL .~ 20
    |> Point.xL %~ { $0 - 5 }
```

看起来就简洁许多

### 复杂的情况

那么刚才我们提及的复杂的情况，除了点之外，还出现了线和面，那应该怎么做呢

同理可得，我们给线和面也添加透镜

```swift
extension Line {
    static let startL : Lens<Point,Line> = lens(
        view: { $0.start },
        set: { Line(start: $0, end: $1.end ) }
    )
    
    static let endL : Lens<Point,Line> = lens(
        view: { $0.end },
        set: { Line(start: $1.start, end: $0) }
    )
}

extension Square {
    static let lineL : Lens<Line,Square> = lens(
        view: { $0.line },
        set: { Square(line: $0, origin: $1.origin) }
    )
    static let originL : Lens<Point,Square> = lens(
        view: { $0.origin },
        set: { Square(line: $1.line, origin: $0) }
    )
}
```

新增一个运算符`<<<`表示左结合，把右参数（闭包表达式）作为左参数（闭包表达式）的参数，并修改一下运算符之间的优先级

```swift
precedencegroup CombinePrecedence {
    associativity : left
    higherThan : LensPrecedence
}

precedencegroup LensPrecedence {
    associativity: right
    higherThan : AdditionPrecedence
}

infix operator <<< : CombinePrecedence

func <<< <A, B, C> (lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
    return { lhs(rhs($0)) }
}
```

最终调用方式如下

```swift
/// 线段的起始点设置为20，原点的y值设置为30
square = square
    |> Square.lineL <<< Line.startL <<< Point.xL .~ 20
    |> Square.originL <<< Point.yL .~ 30
```

看起来也是十分简洁

### 完整代码

仅供参考

```swift
import UIKit

struct Point {
    let x : CGFloat
    let y : CGFloat
}

struct Line {
    let start : Point
    let end : Point
}

struct Square {
    let line : Line
    let origin : Point
}

typealias Lens<Subpart,Whole> = (@escaping (Subpart) -> Subpart) -> (Whole) -> Whole

func lens<Subpart,Whole>(view: @escaping (Whole) -> Subpart, set: @escaping (Subpart,Whole) -> Whole) -> Lens<Subpart,Whole> {
//    return { mapper in
//        return {
//            let subpart = view($0)
//            let newSubpart = mapper(subpart)
//            return set(newSubpart, $0)
//        }
//    }
    /// 可以缩减为这种写法
    return { mapper in { set(mapper(view($0)), $0) } }
}

func over<Subpart,Whole>(mapper: @escaping (Subpart) -> Subpart, lens: Lens<Subpart,Whole>) -> (Whole) -> Whole {
    return lens(mapper)
}

func set<Subpart,Whole>(value: Subpart,lens: Lens<Subpart,Whole>) -> (Whole) -> Whole {
    return over( mapper: { _ in value }, lens: lens)
}

precedencegroup CombinePrecedence {
    associativity : left
    higherThan : LensPrecedence
}

precedencegroup LensPrecedence {
    associativity: right
    higherThan : AdditionPrecedence
}

infix operator %~  : LensPrecedence
infix operator .~  : LensPrecedence
infix operator |>  : AdditionPrecedence
infix operator <<< : CombinePrecedence

func %~ <Subpart, Whole>(lhs: Lens<Subpart, Whole>, rhs: @escaping (Subpart) -> Subpart) -> (Whole) -> Whole {
    return over(mapper: rhs, lens: lhs)
}

func .~ <Subpart, Whole>(lhs: Lens<Subpart, Whole>, rhs: Subpart) -> (Whole) -> Whole {
    return set(value: rhs, lens: lhs)
}

func |> <A, B> (lhs: A, rhs: (A) -> B) -> B {
    return rhs(lhs)
}

func <<< <A, B, C> (lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
    return { lhs(rhs($0)) }
}

extension Point {
    static let xL : Lens<CGFloat,Point> = lens(
        view: { $0.x },
        set: { Point(x: $0, y: $1.y) }
    )
    
    static let yL : Lens<CGFloat,Point> = lens(
        view: { $0.y },
        set: { Point(x: $1.x, y: $0) }
    )
}

extension Line {
    static let startL : Lens<Point,Line> = lens(
        view: { $0.start },
        set: { Line(start: $0, end: $1.end ) }
    )
    
    static let endL : Lens<Point,Line> = lens(
        view: { $0.end },
        set: { Line(start: $1.start, end: $0) }
    )
}

extension Square {
    static let lineL : Lens<Line,Square> = lens(
        view: { $0.line },
        set: { Square(line: $0, origin: $1.origin) }
    )
    static let originL : Lens<Point,Square> = lens(
        view: { $0.origin },
        set: { Square(line: $1.line, origin: $0) }
    )
}

//let xLens = Point.xL { _ in 10 }
//let xLens = set(value: 10, lens: Point.xL)
//let xLens = Point.xL .~ 10
var point1 = Point(x: 1, y: 1)

point1 = point1
    |> Point.xL .~ 10
    |> Point.yL .~ 20
    |> Point.xL %~ { $0 - 5 }

let origin = Point(x: 5, y: 5)
var line = Line(start: origin, end: point1)
var square = Square(line: line, origin: origin)

print("修改前\(square)")

/// 线段的起始点设置为20，原点的y值设置为30
square = square
    |> Square.lineL <<< Line.startL <<< Point.xL .~ 20
    |> Square.originL <<< Point.yL .~ 30

print("修改后\(square)")
```