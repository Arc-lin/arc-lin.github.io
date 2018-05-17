---
title: URLWithString返回空
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 890a3088
date: 2016-10-17 00:00:00
---
`[NSURL URLWithString:@”…………”]` 返回空 nil
但是貌似汉字或者空格等无法被识别，String不被认为是URLString，这个NSURL的值也就一直是nil
要怎样才能够让它识别呢？
解决方法如下 ：

1. 转换编码

  ```
  str1 = [str1 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

  NSURL *url = [NSURL URLWithString:[Tool returnFormatString:str1]];
  ```

2. 除去空格

  ```
  +(NSString *)returnFormatString:(NSString *)str
  {
      return [str stringByReplacingOccurrencesOfString:@" "withString:@" "];
  }

   NSLog(@"URL==%@",url);
  ```