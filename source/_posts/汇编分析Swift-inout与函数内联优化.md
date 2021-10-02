title: 汇编分析Swift inout关键字
author: Arclin
abbrlink: 4e8bf338
tags: []
categories: []
date: 2021-10-02 11:24:00
---
本文主要讲述通过汇编分析展示Swift inout的实现原理与Swift针对函数的内联优化原理

<!-- more -->

首先我们先了解几个汇编指令(AT&T汇编：iOS模拟器汇编，ARM汇编：iOS真机汇编)

- `movq %rax %rdx`：将`%rax`的值赋值给`%rdx`

- `leaq -0x18（%rbp）,%rax`：将`%rbp-0x18`的地址值赋值给`rax`

- `callq 0x100003f60`：调用地址值为`0x100003f60`的函数

- 寄存器的具体用途
	- rax、rdx常作为函数返回值使用
	- rdi，rsi，rdx，rcx、r8、r9等寄存器常用于存放函数参数
	- rsp、rbp用于栈操作
	- rip作为指令指针

## 函数中的inout

首先我们看看普通的函数

```swift
var number = 10

func test(_ num : Int) {
    
}

test(number)
```

在函数调用那里打个断点，可以看到汇编指令是这样子的

```
    0x100003f4e <+78>: movq   -0x30(%rbp), %rdi
->  0x100003f52 <+82>: callq  0x100003f60  ; TestSwift.test(Swift.Int) -> () at main.swift:48
```

分号后面是注释，用于帮助我们理解汇编指令。

这两行的含义是把寄存器`%rbp-0x30`地址上的值赋值给寄存器`%rdi`，将其作为参数然后调用函数地址为`0x100003f60`的函数。

所以很明显，这是一个`值传递`行为

然后我们再来看看使用inout的函数

```swift
var number = 10

func test(_ num : inout Int) {
    num = 20
}

test(&number)
```

当然按照预期number的值会被改变成20，这里我们再次在函数调用那里打断点看看效果

```
    0x100003f37 <+55>: leaq   0x40da(%rip), %rdi ; TestSwift.number : Swift.Int
->  0x100003f3e <+62>: callq  0x100003f60 ; TestSwift.test(inout Swift.Int) -> () at main.swift:40
```

从这里我们可以看出，系统通过`leaq`指令，将`%rip+0x40da`的地址，赋值给了寄存器`%rdi`，然后将其作为参数调用了地址值为`0x100003f60`的函数

所以很明显，这是一个`地址传递`行为

总结：在函数调用中，`inout`修饰的参数是通过地址传递实现修改值的


## 属性使用inout

针对存储属性和计算属性进行`inout`修饰传参，其实现原理会有所不同，我们看下面的一个例子

首先先写一个简单的Demo

```swift
struct Shape {
    var width : Int
    var side : Int {
        willSet {
            print("willSetSide", newValue)
        }
        didSet {
            print("didSetSide", oldValue, side)
        }
    }
    var girth : Int {
        set {
            width = newValue / side
        }
        get {
            return width * side
        }
    }
    
    func show() {
        print("width=\(width),side=\(side),girth=\(girth)")
    }
}

func test(_ num : inout Int) {
    num = 20
}
```

### 存储属性

先试试存储属性

```swift
var s = Shape(width: 10, side: 4)
test(&s.width)
s.show()
```

结果输出

```
width=20,side=4,girth=80
```

显然跟我们预想的一样，我们通过`test`函数把`s.width`改成了20，然后这时候四边形的边长就变成了20，周长变成了80

那么这次是不是通过地址传递呢？

通过断点，我们可以看到如下结果
```
    0x10000308b <+91>:  leaq   0x4fe6(%rip), %rdi        ; TestSwift.s : TestSwift.Shape
    0x100003092 <+98>:  callq  0x100003a60               ; TestSwift.test(inout Swift.Int) -> () at main.swift:34
```

这里很明显看到是把结构体`s`的地址值作为参数传进去了。之所以直接传结构体地址进去，是因为`width`是一个存储属性，属性存在在结构体的内存结构中，而且又是第一个属性，所以第一个属性的地址值就是结构体的地址值。假如不是第一个属性，那么就加上偏移值，把该属性的地址传进去。

