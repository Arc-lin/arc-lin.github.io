---
title: Swift6新特性
abbrlink: feb7c155
date: 2024-07-09 21:53:21
tags:
	- Swift
categories:
	- iOS
---

本文旨在介绍Swift6的一些新技术以及设计方法。

<!-- more -->

# 语法糖
## if、switch 作为表达式之一
> swift5.9

比如在一段网络请求方法中，当 paramsAsQuery为true的时候，需要将参数作为query插入到url中而不是放在httpBody里面
以前可能会这么写

```
 var urlString: String?
 if paramsAsQuery,let query = params?.toQueryParameters() {
      urlString = "\(urlString)?\(query)"
 } else {
      urlString = url
 }
```

现在可以这么写

```
var urlString = if paramsAsQuery, let query = params?.toQueryParameters() {
    "\(url)?\(query)"
} else {
    url
}
```

除了if, switch也一样可以，用法同理

## 正则表达式

> Swift 5.7

有时需要判断分支是否符合以下格式：union/x.xx/union_x.xx_feature 或 union/x.xx/union_x.xx_maint，用来判断是否是主分支，会使用到正则表达式

方法如下

```
let regex = try? NSRegularExpression(pattern: "^union\\/\\d{1,}\\.\\d{1,}\\/union_\\d{1,}\\.\\d{1,}_feature$", options: [])
guard let results = regex?.matches(in: originStr, options: [], range: NSRange(location: 0, length: originStr.count)) else {
    return nil
}
let matchItems = results.map {
    if let range = Range($0.range, in: originStr) {
        return "\(originStr[range])"
    }
    return ""
}
return matchItems
```

正则本身就复杂，还要考虑字符反转义，所以就很麻烦
Swift 5.7 之后，正则迎来了史诗级提升，上述代码可以简化为

```
let pattern = /^union\/\d{1,}\.\d{1,}\/union_\d{1,}\.\d{1,}_feature$/
guard let matchName = name.firstMatch(of: pattern)?.output else {
    return false
}
return matchName
```

用 /.../ 两个斜杠的方式就可以构建一个正则表达式
如果觉得正则表达式太复杂，也可以使用DSL一样的构建方式构建正则对象

```
 let regex = Regex {
    "union/"
    One(.digit)
    "."
    OneOrMore(.digit)
    "/union_"
    One(.digit)
    "."
    OneOrMore(.digit)
    "_feature"
}

guard let matchName = name.firstMatch(of: regex)?.output else {
    return false
}
return matchName
```

效果同上

# Concurreny

## 协程

协程两个要素
1. 用await表示等待，如果异步函数返回正常则继续执行
2. 用try抛出异常，如果异步函数返回错误则执行catch逻辑


举个例子，批量拉取代码，每个目录都需要执行一下git pull, 使用协程之前需要递归遍历一个个拉取

```
 func pull(workspace: LocalWorkspace, components: [Component], index: Int = 0, operation: Operation, complete: ((Component?, Bool)-> Void)?) {
    if index >= components.count {
        complete?(nil, true)
        return
    }
    let component = components[index] 
    pull(component: component) { [weak self] success, errorMsg, comp in
        operation.complete.append(Result(name: comp.name, success: success, content: success ? "成功": errorMsg))
        operation.percent = CGFloat(operation.complete.count) / CGFloat(components.count)
        if success {
            complete?(comp, true)
            self?.pull(workspace: workspace, components: components, index: index + 1 , operation: operation, complete: complete)
        } else {
            complete?(comp, false)
        }
    }
}
```

使用协程之后

```
func pull(workspace: LocalWorkspace, components: [Component], operation: Operation) async {
    for component in components {
        do {
            try await pull(component: component)
            operation.complete.append(Result(name: component.name, success: true, content: "成功"))
        } catch {
            operation.complete.append(Result(name: component.name, success: false, content: error.localizedDescription))
        }
        operation.percent = CGFloat(operation.complete.count) / CGFloat(components.count)
        await MainActor.run {
            updateComponent(component)
            currentOperation = operation
        }
    }
}
```

当然上面的执行还只是串行的效果，如果需要并行，可以简单修改

```
func pull(workspace: LocalWorkspace, components: [Component], operation: Operation) async {
    await withTaskGroup(of: String.self) { group in
        for component in components {
            group.addTask {
                do {
                    try await self.pull(component: component)
                    operation.complete.append(Result(name: component.name, success: true, content: "成功"))
                } catch {
                    operation.complete.append(Result(name: component.name, success: false, content: error.localizedDescription))
                }
                operation.percent = CGFloat(operation.complete.count) / CGFloat(components.count)
                await MainActor.run {
                    self.updateComponent(component)
                    self.currentOperation = operation
                }
                return component.name
            }
        }
        for await value in group {
            print("\(value)拉取完成")
        }
    }
}
```

