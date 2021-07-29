title: Swift 5 Property Wrapper
author: Arclin
tags:
  - iOS
  - Swift
categories:
  - iOS
abbrlink: 1bf095f2
date: 2021-07-30 00:14:00
---
本文主要讲述Swift5新特性Property Wrapper的使用

<!-- more -->

Property Wrapper即属性包装器，用于对某个属性进行包装，包装后可以对其做一些约束、限制或者修改

## 使用

举例，比如我们需要添加一个属性包装器用来包装字符串，对字符串长度进行限制，只有当字符串长度在允许范围内，才能被赋值到属性中

创建一个属性包装器，`wrappedValue`是必须的，并且需要实现其setter和getter，在里面添加赋值判断逻辑

我们可以提供两种属性包装器的初始化方法，一种是设置默认字符串长度上下限，一种是设置特定的字符串长度上下限

```
@propertyWrapper
struct StringWrapper {
    private var value : String
    private var minLength : Int
    private var maxLength : Int
    
    var wrappedValue : String {
        get { return value }
        set {
            if (minLength...maxLength).contains(newValue.count) {
                value = newValue
            } else if minLength > newValue.count {
                print("字符串太短了")
            } else {
                print("字符串太长了")
            }
        }
    }
    
    /// 默认5-10个字
    init() {
        minLength = 5
        maxLength = 10
        value = ""
    }
    
    /// 设置默认值
    init(minLength: Int, maxLength: Int, value: String = "") {
        self.maxLength = maxLength
        self.minLength = minLength
        self.value = value
    }
}
```

使用属性包装器的方式如下

```
struct Person {
     /// 自定义初始化方式
    @StringWrapper(minLength: 3, maxLength: 5) var name: String
    /// 默认初始化方式
    @StringWrapper var title : String
}

var person = Person()
person.name = "ARCLIN"
person.title = "Hyper Agent GridMan"
print(person.name) /// ARCLIN
print(person.title) /// 字符串太长了
```

## 从属性包装器中呈现一个值

属性包装器还提供了另外一个属性，这个属性一般情况下可以用来标记被包装的属性是否被修改过

```
@propertyWrapper
struct StringWrapper {
  ···
  var projectedValue = false
  var wrappedValue : String {
      get { return value }
      set {
          if (minLength...maxLength).contains(newValue.count) {
              value = newValue
              projectedValue = false
          } else if minLength > newValue.count {
              print("字符串太短了")
              projectedValue = true
          } else {
              print("字符串太长了")
              projectedValue = true
          }
      }
  }
  ···
}
```

我们可以通过`$`符号来调用这个值

```
struct Person {
    @StringWrapper(minLength: 3, maxLength: 5) var name: String
}

var person = Person()
person.name = "JASON"
print(person.$name) // 打印false，因为这时候长度符合规范
person.name = "HyperJASON"
print(person.$name) // 打印true，因为这时候长度太长了
```

这个属性也用来可以返回别的东西

```
@propertyWrapper
struct StringWrapper {
  ···
  var projectedValue : NSAttributedString {
      /// 构建出一个富文本对象
      return NSAttributedString(string: "--- \(self.value) ---", attributes: [
          .foregroundColor : UIColor.red,
          .font : UIFont.systemFont(ofSize: 15)
      ])
  }

  var wrappedValue : String {
      get { return value }
      set {
          if (minLength...maxLength).contains(newValue.count) {
              value = newValue
          } else if minLength > newValue.count {
              print("字符串太短了")
          } else {
              print("字符串太长了")
          }
      }
  }
  ···
}
```

```
struct Person {
    @StringWrapper(minLength: 3, maxLength: 5) var name: String
}

var person = Person()
person.name = "JASON"
print(person.$name)
/*  打印出一个富文本对象
--- JASON ---{
    NSColor = "UIExtendedSRGBColorSpace 1 0 0 1";
    NSFont = "<UICTFont: 0x7fc199f06660> font-family: \".SFUI-Regular\"; font-weight: normal; font-style: normal; font-size: 15.00pt";
}
*/
```
