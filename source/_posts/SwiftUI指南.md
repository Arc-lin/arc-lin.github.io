---
title: SwiftUI指南
tags:
  - iOS
categories:
  - iOS
abbrlink: f6762f39
date: 2019-12-14 10:20:13
---

iOS 13 SwiftUI 指南

<!--more-->

### 布局方向

#### VStack 垂直布局

默认垂直方向居中布局

```
VStack {
	Text("默认居中")
	Text("Hello, World!")
	Text("Hello, World Again!")
}
```

对齐方向参数可选(`.leading`,`.trailing`,`.center`)
```
VStack(alignment:.leading) {
	Text("左对齐")
	Text("Hello, World!")
	Text("Hello, World Again!")
}
```
	

#### HStack 水平布局

默认水平方向居中布局

```
HStack {
	Text("默认居中")
	Text("Hello, World!")
	Text("Hello, World Again!")
}
```

对齐方向参数可选(`.top`,`.bottom`,`.center`)
```
HStack(alignment:.bottom) {
	Text("左对齐")
	Text("Hello, World!")
	Text("Hello, World Again!")
}
```

### ZStack 前后布局

代码下面内容的盖住上面的内容

默认水平居中&垂直居中

```
ZStack {
	Text("默认居中")
	Text("Hello, World!")
}
```

对齐方向参数可选(`.leading`,`.trailing`,`.top`,`.bottom`,`.topLeading`,`.topTrailing`,`.bottomLeading`,`.bottomTrailing`)

```
ZStack(alignment:.bottom) {
	Text("底部对齐")
	Text("Hello, World!")
}
```

### Padding

内边距，用来撑开你的布局

默认撑开上下左右各16pt

```
ZStack{
	Text("默认居中").padding()
}
```

可以指定哪个位置撑开和数值大小

```
ZStack{
	Text("默认居中").padding(20) // 上下左右均撑开20
}
```

```
ZStack{
	Text("默认居中").padding(.leading: 20) // 左边撑开20，其他同理
}
```

```
ZStack{
	Text("默认居中").padding([.leading,.trailing],50).fixedSize() // 左边和右边都撑开50，其他同理，fixedSize意思等同于UILabel的sizeToFit
}
```

```
ZStack{
	Text("默认居中").padding(.leading, 10).padding(.top, 20) // 左边10，上边20，其他同理
}
```

### Spacer

用来填充空位。

因为SwiftUI不像原来的UI开发，是先设置好frame,再往里面添加东西，相反，他是一种先紧紧包住控件，然后通过padding、spacer等元素去“撑开”视图的思想。所以，Spacer在这里有点类似于UIBarButtonItem里的那个`UIBarButtonSystemItemFlexibleSpace`,就是把东西给撑开。

举个例子

水平界面这时候布局紧紧包裹着Text控件
```
HStack {
	Text("Hello, World!")
}
```

如果这时候加一个Spacer,那么Text控件就会靠左，右边部分会被Spacer把剩余空隙填满

```
HStack {
	Text("Hello, World!")
	Spacer()
}
```

同理如果是`VStack`，写在下面的话，自然就会把Text控件往上顶，然后把剩余屏幕部分填满。

### Image

直接输入图片名就可以引用本地图片
`Image("bg_nuanxin_mask")`

#### resizeable

`Image("bg_nuanxin_mask").resizable()`

把图片撑开

### 隐藏NavigationBar

```
NavigationView {
	ZStack {
		//...
	}
	.navigationBarHidden(true)
	.navigationBarTitle("")
	.navigationBarBackButtonHidden(true)
}
```

#### 这个界面不显示，下个界面要显示导航栏

当前页面声明一个属性
```
 @State private var navBarHidden = true
```

目标页面加一个属性

```
@Binding var navBarHidden : Bool
```

传值过去
```
NavigationLink(destination:xxxx, navBarHidden: $navBarHidden)) {
   xxxxx
}
```

目标页面处理

```
var body: some View {
	WebView(webUrl:"https://www.baidu.com",title: $title)
	.onAppear {
		self.navBarHidden = false
	}
	.onDisappear {
		self.navBarHidden = true
	}
	.navigationBarTitle(Text(title),displayMode: .inline)
}
```

#### 导航栏标题样式

普通
```
.navigationBarTitle(Text(title),displayMode: .inline)
```

特大
```
.navigationBarTitle(Text(title),displayMode: .large)
```

随滚动自动变化
```
.navigationBarTitle(Text(title),displayMode: .automatic)
```

### 需要用到的一些快捷键

cmd + ctrl + 鼠标左键+控件/布局  =  调出菜单
ctrl + i = 代码缩进调整	

待续