title: Swift 5.5 async与 await
author: Arclin
abbrlink: 75996dec
tags:
  - iOS
  - Swift
categories:
  - iOS
date: 2021-08-23 22:55:00
---
本文主要简述Swift 5.5新特性 async与await的常用方式

<!-- more -->

## 举个例子

首先我们来做一个简单的下载图片的任务

```swift
struct Download {
    static func image(url: URL, completeHandler: @escaping (UIImage?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completeHandler(nil,error)
                }
                return
            }
            if let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let image = UIImage(data: data)
                if image != nil {
                    DispatchQueue.main.async {
                        completeHandler(image, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completeHandler(nil, NSError(domain: "org.swift", code: -2))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completeHandler(nil, NSError(domain: "org.swift", code: -1))
                }
            }
        }
        task.resume()
    }
}
```
可以发现，这个简单的任务里面涉及到了block嵌套，子线程与主线程的切换等等上下文切换的逻辑。

代码首先会执行第一行，然后就直接执行最后一行，再回到第二行执行，然后还得判断各种异常状态，最后才回到主线程刷新。可以发现这里面最深的嵌套达到了4层，而且上下文的切换也不利于代码阅读。可想而知要是逻辑稍微再多一点，就远远不止这种复杂度了。

## 用 async 和 await 来拯救一下

改造完之后，代码如下

```swift
static func image(url: URL) async throws -> UIImage {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw NSError(domain: "org,swift", code: -1) }
    guard let maybeImage = UIImage(data: data) else { throw NSError(domain: "org,swift", code: -1) }
    return maybeImage
}
```

调用方式如下（如果需要捕获异常的话就需要加上`do-catch`）

```swift
Task {
   try self.imageView.image = await AsyncTest.image(url: URL(string: "https://images.xiaozhuanlan.com/photo/2021/fb4d1bcda193cdfb5ccc380d1a008fe1.png")!)
}
```

可以看到我们的代码精简了许多，嵌套最深也就是判断到异常的时候抛出的1层，接下来我们来逐行讲解一下

### 发起请求

首先`URLSession.shared.data(from: url) `是iOS 15 新出的方法，用于发起网络请求，方法定义如下

```swift
/// Convenience method to load data using an URL, creates and resumes an URLSessionDataTask internally.
///
/// - Parameter url: The URL for which to load data.
/// - Parameter delegate: Task-specific delegate.
/// - Returns: Data and response.
public func data(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)
```

其中 `async` 表示这是一个异步方法，如同我们前面定义的方法一样`static func image(url: URL) async throws -> UIImage`，同样也有`async`这个关键字，只要方法里面有`await`关键字，那么方法名就得带上`async`关键字。带有`async`的方法就意味着需要使用`await`去调用，然后其返回值可以直接赋值给某个变量。举例如下:

```swift
func getName() async -> String {
	/// 发起网络请求获取名字，这时候线程会卡住，直到请求完成了，就会把这个请求方法的返回值直接赋值给name，然后就会继续往下执行，把拿到的name给返回出去
	let name = await requestName()
	return name
}

/// 同理，当代码执行到这里的时候，调用异步方法，线程会卡住，然后方法里面去调用网络请求获取名字，然后等待网络请求返回之后，name就会被赋上值
let name = await getName()
```

以上面的`URLSession`的`data(from:delegate:)`方法为例，返回的是一个元组，所以就是

```swift
let (data, response) = try await URLSession.shared.data(from: url)
```
表示请求后，`data`和`response`变量都会被赋上值，分别是`Data`类型和`URLResponse`类型

另外我们注意到，和通过block方式返回请求结果不同，这个新方法返回的元组中的`data`和`response`都不是可选类型，而是确切有值的，如果发生网络异常则会通过`throw`抛出异常，这样子的设计能够让我们节省加下来针对空值的判断，可以放心地使用返回值

> 当然，不仅仅是网络请求可以用`await`，任意的异步行为（比如读取本地文件）都可以使用`await`

目前在iOS 15 SDK的`URLSession`中，不仅仅提供了上述请求数据，返回元组的方法，还提供了其他上传，下载的方法，可供异步调用，这里简单列举一下

