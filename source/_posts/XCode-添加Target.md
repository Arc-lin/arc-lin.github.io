title: XCode 添加Target
author: Arclin
tags:
  - iOS
  - XCode
categories:
  - iOS
date: 2018-02-18 22:08:00
---
在区分开发环境和测试环境或生产环境的时候经常需要在XCode 添加Target, 所以在此记录一下

<!-- more -->

1. Duplicate target
2. Change DisplayName & Bundle Identifier
3. A copy-info.plist，默认生成在程序环境根目录，也就是`A.xcodeproj`的同级目录中，如果想放到里层（比如与`A-info.plist`放在同级目录），可以先在Xcode删除`A copy-info.plist`索引，然后拷贝文件到制定目录中，然后更名为`B-info.plist`，在add到project中。在`Project`的`Build Settings`中，修改`Info.plist` File选项为`B-info.plist`的目录（相对路径）,这样就可以看到Info页了（就是B-info.plist），接着修改`ProductName`和`Bundle identifier`，使之成为另一个app。`Prefix Header的路径`，视具体需求而定是否要修改，如果两个target可以公用同一个`Prefix Header`，那么就不需要修改这里的路径
4. 修改scheme，在调试的Stop按钮边上，我们可以选择本工程中所有的target来做编译，如果不修改，在这里选择出来的名字就是A copy，为了与新建的target统一起来，同样也要修改这里的名字。点击scheme选择区，然后选Manager Scheme，找到A copy，然后改成你需要的名字，比如B
5. 生成一个新的target，一定会与原target有区别，这里可以定义预编译宏，来区分两个版本的不同代码，预编译宏可以在Build Settings中Preprocessor Macros定义，比如在我们新建的target B中定义预编译宏MACRO，然后在代码中通过
```
	#if defined (MACRO)
	//target  B需要执行的代码
	#else
	//target A需要执行的代码
	#endif
```
来区分
6. 其他：Build Phases（各target编译所包含的内容，需要注意的是，如果创建了target B后，再往A里面添加资源或文件，target B中不会自动增加这些资源，需要手动添加）
	- Compile Sources
	需要编译的代码文件
	- Link Binary With Libraries
	编译所依赖的库
	- Copy Bundle Resources
	编译需要的资源
	每个target可以根据具体需要增减里面的内容