### 计算属性

接下来我们传一个计算属性进去试试看

```swift
var s = Shape(width: 10, side: 4)
test(&s.girth)
s.show()
```

输出结果为

```
width=5,side=4,girth=20
```

同样也是符合预期的。然后我们分析一下汇编实现

```
// 第1-2步
0x10000307b <+107>: callq  0x1000034d0               ; TestSwift.Shape.girth.getter : Swift.Int at main.swift:24
0x100003080 <+112>: movq   %rax, -0x28(%rbp)
    
// 第3步
0x100003084 <+116>: leaq   -0x28(%rbp), %rdi
0x100003088 <+120>: callq  0x100003a60               ; TestSwift.test(inout Swift.Int) -> () at main.swift:34
    
// 第4步    
0x10000308d <+125>: movq   -0x28(%rbp), %rdi
0x100003091 <+129>: leaq   0x4fe0(%rip), %r13        ; TestSwift.s : TestSwift.Shape
0x100003098 <+136>: callq  0x100003580               ; TestSwift.Shape.girth.setter : Swift.Int at main.swift:21
```

可以看到：
1. 首先系统调用了`getter`方法，拿到计算属性`girth`的值
2. 然后通过`movq`指令把拿出来的值放在了地址`%rbp-0x28`（一个临时变量）中
3. 接下来通过传递地址值的形式，把这个临时变量的地址传了进去，把他指向的值改成了20
4. 然后改完之后拿出结果值调用计算属性`girth`的setter方法（`%rdi`是参数）
5. 最终就实现了修改`width`属性的结果

### 带属性观察器的存储属性

```swift
var s = Shape(width: 10, side: 4)
test(&s.side)
s.show()
```

输出为

```
width=10,side=20,girth=200
```

同样达到预期。然后我们分析一下汇编实现

为了方便理解，这里拆分为两个部分

```
// 第1步
0x10000306d <+93>:  movq   0x500c(%rip), %rax        ; TestSwift.s : TestSwift.Shape + 8
0x100003074 <+100>: movq   %rax, -0x28(%rbp)
// 第2步
0x100003078 <+104>: leaq   -0x28(%rbp), %rdi
0x10000307c <+108>: callq  0x100003a60               ; TestSwift.test(inout Swift.Int) -> () at main.swift:34
...（省略一些setter方法的参数处理）
// 第3步
0x10000308c <+124>: callq  0x100003180               ; TestSwift.Shape.side.setter : Swift.Int at main.swift:12
```

1. 首先，取出结构体地址值+8的地址值（也就是side属性的地址值），赋值给临时变量地址`%rbp-0x28`
2. 取出临时变量的地址值作为函数参数，调用`test`函数，所以`inout`本质依旧是`地址传递`
3. 进入属性的`setter`方法

然后我们`step into`看看`setter`的主要实现

```
/// 第1步
0x1000031be <+62>: callq  0x1000031f0               ; TestSwift.Shape.side.willset : Swift.Int at main.swift:13
0x1000031c3 <+67>: movq   -0x30(%rbp), %rax
0x1000031c7 <+71>: movq   -0x28(%rbp), %rcx
/// 第2步
0x1000031cb <+75>: movq   %rcx, 0x8(%rax)
/// 第3步
0x1000031cf <+79>: movq   -0x38(%rbp), %rdi
0x1000031d3 <+83>: movq   %rax, %r13
0x1000031d6 <+86>: callq  0x100003370               ; TestSwift.Shape.side.didset : Swift.Int at main.swift:16
```

1. 触发了属性观察器的`willset`方法
2. 给真正的`side`的地址指向的值改为20
3. 触发了属性观察器的`didset`方法

所以跟计算属性类似，也是先拿一个临时变量中转调用了`test`方法，等到触发了属性观察器，在两个方法之间才真正拿到中转的临时变量再进行赋值操作

## 其他注意点

- 可变参数不能标记为`inout`
- `inout`参数不能有默认值
- `inout`参数只能传入可以被多次赋值的（var变量，可变数组的元素等）
