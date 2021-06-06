---
title: DKLogger--iOS日志管理框架
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: abce56f1
date: 2017-02-23 00:00:00
---
用于管理iOS的Log信息的框架

<!-- more -->
可以用在平时的调试中,另外如果app在用户使用过程中发生一些意外事件或者程序崩溃事件,那我们也可以通过服务器的文件得知问题所在

特性
- 支持四个Log等级 `DEBUG`,`INFO`,`WARN`,`ERROR`
- 支持储存Log文件到本地和上传到服务器
- 支持自定义打印Log类型和写入Log类型
- 支持捕获&发送崩溃信息
- 在界面长按2秒可以查看Log信息
- 可以获取用户的在App内的查看轨迹(进入了哪些控制器)
- 崩溃的时候重启RunLoop,进入ANR状态,不闪退
- 支持服务器端同步显示Log信息(建议搭建本地服务器,因为这样子Log发送快)

使用

```
DKLog(@"..."); 普通log
DKInfoLog(@"..."); 包含特殊信息的log
DKWRANLog(@"..."); 警告log
DKERRLog(@"..."); 错误log
```
```
/**	
 初始化: 创建Txt的Log文件并写入输出
 
 @param path  文件夹路径,默认Documents
 @param url   上传log地址 当发生崩溃事故的时候就会提示用户是否上传Log到服务器
 @param debug 调试模式 */
- (void)registerLoggerInPath:(NSString *)path uploadUrlStr:(NSString *)url debug:(BOOL)debug;
eg:
[[DKSharedLogger registerLoggerInPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] uploadUrlStr:@"http://192.168.1.91/public/index/Index/hello" debug:YES];
```

```
[DKSharedLogger printLevel:DKLoggerLevelInfo|DKLoggerLevelWARN]; 在控制器只打印Info和Warn等级的Log
```
```
[DKSharedLogger saveLevel:DKLoggerLevelError|DKLoggerLevelInfo]; 在文件中之写入Info和Error等级的Log
```

```
DK_VAR_DUMP(arr); 查看对象信息,例如变量arr
```

长按界面2秒弹出log信息界面

![](https://github.com/Arc-lin/BlogImage/blob/master/1011.png?raw=true)