```swift
/// Convenience method to upload data using an URLRequest, creates and resumes an URLSessionUploadTask internally.
///
/// - Parameter request: The URLRequest for which to upload data.
/// - Parameter fileURL: File to upload.
/// - Parameter delegate: Task-specific delegate.
/// - Returns: Data and response.
public func upload(for request: URLRequest, fromFile fileURL: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)

/// Convenience method to upload data using an URLRequest, creates and resumes an URLSessionUploadTask internally.
///
/// - Parameter request: The URLRequest for which to upload data.
/// - Parameter bodyData: Data to upload.
/// - Parameter delegate: Task-specific delegate.
/// - Returns: Data and response.
public func upload(for request: URLRequest, from bodyData: Data, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)

/// Convenience method to download using an URLRequest, creates and resumes an URLSessionDownloadTask internally.
///
/// - Parameter request: The URLRequest for which to download.
/// - Parameter delegate: Task-specific delegate.
/// - Returns: Downloaded file URL and response. The file will not be removed automatically.
public func download(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (URL, URLResponse)

/// Convenience method to download using an URL, creates and resumes an URLSessionDownloadTask internally.
///
/// - Parameter url: The URL for which to download.
/// - Parameter delegate: Task-specific delegate.
/// - Returns: Downloaded file URL and response. The file will not be removed automatically.
public func download(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (URL, URLResponse)

/// Convenience method to resume download, creates and resumes an URLSessionDownloadTask internally.
///
/// - Parameter resumeData: Resume data from an incomplete download.
/// - Parameter delegate: Task-specific delegate.
/// - Returns: Downloaded file URL and response. The file will not be removed automatically.
public func download(resumeFrom resumeData: Data, delegate: URLSessionTaskDelegate? = nil) async throws -> (URL, URLResponse)
```

### 容错 & 转码

```swift
guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw NSError(domain: "org,swift", code: -1) }
```
这一行用来处理响应体的异常情况，当`statusCode` 为 200的判断不成立时，就会抛出异常，则外部需要通过`do-catch`去捕获

如果判断成立时，则程序继续往下走

```swift
guard let maybeImage = UIImage(data: data) else { throw NSError(domain: "org,swift", code: -1) }
```

这里将`data`转成了`UIImage`，由于该方法返回的是一个可选值，所以这里同样需要通过`guard`去判断转换失败的情况

```swift
return maybeImage
```

最后得到了确切的结果之后，我们就可以将转好的图片给发送出去了，并且外面使用这个返回值的时候也不用判空，可以放心地确定返回的图片是有值的。

### 调用方法

当我们的方法被标记为`async`的时候，我们就需要加上`await`进行调用，并且调用的环境是需要在异步环境内的，即如下所示

```swift
async {
	try let image = await AsyncTest.image(url: xxxx)
}
```

在Xcode 13.0 bata 4 中这个`async {} `环境的建立代码被提示即将被废弃，所以改成了如下所示

```swift
Task(priority: .userInitiated) {
    try let image = await AsyncTest.image(url: xxxx)
}
```

这里的`userInitiated`表示线程优先级为`用户发起`，当然`priority`参数也可以不填，默认优先级是`Task.currentPriority`，返回值默认是`default`

目前有六种优先级，这里从高到低进行排列如下：

```swift
/// 优先级最高
public static let high: TaskPriority

/// 等同于default
public static var medium: TaskPriority { get }

public static let low: TaskPriority

public static let userInitiated: TaskPriority

public static let utility: TaskPriority

/// 优先级最低
public static let background: TaskPriority
```

### 总结

当你标记一个函数为`async`时，即表示该函数可以被挂起。在`async`函数内部，使用`await`关键词标记在哪里可以一次或多次挂起。当`async`函数挂起时，线程并未阻塞，系统会自由安排其他任务。有时后启动的任务，可能先被执行。即你的程序状态可能在挂起时发生显著变化。当`async`函数恢复执行时，其返回的结果会自然融入到`async`函数的调用者，并在先前挂起的地方接续执行。

### 注意

`await`关键字表示该异步（async）函数可能会被挂起，而不是畅通无阻地继续执行下去，甚至从挂起恢复回来时，函数可能已经跑到了另一个线程上去了，为了解决这个问题，我们可以用Swift的`actor`保护可变状态，这个我们后面再讲

## Async序列

Async序列顾名思义就是异步的序列，比如读取一个很大的文件，我们希望一边下载一边展示读取的内容，这时候我们可以通过使用`for await-in` 来遍历一个异步的序列，如下

```swift
static func eatchquakes() async throws {
    let endpointURL = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv")!

    // 跳过首行 因为是header描述不是地震数据
    // 接着遍历提取强度、时间、经纬度信息
    for try await event in endpointURL.lines.dropFirst() {
        let values = event.split(separator: ",")
        let time = values[0]
        let latitude = values[1]
        let longtitude = values[2]
        let magnitude = values[4]
        print("Magnitude \(magnitude) on \(time) at \(latitude) \(longtitude)")
    }
}
```

也就是说，异步序列就是对随着时间推移如何产生值或对象的一种描述方式。由于值的产生是异步的，所以可能会在读取的过程中出现异常，当异常发生的时候，遍历终止，并抛出异常。

其中，`lines`方法是iOS 15 新增的一个`URL`的拓展属性，同时还有`resourceBytes`属性，完整定义如下

