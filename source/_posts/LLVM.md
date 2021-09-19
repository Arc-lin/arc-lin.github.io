title: LLVM
author: Arclin
tags:
  - iOS
  - 底层原理
categories:
  - iOS
abbrlink: 6d8a8bc2
date: 2021-09-12 11:11:00
---
本文主要简述LLVM的概念与Clang插件开发

<!-- more -->

## LLVM

- 官网：[https://llvm.org](https://llvm.org)
- LLVM项目是模块化、可重用的`编译器`以及`工具链`技术的集合
- ”LLVM“这个名称不是缩写，是项目全称

## 传统的编译器架构

![4ppCOx.png](https://z3.ax1x.com/2021/09/12/4ppCOx.png)

- Frontend：前端
	- 词法分析、语法分析、语义分析、生成中间代码
 
- Optimizer：优化器
	- 中间代码优化
   
- Backend：后端
	- 生成机器码
    
## LLVM架构

![4pEhkt.png](https://z3.ax1x.com/2021/09/12/4pEhkt.png)

- 不同的前端后端使用统一的中间代码`LLVM Intermediate Representation(LLVM IR)`
- 如果需要支持一种新的编程语言，那么只需要实现一个新的前端
- 如果需要支持一种新的硬件设备，那么只需要实现一个新的后端
- 优化阶段是一个通用的阶段，他针对的是统一的`LLVM IR`，不论是支持新的编程语言，还是支持新的硬件设备，都不需要对优化阶段做需修改
- 相比之下，GCC的前端和后端没分得太开，前端后端耦合在了一起。所以GCC为了支持一门新的语言，或者为了支持一个新的目标平台，就变得相当困难
- LLVM现在被作为实现各种静态和运行时编译语言的通用基础结构（GCC家族，Java,.Net,Python,Ruby,Scheme,Haskell,D等）

### Clang

- Clang是LLVM的一个子项目
- 基于LLVM架构的C/C++/Objective-C编译器前端
- 官网：http://clang.llvm.org/

- 相比于GCC，Clang具有如下优点
	- 编译速度快：在某些平台上，Clang的编译速度显著地快过GCC(Debug模式下编译OC速度比GCC快3倍)
    - 占用内存小：Clang生成的AST所占用的内存是GCC的五分之一左右
    - 模块化设计：Clang采用基于库的模块化设计，易于IDE集成及其他用途的重用
    - 诊断信息可读性强：在编译过程中，Clang创建并保留了大量详细的元数据（metadata），有利于调试和错误报告
    - 设计清晰简单，容易理解，易于扩展增强 
    
### Clang与LLVM

 ![WX20210912-142017.png](https://i.loli.net/2021/09/12/P7Z2sTB6ifOt4XM.png)

 ![WX20210912-142026.png](https://i.loli.net/2021/09/12/EZ9hnywmdQAX3LK.png)
 
 IR：中间代码
 
 
## OC源文件的编译过程
 
 - 命令行查看编译的过程：`$ clang -ccc-print-phases main.m`
 
 ```
arclin@ArcdeMacBook-Pro TestObjC % clang -ccc-print-phases main.m 
               +- 0: input, "main.m", objective-c
            +- 1: preprocessor, {0}, objective-c-cpp-output
         +- 2: compiler, {1}, ir
      +- 3: backend, {2}, assembler
   +- 4: assembler, {3}, object
+- 5: linker, {4}, image
6: bind-arch, "x86_64", {5}, image
 ```
 
  preprocessor: 预处理器，处理宏定义，展开引入的头文件内容等

  complier: 编译，编译成ir中间代码

  backend: 后端，转成汇编代码

  assemler: 汇编，转成目标代码

  linker: 链接，链接动态库、静态库等

  bind-arch: 绑定当前处理器架构
  
- 查看preprocesser(预处理)的结果：`$ clang -E main.m`

- 词法分析，生成Token：`$ clang -fmodules -E -Xlang -dump-tokens main.m`

- 语法分析，生成语法树（AST，Abstract Syntax Tree）：`$ clang -fmodules -fsyntax-only -Xclang -ast-dump main.m`

## 词法分析、语法树

词法分析，生成Token： `$ clang -fmodules -E -Xclang -dump-tokens main.m`

[![483bNR.png](https://z3.ax1x.com/2021/09/19/483bNR.png)](https://imgtu.com/i/483bNR)

语法分析，生成语法树（AST，Abstract Syntax Tree）： `$ clang -fmodules -fsyntax-only -Xclang -ast-dump main.m`

[![483d9P.png](https://z3.ax1x.com/2021/09/19/483d9P.png)](https://imgtu.com/i/483d9P)

## LLVM IR

LLVM IR 有三种表现形式

- text：便于阅读的文本格式，类似于汇编语言，拓展名`.ll`，`$ clang -S -emit-llvm main.m`

- memory：内存格式

- bitcode：二进制格式，拓展名`.bc`，`$ clang -c -emit-llvm main.m`

IR基本语法

- 注释以分号开头
- 全局标识以@开头，局部标识符以%开头
- alloca, 在当前函数栈帧中分配内存
- i32，32bit，4个字节的意思
- align，内存对齐
- store，写入数据
- load，读取数据

官方语法参考

[https://llvm.org/docs/LangRef.html](https://llvm.org/docs/LangRef.html)


## Clang插件开发

我们可以通过开发Clang插件来对我们的代码进行静态分析，大概步骤是我们先把LLVM源码和clang源码下载到本地，然后进行编译，编译完之后我们就可以得到我们自己的编译器，然后把我们的clang插件放入指定目录，然后在Xcode里面把Xcode原来的编译器配置为我们自己的编译器，然后就可以使用我们的Clang插件了。

举个例子，通过Clang我们可以对类名命名进行一些约束，比如NSString不用copy修饰的时候就警告一下。

[![48lKER.png](https://z3.ax1x.com/2021/09/19/48lKER.png)](https://imgtu.com/i/48lKER)

接下来我们讲解一下配置和开发步骤

### 下载LLVM源码

可以直接在github上面下载到源码，目前最新版本号为12.0.1，直接点击页面的`Source Code`下载，[github地址](https://github.com/llvm/llvm-project/releases/tag/llvmorg-12.0.1)

### 下载Clang源码

同样也是[这个地址](https://github.com/llvm/llvm-project/releases/tag/llvmorg-12.0.1)，目前的最新版本是12.0.1，点击`clang-12.0.1.src.tar.xz`下载

下载后解压，文件夹命名为clang，把文件夹置入LLVM源码目录`llvm`文件夹的`tools`文件夹中

### 安装cmake和ninja（先安装brew，https://brew.sh）

使用cmake和ninja工具是为了让编译速度更快

`$ brew install cmake`
`$ brew install ninja`

ninja如果安装失败，可以直接从[github]( https://github.com/ninja-build/ninja/releases)获取release版（ninja-mac.zip）放入`/usr/local/bin`中


### 编译

#### 使用ninja模板进行编译

在llvm源码目录内新建一个文件夹命名为`llvm_build`目录备用，用来放置ninja模板，然后在新建一个`llvm_release`文件夹，用来放置编译后的成品

```
$ cd llvm_build
$ cmake -G Ninja ../llvm -DCMAKE_INSTALL_PREFIX=../llvm_release
```

命令执行完成后就`cd llvm_build`进入模板文件夹，然后依次执行以下命令

```
$ ninja
$ ninja release
```

之后就可以在`llvm_release`内看到编译成品了


#### 使用Xcode进行编译

也可以生成Xcode项目再进行编译，但是速度很慢（可能需要1个多小时）

在llvm源码目录内新建一个文件夹命名为`llvm_xcode`目录备用

```
$ cd llvm_xcode
$ cmake -G Xcode ../llvm
```

生成完之后打开`llvm_xcode`内的`LLVM.xcodeproj`

选择自动生成Scheme

[![430RxA.png](https://z3.ax1x.com/2021/09/19/430RxA.png)](https://imgtu.com/i/430RxA)

选择`ALL_BUILD` Scheme 然后就可以Cmd+R开始编译了

[![43022d.png](https://z3.ax1x.com/2021/09/19/43022d.png)](https://imgtu.com/i/43022d)

编译后的成品在`llvm_xcode/Debug/bin`中

### 创建Clang插件

在llvm源码的`/llvm/tools/clang/tools`文件夹内，新建一个文件夹，命名为`my-plugin`(举例名字)

在同目录下打开文件`CMakeLists.txt`，在最后一行写入`add_clang_subdirectory(my-plugin)`后保存

在`my-plugin`文件夹内新建一个文件命名为`MyPlugin.cpp`，再新建一个`CMakeLists.txt`文件到该文件夹内

编辑`CMakeLists.txt`文件，写入

```
add_llvm_library(MyPlugin MODULE BUILDTREE_ONLY MyPlugin.cpp)
```

表示可加载模块

如果有很多cpp文件的话，那么也可以这么写
```
add_llvm_library( MyPlugin MODULE BUILDTREE_ONLY 
MyPlugin.cpp
MyPlugin2.cpp
MyPlugin3.cpp
MyPlugin4.cpp
)
```

### 编写Clang插件

因为在文本编辑器中编辑c++代码很麻烦，所以我们一般会生成一个Xcode模板（也就是上面提到那个`使用Xcode进行编译`的Xcode模板）帮我们辅助编写C++代码

所以我们在llvm源码目录的`llvm_xcode`文件夹内执行一下`cmake -G Xcode ../llvm`命令，就可以得到一个Xcode模板，打开工程之后，就可以看到我们的插件目录

[![4369gg.png](https://z3.ax1x.com/2021/09/19/4369gg.png)](https://imgtu.com/i/4369gg)

#### 基本结构

```
/// 必要的头文件，主要用来解析语法树
#include <iostream>
#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/ASTMatchers/ASTMatchers.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendPluginRegistry.h"

using namespace clang;
using namespace std;
using namespace llvm;
using namespace clang::ast_matchers;

namespace MyPlugin {

    class MyASTConsumer : public ASTConsumer {
    public:
        /// 每当生成一棵语法树就会调用这个方法
        void HandleTranslationUnit(ASTContext &Ctx) {
            cout << "MyPlugin-HandleTranslationUnit" << endl;
        }
    };

    class MyAction : public PluginASTAction {
    public:
        /// 一定要重写的两个父类方法，指定Consumer
        unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &ci, StringRef InFile) {
            return unique_ptr<MyASTConsumer> (new MyASTConsumer);
        }
        
        bool ParseArgs(const CompilerInstance &CI, const std::vector<std::string> &arg) {
            return true;
        }
    };
}

/// 注册插件
static FrontendPluginRegistry::Add<MyPlugin::MyAction>
X("MyPlugin", "The MyPlugin is my first clang-plugin.");
```

编译`MyPlugin` Scheme

[![481kdA.png](https://z3.ax1x.com/2021/09/19/481kdA.png)](https://imgtu.com/i/481kdA)


最后得到成品`MyPlugin.dylib`

[![481eRf.png](https://z3.ax1x.com/2021/09/19/481eRf.png)](https://imgtu.com/i/481eRf)

### 使用Clang插件

`Show in finder`取出`MyPlugin.dylib`之后，我们新建一个测试工程

在新建的Xcode项目中指定加载插件：`Build Settings > OTHER_CFLAGS`，双击输入框后输入

`-Xclang -load -Xclang 动态库路径 -Xclang -add-plugin -Xclang 插件名称`，回车

[![43XojJ.png](https://z3.ax1x.com/2021/09/19/43XojJ.png)](https://imgtu.com/i/43XojJ)

因为Xcode自带的编译器不允许加载插件，所以我们使用刚才自己编译好的编译器


首先下载[Xcode破解插件](https://github.com/weizhangCoder/XcodeHacking)

进入目录`XcodeHacking/HackedClang.xcplugin/Contents/Resources`

修改`HackedClang.xcspec`

```
ExecPath = "/opt/llvm/llvm_build/bin/clang";
```

改为我们刚才编译好的clang的全路径

```
ExecPath = "/Users/arclin/Downloads/llvm-project-llvmorg-12.0.1/llvm-release/bin/clang";
```

然后在XcodeHacking目录下进行命令行，

将XcodeHacking的内容剪切到Xcode内部

```
$ sudo mv HackedClang.xcplugin `xcode-select -p`/../PlugIns/Xcode3Core.ideplugin/Contents/SharedSupport/Developer/Library/Xcode/Plug-ins
$ sudo mv HackedBuildSystem.xcspec `xcode-select -p`/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Specifications
```

这时候Xcode就应该有多一个编译器可选项，我们选择`Clang LLVM Trunk`

[![48lXI1.png](https://z3.ax1x.com/2021/09/19/48lXI1.png)](https://imgtu.com/i/48lXI1)


然后就可以Clean一下后编译进行测试。

自己在测试的时候发生了一些报错的问题（可能我是用的M1笔记本的原因），可以修改`Build System`的值为`Legacy Build System`解决

[![48lsxS.png](https://z3.ax1x.com/2021/09/19/48lsxS.png)](https://imgtu.com/i/48lsxS)

如果发生了`CADisplayLink' is unavailable: not available on macOS`的问题，那尝试新建一个Mac项目


最后贴出完整的插件代码仅供参考

```
#include <iostream>
#include "clang/AST/AST.h"
#include "clang/AST/DeclObjC.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/ASTMatchers/ASTMatchers.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Frontend/FrontendPluginRegistry.h"

// 声明使用命名空间
using namespace clang;
using namespace std;
using namespace llvm;
using namespace clang::ast_matchers;

// 插件命名空间
namespace MyPlugin {

    // 第三步：扫描完毕回调
    // 4、自定义回调类，继承自MatchCallback
    class MyMatchCallback : public MatchFinder::MatchCallback {

    private:
        // CI传递路径：MyASTAction类中的CreateASTConsumer方法参数 -> MyASTConsumer的构造函数 -> MyMatchCallback的私有属性，通过构造函数从MyASTConsumer构造函数中获取
        CompilerInstance &CI;

        // 判断是否是自己的文件
        bool isUserSourceCode(const string fileName) {
            // 文件名不为空
            if (fileName.empty()) return false;
            // 非Xcode中的代码都认为是用户的
            if (0 == fileName.find("/Applications/Xcode.app/")) return false;
            return true;
        }

        // 判断是否应该用copy修饰
        bool isShouldUseCopy(const string typeStr) {
            // 判断类型是否是 NSString / NSArray / NSDictionary
            if (typeStr.find("NSString") != string::npos ||
                typeStr.find("NSArray") != string::npos ||
                typeStr.find("NSDictionary") != string::npos) {
                return true;
            }
            return false;
        }

    public:
        // 构造方法
        MyMatchCallback(CompilerInstance &CI):CI(CI) {}

        // 重载run方法
        void run(const MatchFinder::MatchResult &Result) {
            // 通过Result获取节点对象，根据节点id("objcPropertyDecl")获取(此id需要与MyASTConsumer构造方法中bind的id一致)
            const ObjCPropertyDecl *propertyDecl = Result.Nodes.getNodeAs<ObjCPropertyDecl>("objcPropertyDecl");
            // 获取文件名称（包含路径）
            string fileName = CI.getSourceManager().getFilename(propertyDecl->getSourceRange().getBegin()).str();
            // 如果节点有值 && 是用户文件
            if (propertyDecl && isUserSourceCode(fileName)) {
                // 获取节点的类型，并转成字符串
                string typeStr = propertyDecl->getType().getAsString();
                // 节点的描述信息
                ObjCPropertyAttribute::Kind attrKind = propertyDecl->getPropertyAttributes();
                // 应该使用copy，但是没有使用copy
                if (isShouldUseCopy(typeStr) && !(attrKind & ObjCPropertyAttribute::kind_copy)) {
                    // 通过CI获取诊断引擎
                    DiagnosticsEngine &diag = CI.getDiagnostics();
                    // Report 报告
                    /**
                     错误位置：getLocation 节点位置
                     错误：getCustomDiagID（等级，提示）
                     DiagnosticsEngine::Warning 警告
                     DiagnosticsEngine::Error 错误
                     */
                    diag.Report(propertyDecl->getLocation(), diag.getCustomDiagID(DiagnosticsEngine::Warning, "%0 - 推荐使用copy修饰该属性"))<< typeStr;
                }
            }
        }
    };

    // 第二步：扫描配置完毕
    // 3、自定义MyASTConsumer，继承自抽象类 ASTConsumer，用于监听AST节点的信息 -- 过滤器
    class MyASTConsumer : public ASTConsumer {
    private:
        // AST 节点查找器（过滤器）
        MatchFinder matcher;
        // 回调对象
        MyMatchCallback callback;

    public:
        // 构造方法中创建MatchFinder对象
        MyASTConsumer(CompilerInstance &CI):callback(CI) { // 构造即将CI传递给callback
            // 添加一个MatchFinder，每个objcPropertyDecl节点绑定一个objcPropertyDecl标识（去匹配objcPropertyDecl节点）
            // 回调callback，其实是在CJLMatchCallback里面重写run方法（真正回调的是回调run方法）
matcher.addMatcher(objcPropertyDecl().bind("objcPropertyDecl"), &callback);
        }

        // 重载两个方法 HandleTopLevelDecl 和 HandleTranslationUnit

        // 解析完毕一个顶级的声明就回调一次（顶级节点，即全局变量，属性，函数等）
        bool HandleTopLevelDecl(DeclGroupRef D) {
//            cout<<"正在解析..."<<endl;
            return true;
        }

        // 当整个文件都解析完毕后回调
        void HandleTranslationUnit(ASTContext &Ctx) {
//            cout<<"文件解析完毕！！！"<<endl;
            // 将文件解析完毕后的上下文context（即AST语法树） 给 matcher
            matcher.matchAST(Ctx);
        }
    };

    //2、继承PluginASTAction，实现我们自定义的MyASTAction，即自定义AST语法树行为
    class MyASTAction : public PluginASTAction {
    public:

        // 重载ParseArgs 和 CreateASTConsumer方法

        /*
         解析给定的插件命令行参数
         - param CI 编译器实例，用于报告诊断。
         - return 如果解析成功，则为true；否则，插件将被销毁，并且不执行任何操作。该插件负责使用CompilerInstance的Diagnostic对象报告错误。
         */
        bool ParseArgs(const CompilerInstance &CI, const std::vector<std::string> &arg) {
            return true;
        }

        // 返回自定义的MyASTConsumer对象，抽象类ASTConsumer的子类
        unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI, StringRef InFile) {
            /**
             传递CI
             CI用于：
             - 判断文件是否是用户的
             - 抛出警告
             */
            return unique_ptr<MyASTConsumer>(new MyASTConsumer(CI));
        }
    };
}

// 第一步：注册插件，并自定义MyASTAction类
// 1、注册插件
static FrontendPluginRegistry::Add<MyPlugin::MyASTAction> X("MyPlugin", "this is MyPlugin");
```


> 参考：https://juejin.cn/post/7004633055012864031