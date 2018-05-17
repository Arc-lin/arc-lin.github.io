---
title: ReactNative ListView flexWrap不起作用解决办法
author: Arclin
tags:
  - React Native
categories: []
abbrlink: 11785d19
date: 2017-03-02 00:00:00
---
`flexWrap:’wrap’ `作用是让超出页面的元素进行换行显示,但是在RN 0.28之后就发生了改变

<!-- more -->

|RN0.28之前|RN0.28之后|
|----|----|
|contentViewStyle:<br/>{<br/>flexDirection:’row’,<br/>flexWrap:’wrap’,<br/>alignItems: ‘stretch’,<br/>// 屏幕宽度<br/>width:width,<br/>},|contentViewStyle:<br/>{<br/>flexDirection:’row’,<br/>flexWrap:’wrap’,<br/>alignItems:’flex-start’,<br/>// 屏幕宽度<br/> width:width,<br/>},|

`alignItems: ‘stretch’` 变成了 `alignItems:’flex-start’`,

但是现在的教程基本上不会加上`alignItems`…只有一个`flexWrap`,但是放到现在就实现不了了