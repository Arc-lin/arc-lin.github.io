---
title: 纯Swift热修方案
tags:
  - Swift
  - iOS
categories:
  - iOS
abbrlink: 8af9107c
date: 2025-06-03 17:50:28
---

本文主要讲述纯Swift代码的热更方案调研

<!-- more -->

## 原理分析
先从Swift的方法派发原理进行分析，是否存在hook纯Swift方法的可能性

### 直接派发

编译时确定方法地址，场景如下：

1. 值类型（Struct 和 Enum）：值类型的方法默认使用直接派发。
2. final 方法和类：被 final 修饰的方法或类无法被重写或继承，因此使用直接派发。
3. 全局函数和静态方法：这些方法在编译时就能确定实现，使用直接派发

如下代码：

```
public class STestViewController: UIViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        let animal = Animal(legs: 2)
        animal.eat()
    }
}

struct Animal {
    var legs: Int
    func eat() {
        print("eat")
    }
}
```
调用animal.eat()的时候，访问地址0x109ade990，
![](https://i0.hdslb.com/bfs/openplatform/22bd6f8afb626fe5cf3975774bb2a2a0d5ace0fd.png)

因为是直接确定了方法地址，所以理论上不可能运行时修改这个地址改为我们的补丁方法，但是可以采用插桩方案（查看下面的”方案选型“）

### 函数表派发

运行时通过虚函数表（vtable）动态查找方法地址，场景：类的非 final 实例方法。
简单例子：

```
class Person {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func walk() {
        print("\(name) walk")
    }
}
```

![](https://i0.hdslb.com/bfs/openplatform/b322f3b9f4edfeea4fc4d5a607780c5c342d860b.png)

对应的汇编代码如下

![](https://i0.hdslb.com/bfs/openplatform/27b50036ed9239b8e5eb76c7ed93ff0d69159995.png)

一层层读取发现r13寄存器是Person对象，传递给rax寄存器

![](https://i0.hdslb.com/bfs/openplatform/4ac7ef48c4ae371a7c15701a8c9ff655a520918e.png)

*0x78(%rax)： 从 %rax 指向的地址加上偏移量 0x78 的位置读取一个地址，并调用该地址指向的函数。
0x78偏移量指向的是虚表中的walk方法的地址

这里的0x600000255778就是walk方法地址。
由此可以确定，要是能提前修改虚表里面的方法地址，就可以做到方法替换
所以尝试，虚表地址替换方案

### 消息派发

即objc_msgSend，场景：@objc dynamic 方法、继承自 NSObject 的类、与 Objective-C 交互的代码
业界有很多成熟方案如JSPatch、MongoFix等，这里不展开讨论

## 方案选型

###插桩方案

参考SOT的方案，因为官网已经挂了，所以我们从网上收集到一些他曾经存在的证据和一些截图来分析他的实现方案

文章1：https://zhuanlan.zhihu.com/p/654079130 该文章提到“SOT的工作原理是在编译流程中进行代码注入，为函数增加跳板逻辑代码，这样就能够根据需要跳转到虚拟机中运行补丁代码。”

截图1：从该截图可以看出，SOT会给所有Swift函数插桩，在函数最前面插入判断语句 （从cmp、jz汇编指令可以看出），判断当前方法是否存在于数组中，如果存在就跳转到插桩函数执行，如果不存在就跳转到1007079F3执行原函数，最后调用1007079FB出栈。
中间的call j__sotdlg_475573651764395585应该就是跳转到虚拟机执行补丁方法

![](https://i0.hdslb.com/bfs/openplatform/720107ba6407713ab6b872cae4d50b374fd07d5c.png)


所以我们先看插桩实现是否可行，是否真的可以一次性给所有方法（OC、Swift）插桩，先通过LLVM自带的代码覆盖率插桩进行快速验证（LLVM文档）

Other C Flags添加参数`-sanitize-coverage=func,trace-pc-guard`

![](https://i0.hdslb.com/bfs/openplatform/649c8ece6b26f9e8081109dd19db9396b4cf0e51.png)

Other Swift Flags添加参数`-sanitize-coverage=func` 和 `-sanitize=undefined`

![](https://i0.hdslb.com/bfs/openplatform/1de410d8ba52156213590cc0aca07da4958570a1.png)

找个地方实现插桩方法

```
void __sanitizer_cov_trace_pc_guard_init(uint32_t *start, uint32_t *stop) {
  static uint64_t N;  // Counter for the guards.
  if (start == stop || *start) return;  // Initialize only once.
  printf("INIT: %p %p\n", start, stop);
  for (uint32_t *x = start; x < stop; x++)
    *x = ++N;  // Guards should start from 1.
}

void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
  void *PC = __builtin_return_address(0);
  Dl_info info;
  dladdr(PC, &info);
  printf("fname=%s \nfbase=%p \nsname=%s\nsaddr=%p \n\n",info.dli_fname,info.dli_fbase,info.dli_sname,info.dli_saddr);
}
```

然后我们随便写个Demo, 比如写个tableView, 然后再didSelect回调里面打断点，进入汇编页面，看看插桩是否成功
![](https://i0.hdslb.com/bfs/openplatform/f8d67de756ee0b7c24ea24607247e3e4fc5393ed.png)

可以看出，插桩成功，程序在调用didSelect之前，会先调用`__sanitizer_cov_trace_pc_guard`
简单分析汇编代码插入函数位置，可以得到每个“代码块”都有对应的插桩函数

![](https://i0.hdslb.com/bfs/openplatform/9c1748ace00bcb46d3396caaa2b05bde696673ec.png)


再对Swift插桩进行验证，同样发现了插桩代码`__sanitizer_cov_trace_pc_guard`
![](https://i0.hdslb.com/bfs/openplatform/0444804fdca84a209ca42464da2bb27d8ef47854.png)
![](https://i0.hdslb.com/bfs/openplatform/3bfebb3f119177eaf3f37e59cdf7850a7b00e98a.png)

控制台输出

![](https://i0.hdslb.com/bfs/openplatform/d638fa5b37eafc0ca7b5abe4f1d8094b23a36b62.png)

由此可以得出结论，OC与Swift都可以通过插桩方式拿到回调
当然代码覆盖率这个插得太多了，实际实现的时候我们自己写clang插件在头尾插桩就可

于是可以做如下尝试，结合JSPATCH实现原理进行操作

```
struct Animal {
    var legs: Int
    func eat() {
         /// 插桩代码开始
         if "Animal.eat" in Start_PATCH_Array {
            id returnValue = nil
            RunJavaScipt(self, xxxx, &returnValue)
            return returnValue
         }
         /// 插桩代码结束
        print("eat")
          /// 插桩代码开始
         if "Animal.eat" in END_PATCHArray {
             id returnValue = nil
             RunJavaScipt(self, xxxx)
             return returnValue
         }
         /// 插桩代码结束
    }
}
```

处理补丁方法void返回值可以参考以下方法，参考文档[https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html]()

```
const char* retType = getReturnType();
if (strcmp(retType, @encode(void)) == 0) {
    return;
} else {
    return patch();
}
```

但是这种方案不是真正的热修复方案，反而是作为全埋点方案更为合适。暂时保留方案待定

### 虚表地址替换
以此为例

```
class Person {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func walk() {
        print("\(name) walk")
    }
}
```

首先拿到二进制文件进行Mach-O分析，或者通过nm命令，拿到walk方法的名字
![](https://i0.hdslb.com/bfs/openplatform/d64507acc3e9ab23485364906fc4f311c64de2b6.png)

编写代码

```
#include "patch.h"
#include "dlfcn.h"
#import <Foundation/Foundation.h>

void new_walk(void) {
    printf(" -- new walk -- ");
}

void write_memory(void **ptr, void *value) {
    *ptr = value;
}

void *get_method_address(void) {
    return &new_walk;
}

void *get_class_meta_address(void) {
    Class aclass = NSClassFromString(@"DynamicFrameworkDemo.Person");
    return (__bridge void *)aclass;
}

long get_method_offset(void *class) {
    void * raw_method_address = dlsym(RTLD_DEFAULT, "$s20DynamicFrameworkDemo6PersonC4walkyyF");
    for (long i=0; i<1024; i++) {
        if (*(long *)(class+i) == (long)raw_method_address) {
            return i;
        }
    }
    return -1;
}

void patch(void) {
    void *method_address = &new_walk; /// 获取补丁方法的地址
    void *class_meta_address = get_class_meta_address(); // 获取类对象元信息地址
    long offset = get_method_offset(class_meta_address); // 循环遍历获取偏移量
    write_memory(class_meta_address+offset, method_address); /// 函数指针替换
}
```

![](https://i0.hdslb.com/bfs/openplatform/8ce71b55d0718fce5b1cd4617a25cdad7dcaa606.png)

成功替换实现
可以使用dlsym或者symdl进行C函数指针生成

Todo: 考虑结合MongoFix动态下发解释能力，实现热修复能力

## 总结
以上方案均无法过审，只能本地调试使用
1. 插桩方案可以结合JSPatch实现原理进行替换
2. 虚表地址替换方案可以结合MongoFix能力进行实现