拓展一下，如果不是数组类型的任务并发，可以使用async let方式使用控制并发，如下

```
func fetchUserData() async {
    do {
        async let profile = fetchUserProfile()
        async let posts = fetchUserPosts()

        // 并行等待两个异步操作的结果
        let userProfile = try await profile
        let userPosts = try await posts

        print("User Profile: \(userProfile)")
        print("User Posts: \(userPosts)")
    } catch {
        print("Error: \(error)")
    }
}

Task {
    await fetchUserData()
}
```

使用MainActor替代主线程回调
有时候我们需要刷新单个工作区，需要重新查看当前工作区的所有组件的状态，可以调一个全局异步子线程去查询然后主线程回调，可以这么写

```
func reloadWorkspace(_ workspace: LocalWorkspace) {
    workspace.isLoading = true
    DispatchQueue.global().async {
        var newWpss: [LocalWorkspace] = []
        for wps in self.workspaceViewModel.workSpaces {
            if wps.path == workspace.path {
                let path = workspace.path
                let name = (path as NSString).lastPathComponent
                do {
                    var components = try Component.parseComponents(workspace: path).map {
                        let comp = Component($0)
                        self.updateComponent(comp)
                        return comp
                    }
                    components = components.sorted { comp1, comp2 in
                        return (comp1.unPushCount + comp1.unPullCount) > (comp2.unPushCount + comp2.unPullCount)
                    }
                    let workspace = LocalWorkspace(name: name, path: path, components: components)
                    newWpss.append(workspace)
                } catch {
                    
                }
            } else {
                newWpss.append(wps)
            }
        }
        DispatchQueue.main.async {
            self.workspaceViewModel = ComponentListViewModel(workSpaces: newWpss)
        }
    }
}
```

通过使用@MainActor， 再将读取子线程修改到读取文件的那部分，那可以简单许多

```
func reloadWorkspace(_ workspace: LocalWorkspace) {
        Task { @MainActor in
            workspace.isLoading = true
            for wps in self.workspaceViewModel.workSpaces where wps.path == workspace.path {
                do {
                    let baseComponents = try await Component.parseComponents(workspace: path)
                    var components = baseComponents.map {
                        let comp = Component($0)
                        self.updateComponent(comp)
                        return comp
                    }
                    components = components.sorted { comp1, comp2 in
                        return (comp1.unPushCount + comp1.unPullCount + comp1.unCommitCount) > (comp2.unPushCount + comp2.unPullCount + comp2
                            .unCommitCount)
                    }
                    workspace.components = components
                    workspace.isLoading = false
                } catch {
                    print(error)
                }
            }
            self.workspaceViewModel = ComponentListViewModel(workSpaces: self.workspaceViewModel.workSpaces)
        }
    }
```

系统会自动将Task里面包含的部分都强制在主线程执行
@MainActor除了可以修饰闭包之外，还可以直接写在方法前面，表示该方法都是在主线程执行的， 或者写在类或者结构体前面，这表示强制要求该类的方法或成员属性必须在主线程中执行或进行读写操作。
提问：下面这串代码最后会怎么输出？

```
@MainActor
class TestClass {
    var testItem: String = "1" {
        didSet {
            print("访问的testItem在: \(Thread.current)")
        }
    }
    
    func globalThread() {
        print(Thread.current)
        testItem = "123"
    }
}

DispatchQueue.global().async {
    print("当前线程111：\(Thread.current)")
    Task {
        print("当前线程222：\(Thread.current)")
        let item = await TestClass()
        await item.globalThread()
        print("当前线程333：\(Thread.current)")
    }
    print("当前线程444：\(Thread.current)")
}
```

结果：

```
当前线程111：<NSThread: 0x600001700640>{number = 4, name = (null)}
当前线程222：<NSThread: 0x60000170cbc0>{number = 9, name = (null)}
当前线程444：<NSThread: 0x600001700640>{number = 4, name = (null)}
<_NSMainThread: 0x600001708240>{number = 1, name = main}
访问的testItem在: <_NSMainThread: 0x600001708240>{number = 1, name = main}
当前线程333：<NSThread: 0x60000170cbc0>{number = 9, name = (null)}
```

## 数据竞争（Data Race）
在循环执行多个仓库的拉取或者推送的时候，需要看到对应进度以及成功或者失败的状态，失败的话要允许显示失败信息

