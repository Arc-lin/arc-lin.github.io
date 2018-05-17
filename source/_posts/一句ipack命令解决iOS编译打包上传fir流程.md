---
title: 一句ipack命令解决iOS编译打包上传fir流程
author: Arclin
tags:
  - Fir
  - shell
categories:
  - iOS
abbrlink: 4edc914d
date: 2017-02-14 00:00:00
---
一行命令即可将包含 cocoapods 的iOS 项目编译打包并上传到 fir
<!-- more -->

### 准备工具
 - fir-cli
 - Cocopods
 
### 功能

进入任意一个有.xcodeworksapce文件的目录下，输入ipack（可以自定义）即可完成编译打包上传，加上-c 更新说明
参数就可以填写本次打包的更新说明，这个说明会在 fir 上面显示出来

### 编写shell脚本

sh代码说明

变量定义

`basepath=$(pwd)`  命令行代码执行位置
`bName=$(basename ${basepath})`  拿到项目文件夹名字
`description=$(basename ${basepath})` 要写在 fir 的更新说明
`achivepath=${basepath}'/build/'${bName}'.xcarchive'` 构建文件的储存位置

`ipaPath=${basepath}'/'${bName}'.ipa'` ipa 的储存位置

拿到参数

```
while getopts ":c:" opt; do` # 遍历参数 虽然现在只有一个，不过为了拓展还是可以加上去
case $opt in
    c ) description="$OPTARG";;   # 如果参数是c 的话就把内容赋值给description
    ? ) echo "参数选项不正确，应该是 -c <发布内容>"
        exit 1;;
    esca
done
```

判断命令是不是执行在有`.xcodeworksapce`文件的目录下

`$(ls *.xcwork* >/dev/null 2>&1)`

清除缓存

```
/usr/bin/xcodebuild -target　${bName} clean
```

编译

```
/usr/bin/xcodebuild -exportArchive -exportFormat ipa -archivePath ${achivepath} -exportPath ${ipaPath}
```

判断编译成功了吗

`if [ ! -d ${achivepath} ];`

打包

/usr/bin/xcodebuild -exportArchive -exportFormat ipa -archivePath ${achivepath} -exportPath ${ipaPath}

判断打包成功了吗

`if [ ! -f ${ipaPath} ];`

上传到 fir

```
fir publish ${bName}.ipa --token <你的 Fir Token> -c ${description}
```

firToken 的位置

![](/images/pasted-0.png)

清理编译打包的文件

```
rm -rf ${ipaPath} ${achivepath}
```

完事

执行
如果你把 sh文件放在桌面的话，一般来说现在去到有.xcodeworksapce文件的目录下，执行

```
~/Desktop/iosPackage.sh
```

就可以了，加个参数就是

```
~/Desktop/iosPackage.sh -c "测试测试"`
```

但是`~/Desktop/iosPackage.sh`太长了，所以得给他加个别名

所以执行

```
cd ~
touch .bash_profile
```

创建一个`.bash_profile`文件

然后在里面填写 `alias ipack='~/Desktop/iosPackage.sh'`
这个`ipack`你想写啥就啥

然后保存之后执行

`source ./bash_profile`

之后就可以直接用 ipack 代替 `~/Desktop/iosPackage.sh`

`ipack ipack -c "测试测试"`

END