```swift
extension URL {
    public struct AsyncBytes : AsyncSequence, AsyncIteratorProtocol {

        public typealias AsyncIterator = URL.AsyncBytes
        
        public typealias Element = UInt8

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        /// 
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        @inlinable public mutating func next() async throws -> UInt8?

        /// Creates the asynchronous iterator that produces elements of this
        /// asynchronous sequence.
        ///
        /// - Returns: An instance of the `AsyncIterator` type used to produce
        /// elements of the asynchronous sequence.
        public func makeAsyncIterator() -> URL.AsyncBytes
    }
    public var resourceBytes: URL.AsyncBytes { get }
    public var lines: AsyncLineSequence<URL.AsyncBytes> { get }
```

因为异步序列的遍历是一个耗时操作，所以我们也可以在需要的时候中断遍历（取消请求）

```swift
let task = Task(priority: .userInitiated) {
    do {
        try await AsyncTest.eatchquakes()
    } catch {
        print(error)
    }
}

/// 取消
task.cancel()
```

除了`URL`新增的`lines`方法，iOS 15 还给`FileHandle`和`URLSession`添加了异步序列方法，比如`FileHandle`新增的`bytes`属性，能提供字节流的异步序列。配合异步序列的扩展能力（把字节流变成`lines`），我们就可以从文件中异步地获得逐行内容并进行处理了。

```swift
// 从FileHandle异步读取bytes
public var bytes: AsyncBytes

for try await line in FileHandle.standardInput.bytes.lines {

}
```

不仅如此，现在通知也支持异步序列了

```swift
// 异步await通知
public func notifications(named: Notification.Name, object: AnyObject) -> notifications

let center = NotificationCenter.default

/// 返回第一个userInfo的NSStoreUUIDKey值为storeUUID的通知
let notification = await center.notifications(named: .NSPersistentStoreRemoteChange).first {
    $0.userInfo[NSStoreUUIDKey] == storeUUID
}
```

## 将异步回调的闭包方法改造成async方法

上面提到的都是基于系统提供的`async`方法，如果要改造我们原有的异步回调block方法，我们可以使用`withCheckedContinuation`或者`withCheckedThrowingContinuation`函数，区别在于前者用于确定不会抛出错误的场景，举例如下：

- 三秒后返回Hello World

```swift
static func getItem(callback: @escaping (String)->(Void)) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        callback("Hello World");
    }
}
```

改造后

```swift
static func getItem() async -> String {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            continuation.resume(returning: "Hello World");
            /// 如果需要抛出错误，使用 continuation.resume(throwing: error)
        }
    }
}
```

continuation 有个简单但是重要的原则，resume方法必须在每个路径上执行，有且只有一次。但是不用担心，如果在有的路径上没有执行resume方法，Swift runtime 会发出 warning 警告。

但如果在某个路径上，resume执行了不止一次，这会是严重得多的问题。Swift runtime 会在第二次 resume 调用处触发 fatal error。

如果使用的是`withTaskCancellationHandler`，那么可以在异步操作被取消的时候执行某些行为

```swift
static func getItem() async throws -> String {
    return try await withTaskCancellationHandler {
        print("Cancel")
    } operation: {
        let result = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                continuation.resume(returning: "Hello World")
            }
        }
        return result
    }
}

/// 调用
let task = Task {
    do {
        let item = try await AsyncTest.getItem()
        print(item)
    } catch {
        print("Error" + error.localizedDescription)
    }
}

/// 调用取消的时候会打印`Cancel`
task.cancel()
```

## 只读属性使用async

只读属性可以在其`get`方法中使用`async`标记是一个异步读取的属性，如下所示

```swift
struct AsyncTest {
  enum FileError : Error {
      case missing, unreadable
  }

  var content : String {
      get async throws {
          guard let url = Bundle.main.url(forResource: "Empty", withExtension: "md") else { throw FileError.missing }
          do {
              return try String(contentsOf: url)
          } catch {
              throw FileError.unreadable
          }
      }
  }

  func readContent() async throws -> String {
      let result = try await self.content
      return result
  }
}
```

## 结构化并发

假如我们有多个异步函数，比如`切菜`、`切洋葱`、`切肉`

```swift
struct Cooking {
    static func cutVegetable() async -> String {
        await Task.sleep(10_000_000_000) // 暂停10秒的意思
        return "cut vegetable"
    }
    
    static func cutOnion() async -> String {
        await Task.sleep(5_000_000_000)
        return "cut onion"
    }
    
    static func cutMeet() async -> String {
        await Task.sleep(5_000_000_000)
        return "cut meet"
    }
}
```

如果我们这么调用的话，那么整个过程将是串行的，一共会花费20秒左右

```swift
Task {
    let step1 = await Cooking.cutVegetable()
    let step2 = await Cooking.cutOnion()
    let step3 = await Cooking.cutMeet()
    
    print([step1,step2,step3])
}
```

