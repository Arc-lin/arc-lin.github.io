---
title: MongoDB笔记
author: Arclin
tags:
  - MongoDB
categories:
  - MongoDB
abbrlink: b3b38c86
date: 2018-02-18 21:58:00
---
MongoDB笔记

<!-- more -->

OS X安装

`brew install mongodb`

进入mongodb

`mongo`

查看所有数据库

`db`

查看所有*有数据的*数据库并带上内存信息

`show dbs`

创建/进入某个数据库

`use DATABASE_NAME`

删除数据库(需要先`use DATABASE_NAME` 进入数据库)

`db.dropDatabase()`

插入数据

`db.DATABASE_NAME.insert({“COLUMN_NAME”:”VALUE”,”COLUMN_NAME_SECOND”:”SECOND_VALUE”})`

查询所有数据

`db.DATABASE_NAME.find()`

查询所有数据并pretty形式打印

`db.DATABASE_NAME.find().pretty()`

更新满足条件的第一条数据

`db.DATABASE_NAME.update({‘条件字段’:’条件值’},{$set:{‘更新字段’:’更新值’,‘更新字段2’:’更新值2’}})`

更新满足条件的所有数据

`db.DATABASE_NAME.update({‘条件字段’:’条件值’},{$set:{‘更新字段’:’更新值’,‘更新字段2’:’更新值2’},{multi:true}})`

替换整条数据的内容(根据ID查找)

`db.DATABASE_NAME.save({“_id”:ObjectId(“xxxxx”),”要替换的字段名”:”要替换的字段名”,”要替换的字段名2”:”要替换的字段名2”})`

删除数据

`db.DATABASE_NAME.remove({‘条件字段’:’条件值’})`

删除第一条找到的记录

`db.DATABASE_NAME.remove({‘条件字段’:’条件值’},1)`

删除所有数据(请空表)

`db.DATABASE_NAME.remove({})`






