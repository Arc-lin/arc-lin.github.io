title: 使用PHP进行webhook的注意点
author: Arclin
tags:
  - php
  - webhook
categories:
  - PHP
date: 2018-02-18 21:55:00
---
有时会编写PHP脚本进行webhook, 这里有些地方需要注意一下, 否则会导致脚本执行失败

<!-- more -->

允许某些敏感方法的执行
编辑`php.ini`

```
disable_functions = scandir,passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,
ini_alter,ini_alter,ini_restore,dl,pfsockopen,openlog,syslog,readlink,symlink,popepassthru,
stream_socket_server,fsocket,fsockopen
```

把`exec`去掉

检查`apache`用户的目录权限

apache用户公钥要配置在项目里面
也就是项目里会有两个公钥
一个是root的一个是apache的