但是实际三个步骤之间并没有依赖关系，是可以同时进行的，所以我们需要使用结构化并发，让他们并发执行

```swift
func cooking() async -> [String] {
    return await withTaskGroup(of: String.self) { group in
        group.addTask {
            await Cooking.cutVegetable()
        }
        group.addTask {
            await Cooking.cutOnion()
        }
        group.addTask {
            await Cooking.cutMeet()
        }
        var steps : [String] = []
        for await finishedStep in group {
            steps.append(finishedStep)
        }
        return steps
    }
}
```

这样子只要10秒左右就可以完成任务了

```swift
Task {
    let result = await cooking()
    print(result)
}
```

如果在执行子任务的过程中发生了异常，那么`cooking()`方法将会退出，任何尚未完成的子任务都将自动取消。

## Actor

由于我们现在已经多很多异步操作的场景，所以自然我们在设计类的时候，也要注意这个类要是被多个线程同时访问的时候引起的状态变化的问题。

Swift 5.5引入了Actor，它在概念上类似于在并发环境中可以安全使用的类。Swift 确保在任何给定时间只能由单个线程访问 Actor 内的可变状态，这有助于在编译器级别消除各种严重的错误。

比如以下代码在单线程情况下是安全的，但是如果是多线程访问的话`deck`属性会出现资源竞争的问题

```swift
class RiskyCollector {
    var deck: Set<String>
    
    init(deck: Set<String>) {
        self.deck = deck
    }
    
    func send(card selected: String, to person: RiskyCollector) -> Bool {
        guard deck.contains(selected) else { return false }
        deck.remove(selected)
        person.transfer(card: selected)
        return true
    }
    
    func transfer(card: String) {
        deck.insert(card)
    }
}
```

危险：

```
let set = Set<String>(["1","2","3","4","5","6","7","8","9","10","11","12"])
let risky = RiskyCollector(deck:set)
for i in 1...12 {
    DispatchQueue.global().async {
        _ = risky.send(card: "\(i)", to: risky)
        print(risky.deck)
    }
}
```

Actor 通过引入 Actor 隔离解决了这个问题：除非异步执行，否则无法从 Actor 对象外部读取属性和方法，并且根本无法从 Actor 对象外部写入属性。 Swift 会自动将这些请求放入一个按顺序处理的队列中，以避免出现多线程竞争。

我们可以使用Actor重新实现一个SafeCollector，如下:

```swift
actor SafeCollector {
  var deck: Set<String>
  init(deck: Set<String>) {
      self.deck = deck
  }

  func send(card selected: String, to person: SafeCollector) async -> Bool {
      guard deck.contains(selected) else { return false }
      deck.remove(selected)
      await person.transfer(card: selected)
      return true
  }

  func transfer(card: String) {
      deck.insert(card)
  }
}
```

安全：

```swift
let set = Set<String>(["1","2","3","4","5","6","7","8","9","10","11","12"])
let risky = SafeCollector(deck:set)
for i in 1...12 {
    Task {
        _ = await risky.send(card: "\(i)", to: risky)
        print(await risky.deck)
    }
}
```

在这个例子中有几件事情需要注意：

- actor内对外暴露的方法都是异步方法，即使没有标记async，因为它会等到另一个 SafeCollector actor 能够处理请求。

- actor 可以自由地、异步或以其他方式使用自己的属性和方法，但是当与不同的 actor 交互时，它必须始终异步完成。通过这些特性，Swift 可以确保永远不会同时访问所有与 actor 隔离的状态，更重要的是，这是在编译时完成的，以保证线程安全。

Actor 和 Class 有一些相似之处：

- 两者都是引用类型，因此它们可用于共享状态。

- 它们可以有方法、属性、初始值设定项和下标。

- 它们可以实现协议。任何静态属性和方法在这两种类型中的行为都相同。

除了 Actor 隔离之外，Actor 和 Class之间还有另外两个重要的区别：

- Actor 目前不支持继承，这在未来可能会改变

- 所有 Actor 都隐式遵守一个新的 Actor Protocol

### Global Actor

Global Actor 将 actor 隔离的概念扩展到了全局状态，即使状态和函数分散在许多不同的模块中，Global Actor 可以在并发程序中安全地使用全局变量，例如 Swift 提供的 `@MainActor` 限制属性和方法只能在主线程访问

```swift
class ViewController {
    @MainActor func refreshUI() {
        print("updating ui…")
    }
}

@MainActor var globalTextSize: Int

@MainActor func increaseTextSize() {
  globalTextSize += 2   // okay:
}

func notOnTheMainActor() async {
  globalTextSize = 12  // error: globalTextSize is isolated to MainActor
  increaseTextSize()   // error: increaseTextSize is isolated to MainActor, cannot call synchronously
  await increaseTextSize() // okay: asynchronous call hops over to the main thread and executes there
}
```