title: Swift 5.4 Result Builder
author: Arclin
tags:
  - iOS
  - Swift
categories:
  - iOS
abbrlink: 4bf15bdf
date: 2021-07-18 10:13:00
---
本文主要讲述Swift 5.4的新特性 Result Builder在设计上的一些使用方式

<!-- more -->

## 需求

假如我们有一个需求，需要往ScrollView上加入不同类型的View，并且根据不确定的的顺序从上往下进行排列，所以一般情况下我们可以这样子设计框架

1. 首先定义一个协议，遵循协议的对象使用一个build方法返回一个View

  ```
  protocol ViewBuilder {
      func build() -> UIView
  }
  ```
 
2. 这里我们设计四种颜色的View，宽度均为屏幕宽度，高度不定

  ```
  struct WhiteView : ViewBuilder {
      func build() -> UIView {
          let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100))
          view.backgroundColor = .white
          return view
      }
  }

  struct RedView : ViewBuilder {
      func build() -> UIView {
          let banner = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200))
          banner.backgroundColor = UIColor.red
          return banner
      }
  }

  struct BlueView : ViewBuilder {
      func build() -> UIView {
          let goodsView = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 350))
          goodsView.backgroundColor = UIColor.blue
          return goodsView
      }
  }

  struct GreenView : ViewBuilder {
      func build() -> UIView {
          let dynamicView = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 400))
          dynamicView.backgroundColor = UIColor.green
          return dynamicView
      }
  }
  ```
  
3. 最后我们再定义一个ScrollView的容器，传入一个数组，让其从上到下进行排列

	```
    struct ScrollableContainer : ViewBuilder {
    var contents : [ViewBuilder]
    func build() -> UIView {
        let scrollView = UIScrollView.init(frame: UIScreen.main.bounds)
        _ = contents.reduce(CGFloat(0)) { currentY, builder in
            let view = builder.build()
            view.frame.origin.y = currentY
            scrollView.addSubview(view)
            scrollView.contentSize = CGSize(width: UIScreen.main.bounds.size.width, height: scrollView.subviews.last!.frame.maxY)
            return currentY + view.frame.size.height
        }
        return scrollView
    }
    ```
    
4. 这样子我们就可以开始布局了

	```
    let scrollView = ScrollableContainer(contents: [
        RedView(),
        BlueView(),
        GreenView()
    ])
    view.addSubview(scrollView.build())
    ```
    
    效果如下
    
    <img src="https://p6-tt.byteimg.com/origin/pgc-image/8f8201d352eb44a7aab4b0b68ba6e9e2.png" width=50%>
    
5. 通过这种方式，我们就可以随意调整内部的布局顺序，也可以方便的新增多个View

## 优化

但是上述方法有一个缺点，就是当如果要重复添加多个相同的View或者说想要通过某个条件再添加View，就会有点复杂，比如当`needBlue == true`成立的时候再添加`BlueView`，那么可能需要这么写

```
var contents = [
    RedView(),
    GreenView()
]

if needBlue == true {
	contents = [
        RedView(),
        BlueView(),
        GreenView()
    ]
}

let scrollView = ScrollableContainer(contents: contents)
view.addSubview(scrollView.build())
```

为了让可读性更加好，我们可以模仿SwiftUI的DSL语法进行设计，这里就需要使用到Swift 5.4的新特性 Result Builder
    
1. 首先我们要添加一个容器结构体，因为从上到下写的`View`会被整成一个数组或者多参数传进来，所以要加一个容器把他们从上到下排列好，最后排列完了，再把这个容器放进去ScrollView中

	```
	struct ViewContainer : ViewBuilder {
      var contents : [ViewBuilder]
      func build() -> UIView {
          let container = UIView(frame: UIScreen.main.bounds)
          _ = contents.reduce(CGFloat(0), { currentY, builder in
              let view = builder.build()
              view.frame.origin.y = currentY
              container.addSubview(view)
              container.frame.size = CGSize(width: UIScreen.main.bounds.size.width, height: container.subviews.last!.frame.maxY)
              return currentY + view.frame.size.height
          })
          return container
      }
	}
    ```
    
2. 创建一个Result builder，使用`@resultBuilder`注解会要求我们添加一个`buildBlock`方法，实现这个方法，把我们外面传进来的多个View放进去`VieContainer`容器中，然后实现`buildFinalResult`在编写结束的时候把
`VieContainer`放进去`ScrollView`容器中

	```
    @resultBuilder
    struct ScrollableViewBuilder {
        static func buildBlock(_ components: ViewBuilder...) -> ViewBuilder {
            return ViewContainer(contents: components)
        }
        static func buildFinalResult(_ component: ViewBuilder) -> ViewBuilder {
            return ScrollableContainer(contents: [component])
        }
    }
    ```
    