其中，pull操作本质上是fetch + merge 的流程，fetch本质是一个文件下载的流程，他的进度回调方法会在子线程
所以当多个仓库并发操作的时候，这里就会存在多个子线程同时更改Progress的情况，所以这里我们用actor避免数据竞争情况
actor : 属于引用类型，类似class但是不可继承
定义一个actor, 存储操作类型，已经完成的组件及其结果，还有当前进度

```
  actor Operation {
    private(set) var action: Component.Action
    private(set) var complete: [Result] = []
    private(set) var percent: CGFloat = 0.0
    
    init(action: Component.Action) {
        self.action = action
    }
    
    func addComplete(_ result: Result) {
        complete.append(result)
    }
    
    func updatePercent(_ newValue: CGFloat) {
        percent = newValue
    }
}
```

值得注意的是，actor里面的方法和属性都需要通过await读写

在dataProvider定义属性，提供给SwiftUI渲染, 当数据更新的时候，调用updateProgress方法更新数据进而更新UI

```
@Published var progress: CGFloat = 0.0 
@Published var completeCount: Int = 0
@Published var totalCount: Int = 0
@Published var title: String?
@Published var results: [Result] = []

func updateProgress() async {
    guard let currentOperation = self.currentOperation, await currentOperation.action.components.count > 0 else { return }
    progress = CGFloat(await currentOperation.complete.count) / CGFloat(await currentOperation.action.components.count)
    completeCount = await currentOperation.complete.count
    totalCount = await currentOperation.action.components.count
    results = await currentOperation.complete
}
func pull(workspace: LocalWorkspace, components: [Component], operation: Operation) async {
    await withTaskGroup(of: String.self) { group in
        for component in components {
            group.addTask {
                do {
                    print("\(component.name)开始执行")
                    try await self.pull(component: component)
                    await operation.addComplete(Result(name: component.name, success: true, content: "成功"))
                } catch {
                    await operation.addComplete(Result(name: component.name, success: false, content: error.localizedDescription))
                }
                await operation.updatePercent(CGFloat(operation.complete.count) / CGFloat(components.count))
                self.updateComponent(component)
                await self.updateProgress()
                return component.name
            }
        }
        for await value in group {
            print("\(value)拉取完成")
        }
    }
}
```

在Task中，如果有actor对象发生行为，自动隔离其他线程对他的操作，相当于加锁，保证这个对象的操作是线程安全的，如果actor内某个方法不需要隔离（比如没有对属性进行操作），那么在方法前面加上nonisolated即可

当然，保证线程安全 ≠ 在主线程上操作，如果需要在主线程上操作，可以搭配@MainActor + class，如

```
@MainActor
class MyClass {
}
```


# SwiftUI

## @EnvironmentObject

众所周知，要弹窗必须在view下面添加一个alert属性，并且在里面定义alert的样式，如果很多地方都有弹窗需求，那么这个重复代码量就很大。

```
/// 第一件事，创建一个Bool控制弹窗显示和隐藏
@State var isShowing = false
VStack {
    Text("Anything")
} 
// 第二个使其，设计弹窗样式，如果弹窗样式复杂，那代码量就更多
.alert(isPresented: isShowing) {
    Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
}
```

目标：设计一个弹窗用来提示错误信息，使其在任意一个View上面都可以弹出，尽量减少重复编码

首先设计一个类，在全局生效

```
class AlertManager: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var title: String = ""
    @Published var message: String = ""
   
    func showAlert(title: String, message: String) {
        self.title = title
        self.message = message
        self.isShowing = true
    }
}
```

实例化后注入到根视图中， 使用environmentObject注入

```
@main
struct yboxDesktopApp: App {
    
    @StateObject private var alertManager = AlertManager()
  
    var body: some Scene {
        MenuBarExtra("yboxDeskTop", image: "icon50") {
            ContentView()
                .environmentObject(alertManager)
                .onAppear {
                    print("Visible")
                }
        }
        .menuBarExtraStyle(.window)
    }
}
```

之后可以在这个根视图下的任意一个子视图都可以访问到这个alertManager对象
如下，在view内定义好环境变量对象之后，点击按钮可以直接访问到alertManager对象，并调用其方法

```
struct GitUserEditView: View {
    @EnvironmentObject var alertManager: AlertManager

    var body: some View {
        VStack {
            Button(action: {
                alertManager.showAlert(title: "提示", message: "信息")
            }) {
                Text("点击")
            }
        }
    }
   }
```
为了创建弹窗，我们创建一个ViewModifier用于修改View的属性

```
struct ErrorAlert: ViewModifier {
    @EnvironmentObject var errorManager: AlertManager

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorManager.isShowing) {
                Alert(title: Text(errorManager.title), message: Text(errorManager.message), dismissButton: .default(Text("OK")))
            }
    }
}
```

