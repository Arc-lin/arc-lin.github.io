title: Vue学习笔记
author: Arclin
tags:
  - Vue.js
categories:
  - 前端
date: 2017-08-08 00:10:00
---
Vue.js 是一个用于构建用户界面的渐进式前端框架

<!-- more -->

## 安装 vue-cli 命令行工具

 安装Vue
`npm install -g vue-cli`

## 初始化项目
vue init webpack-simple 项目名

项目模板有很多种,这里用了webpack-simple webpack-simple 没有包括Eslint检查功能等等功能，webpack有,但是普通项目用webpack-simple就足够了.

构造Vue实例

```
var vm = new Vue({
  // 选项
})
```

例子

```
window.onload=function(){
 //在这里面写Vue.js代码
 new Vue({
  el: '#demo', // 需要渲染的DOM元素
  data: {		 // 渲染的数据,key-value方式
    message: 'Hello Vue.js!' 
  }
})
//----------------
}
```

## HTML中数据绑定

### 单次插值

```
<span>Message: {{ message }}</span>
```

如果想要单次插值,即今后的数据变化就不会再引起插值更新,加个 *

```
<span>This will never change: {{* message }}</span>
```

例子

```
JS

var data={message:'Hello Vue.js!'};
new Vue({
  el: '#demo',
  data: data
 })
data.message ="Hello World!";
data.message ="Hello"; // 再次改变时候,第二个元素内的值不会变化

HTML

<span>This will never change: {{ message }}</span><br>
<span>This will never change: {{* message }}</span>
```

### 嵌入HTML

三个大括号表示不是插入文本而是html标签

```
HTML

<div>{{{ msg }}}</div>
```

```
JS

var data={msg:'<p>Hello Vue.js!</p>'};
new Vue({
    el: '#demo',
    data: data
})

```

### HTMl特性
比如说修改某个元素的id属性

```
HTML

<div id="{{ id }}"></div>
```

```
JS

var data={id:'demo'};
new Vue({
  el: 'div',
  data: data
})
```

### JavaScript表达式

绑定的数据支持JavaScript表达式

```
JS

window.onload=function(){
 //在这里面写Vue.js代码
 var data={message:'Hello ',number:3,ok:true};
 new Vue({
  el: '#demo',
  data: data
 })
 //----------------
}
```

```
<div id='demo'>
{{ number + 1 }}<br/>
{{ ok ? 'YES' : 'NO' }}<br/>
{{ message.split('').reverse().join('') }}
</div>
```

输出

```
YES
olleH
```

### 过滤器
使用管道符 |

将message内的全部转换为小写字母

```
{{ message | lowercase }}
```

转为小写字母后,首字母大写

```
{{msg | lowercase | capitalize}}
```

此外还有大写过滤器`uppercase`

```
JS
 var data={msg:'heLLO!'};
 new Vue({
  el: '#demo',
  data: data
 })
```

输出

```
Hello
```

### 指令
渲染数据的时候的逻辑表达式
v-text v-html v-model v-on v-else

```
JS

var data={msg:0};
 new Vue({
  el: '#demo',
  data: data
 })
```

当msg的值为1的时候才打印Hello!

```
HTML
<p v-if="msg">Hello!</p>
```

### 计算属性

在模板中表达式非常便利，但是它们实际上只用于简单的操作。模板是为了描述视图的结构。在模板中放入太多的逻辑会让模板过重且难以维护。这就是为什么 Vue.js 将绑定表达式限制为一个表达式。如果需要多于一个表达式的逻辑，应当使用计算属性。

```
JS

var vm = new Vue({
  el: '#example',
  data: {
    a: 1
  },
  computed: {
    // 一个计算属性的 getter
    b: function () {
      // `this` 指向 vm 实例
      return this.a + 1
    }
  }
})
```
```
HTML

<div id="example">
  a={{ a }}, b={{ b }}
</div>
```
输出

```
1
a=1, b=2
```