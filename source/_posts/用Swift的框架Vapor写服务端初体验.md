title: 用Swift的框架Vapor写服务端初体验
author: Arclin
tags:
  - Swift
categories:
  - Swift
date: 2017-03-16 00:00:00
---
咦? 用Swift写后端? 一开始听到的时候懵逼了一秒,一秒自后想了想感觉也没毛病,那就试试看咯.(没看WWDC的后果)

<!-- more -->

## 安装Vapor

`curl -sL toolbox.vapor.sh | bash`

## 创建项目

`vapor new Hello --template=light`

`--template=light` 意思是使用light-template模板,如果不指定模板的话默认使用base-template模板

下载依赖并编译项目
`vapor build`

50多M的包,好久…

配置服务器
创建Config文件夹,新建servers.json文件, 指定host地址和端口号

```
{
  "http": {
    "host": "0.0.0.0",
    "port": 8000
  }
}
```

`0.0.0.0` 和 `127.0.0.1` 都表示本机，使用 `0.0.0.0` 的原因是，一个机器可能有多个 IP 地址，`0.0.0.0` 表示监听每个 IP `8000` 端口收到的请求。

`127.0.0.1` 则表示只接受本机发给本机的请求，从网络上其他电脑发过来的请求，不论是请求的哪个 IP，都是不被处理的。

## 打包成一个XCode项目
`vapor xcode -y` 这样子打包之后就会自动打开了

## 启动服务器
`vapor run` 或者在XCode运行

看到了控制台输出了

```
No command supplied, defaulting to serve...
No preparations.
Server 'http' starting at 0.0.0.0:8000
```

就可以了

如果说什么`Can not bind to xxxx` 就应该是端口占用的问题,可以用`lsof -i tcp:端口号` 和 `kill -9` 端口号解决这个问题

如果你在浏览器输入`http://localhost:8000`可以看到以下信息就证明服务器启动成功了

```
Request  
- GET / HTTP/1.1
- Headers:
    Host: 0.0.0.0:8000
    Upgrade-Insecure-Requests: 1
    Connection: keep-alive
    User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36
    Accept-Language: en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4,zh-TW;q=0.2
    Accept-Encoding: gzip, deflate, sdch
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
- Body:
```

会出现这串东西是因为他执行了`Sources/App/main.swift`的内容,把请求体返回回来.

修改`Sources/App/main.swift`
把文件改成这样子

```
import Vapor

let drop = Droplet()

drop.get { _ in
    return try JSON(node: [
            "message":"Hello Vapor"
        ])
}

drop.get("Hello","There") { request in
    return try JSON (node:[
            "message":"Hello There"
        ])
}

drop.get("TEST") { request in
    return try JSON (node:[
            "message":"Hello Test"
        ])
}

drop.run()
```

然后我们使用Postman测试一下三个地址

`http://localhost:8000/`

![WX20170316-105233@2x.png](https://ooo.0o0.ooo/2017/03/16/58c9fe803b931.png)

`http://localhost:8000/Hello/There

![WX20170316-105315@2x.png](https://ooo.0o0.ooo/2017/03/16/58c9fe7f92afc.png)

`http://localhost:8000/TEST`

![WX20170316-105336@2x.png](https://ooo.0o0.ooo/2017/03/16/58c9fe7fca399.png)

接下来试试接受参数并返回

继续在`drop.run()` 上面补充

```
drop.post("post") { request in
    guard let name = request.data["name"]?.string else {
        throw Abort.badRequest
    }
    return try JSON(node: [
        "name": "Hello \(name)!"
        ])
}
```

> guard近似的看做是Assert，但是你可以优雅的退出而非崩溃。

判断如果没有接收到’name’参数的话就会抛出异常Invalid request,有的话就返回Hello + 参数值 + !

测试一下

![WX20170316-110133@2x.png](https://ooo.0o0.ooo/2017/03/16/58ca001f306a5.png)

部署服务器
Vapor支持Heroku,Ubuntu,Digital Ocean,AWS等等服务器,具体怎么做我还没试过,有时间再去试试看

为什么要用Swift写服务器?
额,看了一下资料,也没发现有谁说这东西有什么特别突出的优点,不过没试过,觉得挺新鲜,就试试嘛.

> 学习资料 :

> [服务端 Swift - Vapor 篇 （一）](http://www.jianshu.com/p/3fc28570d951)

> [用 Swift 的框架 Vapor 写服务器这事儿怎么样？](http://tips.producter.io/yong-swift-de-kuang-jia-vapor-xie-fu-wu-qi-zhe-shi-er-zen-yao-yang/)