拓展一下View, 给他添加刚才创建的ViewModifier

```
extension View {
    func errorAlert() -> some View {
        self.modifier(ErrorAlert())
    }
}
```

完成上述工作之后，用如下方式就可以比较低成本的接入弹窗能力

```
struct GitUserEditView: View {
    @EnvironmentObject var alertManager: AlertManager
    
    var body: some View {
        VStack {
            Button(action: {
                alertManager.showAlert(title: "提示", message: "信息")
            }) {
                Text("点击")
            }
        }
        .errorAlert()
    }
}
```

# Swift 6

## 数据竞争问题

Swift 6 之前，下面代码第十行会有警告，因为user会被认为是不安全的，可能会被其他方法引用导致数据竞争

```
class User {
    var name = "Anonymous"
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .task {
                let user = User()
                await loadData(for: user)
            }
    }

    func loadData(for user: User) async {
        print("Loading data for \(user.name)…")
    }
}
```

Swift 6以后警告消失，因为编译器检查到没有其他地方调用了，所以他是安全的
另外一个修改，在Swift 6中，如果ViewModel被标记为了@MainActor，那么使用他的LogInView也必须被标记为@MainActor

```
@MainActor
class ViewModel: ObservableObject {
    func authenticate() {
        print("Authenticating…")
    }
}

@MainActor
struct LogInView: View {
    @StateObject private var model = ViewModel()

    var body: some View {
        Button("Hello, world", action: startAuthentication)
    }

    func startAuthentication() {
        model.authenticate()
    }
}
```

同理， DataController被标记为@MainActor后，入参Logger也必须要@MainActor

```
@MainActor
class Logger {

}

@MainActor 
class DataController {
    init(logger: Logger = Logger()) {

    }
}
```

这一切都是为了避免数据竞争所作出的修改。

## count(where:)

以前要在下面数组中得到85以上的数据个数，需要创建一个临时数组再数一下

```
let scores = [100, 80, 85]
let passcount = scores.filter({ $0 > 85 }).count
```

Swift 6之后可以使用方法

```
let passCount = scores.count { $0 >= 85 }
```

## 类型化异常抛出

以前我们写try catch的时候，在catch里面需要判断方法throw是的什么类型再进行处理

```
do {
    try xxx
} catch let error as NSError {
    handleNSError(error)
} catch let error as CustomError {
    handleCustomError(error)
} catch {
   handleOtherError(error)
}
```

Swift 6之后可以抛出指定类型的异常，外部可以直接知道Error的类型

```
public func count<E>(where predicate: (Element) throws(E) -> Bool) throws(E) -> Int
```

## import访问控制
Swift 6之后可以使用如下语法
private import SomeLibrary
当然private也可以改为public、internal等访问控制符
这个语法可以帮助我们隐藏某些库的引入，让外部无法知道我们依赖了哪些库
## 不可复制类型
~Copyable是可复制前面带了一个取反符号，所以直译为不可复制类型
不可复制类型是在 Swift 5.9 中引入的，但在 Swift 6 中得到了几次升级
虽然翻译是这么翻译，但是我觉得更确切的说法应该是一次性类型。
使用方法如下，MissionImpossibleMessage标记为不可复制，并且read方法标记为了consuming
意味着message实例调用了read方法后会自动被销毁，他会被“消费”掉
继续执行print方法将会报错，因为message已经被销毁

```
struct MissionImpossibleMessage: ~Copyable {
    private var message: String

    init(message: String) {
        self.message = message
    }

    consuming func read() {
        print(message)
    }
}

let message = MissionImpossibleMessage()
message.read()
print(message)
```

## 不连续下标

swift6升级了RangeSet, 支持从数组中分离出若干个满足条件的元素的不连续下标，并通过for循环结合下标进行遍历
比如下面的例子是从成绩表里面找到大于85分的成绩并打印出来
swift6之前我们可能会通过filter和map去解决问题，swift6之后多了一种解决方案

```
struct ExamResult {
    var student: String
    var score: Int
}

let results = [
    ExamResult(student: "Eric Effiong", score: 95),
    ExamResult(student: "Maeve Wiley", score: 70),
    ExamResult(student: "Otis Milburn", score: 100)
]

let topResults = results.indices { student in
    student.score >= 85
}

for result in results[topResults] {
    print("\(result.student) scored \(result.score)%")
}
```

## Int128
就是支持了128位的整型

```
let enoughForAnybody: Int128 = 170_141_183_460_469_231_731_687_303_715_884_105_727
```

## 其他
Swift开始支持Windows、Linux、C++混编、嵌入式编程
