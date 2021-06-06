---
title: Express学习笔记
author: Arclin
tags:
  - Node.js
  - Express
categories:
  - Node.js
abbrlink: dcb90c85
date: 2017-03-07 00:00:00
---
Express 是 Node.js 的一个轻量级web框架,目前使用EJS模板引擎,该笔记持续更新

<!-- more -->

## supervisor

使用supervisor监听文件改变然后自动重启node服务器,这样子就不用每改一次代码run一遍服务器了

`sudo npm install -g supervisor`

### WebStrom配置supervisor

文件目录结构
```
├── app.js        项目入口及程序启动文件。
├── bin
│   └── www       存放启动项目的脚本文件，默认www。
├── package.json  项目依赖配置及开发者信息。
├── public        静态资源文件夹，默认images、javascripts、stylesheets。
│   ├── images
│   ├── javascripts
│   └── stylesheets
├── routes        路由文件相当于MVC中的Controller，默认index.js、users.js。
│   ├── index.js
│   └── users.js
└── views         页面文件，相当于MVC中的view，Ejs模板默认error.ejs、index.ejs
    ├── error.ejs
    └── index.ejs
```

项目依赖配置 `package.json`

`package.json` 里面有项目依赖配置及开发者信息。
在dependencies后面写上依赖的包名和版本号,然后在项目根目录执行npm install就可以像cocopods一样一次性安装包依赖

## 路由 Routes
路由用来处理URL的访问

`index.js`

```
var express = require('express');   获取express对象
var router = express.Router();      获取router对象
```

router有get(),post(),put(),delete()对象,代表接受的请求方式,对应查,增,改,删

```
router.get('/getSomething',function(req,res,next) {});
router.post('/post', function (req,res) {});
router.put('/put',function(req,res,next) {});
router.delete('/delete',function(req,res,next) {});
```

方法中第一个参数意味着请求路径,例如第一个的请求路径是`http://localhost:3000/getSomething`,第二个参数是获取请求内容和准备返回的响应体.

## Request获取请求参数

例如请求发送了id参数,则`var id = req.params.id;`可以取得
Response返回响应体

`send()`方法向浏览器发送一个响应信息
例如想返回一个json,则res.send({test:id = ${id},name = ${name}});
当参数为一个Number时，并且没有上面提到的任何一条在响应体里，Express会帮你设置一个响应 体，比如：200会返回字符”OK”。
res.send(200); // OK
res.send(404); // Not Found
res.send(500); // Internal Server Error

## Response重定向

`res.redirect("http://www.hubwiz.com");`

## Response渲染页面

如果想渲染`hello.ejs`页面,`res.render('hello',{title:"MySQL",test_params:'aaa'});`
`hello.ejs`页面通过`<%= title %>`的方式取得title等参数

Request获取主机名,路径名

`req.host`获取主机名，`req.path`获取请求路径名

## restful 方式路由

```
router.post('/restful/:id/name/:name', function (req,res) {
  var id  = req.params.id;
  var name = req.params.name;
  console.log(JSON.stringify(req.params));
  res.send({test:`id = ${id},name = ${name}`});
});
JSON.stringify() 把js对象转成json
```

## 数据库

### MySQL
安装MySQL

`$ npm install mysql`

引入MySQL并配置
```
var mysql      = require('mysql');
var connection = mysql.createConnection({
    host     : 'localhost',
    user     : 'root',
    password : '123456',
    database : 'csdn_test',
    port     : 3306
});
```

连接数据库

```
connection.connect()
```

这个方法可以接受一个回调用来判断是否连接成功

```
connection.connect(function(err) {
    if (!err) {
   		// 连接成功
     } else {
      // 连接失败 
     }
});
connection.end();
```

#### 查询

```
connection.query('SELECT 1 + 1 AS solution', function(err, rows, fields) {
  if (err) throw err;
  console.log('The solution is: ', rows[0].solution);
});
```

同上,接受一个回调来判断是否成功关闭连接

`connection.end(err => console.log(`连接中断${err}`));'

### MongoDB

安装

`npm install -g mongoose`
配置

```
var mongoose = require('mongoose');
var options = {
    db_user: "root",
    db_pwd: "123456",
    db_host: "localhost",
    db_port: 27017,
    db_name: "csdn_test"
};
```

#### 连接

```
var dbURL = "mongodb://" + options.db_user + ":" + options.db_pwd + "@" + options.db_host + ":" + options.db_port + "/" + options.db_name;

// 连接
mongoose.connect(dbURL);

// 监听连接事件
mongoose.connection.on('connected', function (err) {
    if (err) logger.error('Database connection failure');
});

// 监听错误事件
mongoose.connection.on('error', function (err) {
    logger.error('Mongoose connected error ' + err);
});

// 监听断开事件
mongoose.connection.on('disconnected', function () {
    logger.error('Mongoose disconnected');
});
查询

mongoose.collection('mamals').find().toArray(function(err, result) {
  if (err) throw err;
  console.log(result);
});
```

其他方法以后遇到再补充.