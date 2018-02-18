title: 用flow.ci做iOS的持续化集成
author: Arclin
tags:
  - Flow.ci
  - iOS
categories:
  - iOS
date: 2017-02-24 00:00:00
---
听说flow.ci上线公测了,赶紧拿着一把限时免费资格玩一玩体验一下.

<!-- more -->

结论: 一套下来行云流水,配置上基本没啥大问题,感觉还是挺好用的.可以支持简单的项目

官方中文文档在这里

里面讲的相当详细,在这里我就讲点注意点就好

1. 如果你想达到的功能除了编译打包外,还想上传到fir,并且想拿最新的git commit 信息作为fir版本更新备注,那么你的工作流可以这么配
![](https://github.com/Arc-lin/BlogImage/blob/master/1012.png?raw=true)
2. ‘自定义脚本’里面写的是export CHANGE_LOG=$(git log --pretty=format:"%s" -1 $describe) 然后 fir.im 上传插件 中 FIR_CHANGELOG就直接写$CHANGE_LOG这样子就可以做到拿最新的git commit 信息作为fir版本更新备注, $FIR_APP_PATH里面就直接写$FIR_APP_PATH就好了
3. ‘缓存’那里启用一下安装速度会快些
4. 如果你的git的根目录不是你项目的根目录的话,你要添加一个’环境变量’(就像上面的图),详情看这里
5. ‘编译’那里的’Workspace’,填的时候记得把’.xcworkspace’后缀带上
6. ‘编译’那里的’Workspace’和’Project’两个选一个填,不能一起填
7. 大概就这么多,以后我遇到啥再补充