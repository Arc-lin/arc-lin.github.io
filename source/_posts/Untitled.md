---
title: 'Apache强制https '
author: Arclin
tags:
  - https
categories:
  - Linux
abbrlink: f6ce3122
date: 2018-02-18 21:50:00
---
当用户访问http的地址的时候，Apache如何强制跳转到https地址

<!-- more -->

修改httpd.conf

1. LoadModule rewrite_module modules/mod_rewrite.so 这个拓展貌似是已经被加载了；
2. 修改Apache默认项目路径的这个

```
<Directory "/var/www/html">
```

其实是修改为项目发布的路径
```
<Directory "/var/www/html/app/src/htdocs_www">
```
改为All

```
AllowOverride All
```


```
# 
# Possible values for the Options directive are "None", "All", 
# or any combination of: 
# Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews 
# 
# Note that "MultiViews" must be named *explicitly* --- "Options All" 
# doesn't give it to you. 
# 
# The Options directive is both complicated and important. Please see 
# http://httpd.apache.org/docs/2.2/mod/core.html
# options 
# for more information. 
# Options Indexes FollowSymLinks 
# 
# AllowOverride controls what directives may be placed in .htaccess files. 
# It can be "All", "None", or any combination of the keywords: 
# Options FileInfo AuthConfig Limit 
# 
# 
# Controls who can get stuff from this server. 
# 
Order allow,deny 
Allow from all
```

添加三行代码

```
RewriteEngine on
RewriteCond %{SERVER_PORT} !^443$
RewriteRule ^(.*)?$ https://%{SERVER_NAME}/$1 [L,R]
```