3. 这时候我们通过新增的`ScrollableViewBuilder`来创建一个方法，这里的闭包就是待会我们要写DSL的地方

	```
    func build(@ScrollableViewBuilder content: () -> ViewBuilder) -> ViewBuilder {
        return content()
    }
    ```
    
    这个方法传入一个闭包，这个由于我们已经实现了`buildBlock`，所以`content`被`@ScrollableViewBuilder`修饰之后，会自动将闭包内的东西转化成多参数，传入`buildBlock`方法，在那里面我们把各种各样的`View`给添加到`ViewContainer`上，方法调用如下
    
    ```
    let result = build {
        RedView()
        BlueView()
        GreenView()
    }
        
	view.addSubview(result.build())
    ```

	这时候运行效果同上图一致
    
4. 接下来我们需要让这个闭包内支持if语句、else if语句、else语句和for语句，

	```
    struct ScrollableViewBuilder {
      static func buildBlock(_ components: ViewBuilder...) -> ViewBuilder {
          return ScrollableContainer(contents: components)
      }
      /// 表示if语句
      static func buildEither(first component: ViewBuilder) -> ViewBuilder {
          return component
      }
      /// 表示eles if语句
      static func buildEither(second component: ViewBuilder) -> ViewBuilder {
          return component
      }
      /// 表示else语句和其他的可选值（即？修饰的View）
      static func buildOptional(_ component: ViewBuilder?) -> ViewBuilder {
          return component ?? DefaultView()
      }
    }
    ```
    
    然后我们试一试这么写
    
    ```
    let flag = 2
    let result = build {
        RedView()
        BlueView()
        GreenView()
        if flag == 1 {
            RedView()
            RedView()
        } else if flag == 2 {
            GreenView()
            GreenView()
            GreenView()
        } else if flag == 3 {
            GreenView()
        } else {
            BlueView()
            BlueView()
            BlueView()
        }
    }
    ```
    
    当flag = 1的时候，首先两个`RedView()`会先进入`buildBlock`方法，然后被包装成一个`ViewContainer`，然后再进去`buildEither(first component: ViewBuilder)`方法，这里我没处理就直接把传进来的值返回出去了
    
    当flag = 2 或者 flag = 3 的时候，首先括号内的多个`GreenView()`会先进入`buildBlock`方法，然后被包装成一个`ViewContainer`，然后再进去`buildEither(second component: ViewBuilder)`方法，这里我没处理就直接把传进来的值返回出去了
    
    当 flag 为其他值的时候，首先括号内的多个`BlueView()`会先进入`buildBlock`方法，然后被包装成一个`ViewContainer`，然后再进去`buildEither(second component: ViewBuilder)`方法。当没有写`eles`语句的时候，需要实现`buildOptional(_ component: ViewBuilder?)`方法，去处理没有进入`if`语句而导致的不返回`View`的情况，如果没有写`else`语句，那么不会进入`buildBlock`，会直接取空值情况下你返回的默认`View`。
    
5. 处理for语句，比如这样

    ```
    let result = build {
        RedView()
        BlueView()
        GreenView()
        for _ in 0...2 {
            GreenView()
            BlueView()
        }
    }
    ```
    
    `for`里面需要返回3个`GreenView+BlueView`，这里他每次调用for的括号里面的内容，都会走一遍`buildBlock`把里面的`GreenView+BlueView`封装成一个`ViewContainer`，所以这里会产生3个`ViewContainer`，最后这三个会变成一个数组，进入`buildArray`方法，再封装成一个`ViewContainer`，代码如下
    
    ```
    @resultBuilder
    struct ScrollableViewBuilder {
        static func buildBlock(_ components: ViewBuilder...) -> ViewBuilder {
            return ViewContainer(contents: components)
        }
        static func buildEither(first component: ViewBuilder) -> ViewBuilder {
            return component
        }
        static func buildEither(second component: ViewBuilder) -> ViewBuilder {
            return component
        }
        static func buildOptional(_ component: ViewBuilder?) -> ViewBuilder {
            return component ?? WhiteView()
        }
        static func buildArray(_ components: [ViewBuilder]) -> ViewBuilder {
            return ViewContainer(contents: components)
        }
        static func buildFinalResult(_ component: ViewBuilder) -> ViewBuilder {
            return ScrollableContainer(contents: [component])
        }
    }
    ```
    
6. 处理表达式，如果我们要在DSL里面插一些除了`View`之外的一些东西，那么就需要添加对应的处理方法，比如

	```
    let result = build {
        print("a123")
        RedView()
        BlueView()
        GreenView()
    }
    ```
    
    针对这个`print`我们添加表达式处理
    
    ScrollableViewBuilder
    
    ```
    /// 针对正常的表达式，就直接返回
    static func buildExpression(_ expression: ViewBuilder) -> ViewBuilder {
        return expression
    }
    
    /// 针对特殊的表达式，返回空View
    static func buildExpression(_ expression: ()) -> ViewBuilder {
        return EmptyBuilder()
    }
    ```
    
    EmptyBuilder
    
    ```
    struct EmptyBuilder : ViewBuilder {
      func build() -> UIView {
          return UIView.init()
      }
    }
    ```
    
## 总结

到这里就说的差不多了，其他本文没提及到的内容可以参阅[Write a DSL in Swift using result builders](https://developer.apple.com/videos/play/wwdc2021/10253/)

本文[Demo](https://github.com/Arc-lin/ResultBuilderDemo)地址
    