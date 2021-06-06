title: Jenkins上蒲公英插件中update description 无法自动写入commit message问题解决
author: Arclin
tags:
  - Jenkins
categories:
  - Jenkins
abbrlink: 5fcbb764
date: 2018-05-10 10:46:00
---
花了一天时间解决这个问题，找了好多资料都没找到，最后终于想到了办法。
<!--more-->

### 背景

在Jenkins上使用蒲公英上传软件安装包有两种方法，一种是使用命令行的方式
类似下面这种

```
IPANAME="jinkens-myapp"
fastlane gym --export_method ad-hoc --output_name ${IPANAME}

MSG=`git log -1 --pretty=%B`
PASSWORD=123456
curl -F "file=@${IPANAME}" -F "uKey=USER_KEY" -F "_api_key=API_KEY" -F "updateDescription=${MSG}" -F "password=${PASSWORD}" https://qiniu-storage.pgyer.com/apiv1/app/upload
```

这种方式的话就可以直接通过命令行获得`commit message`作为版本更新说明，但是缺点是无法直接通过环境变量获得上传后的App的各种信息，比如安装包地址，app二维码图片的等等。

第二种方式是通过蒲公英在Jenkins上发布的插件`Upload to pgyer`，优点是上传后的各种App的信息都会被注入到环境变量中，可以在邮件模板中直接调用。缺点是Upload description必须写死为某个值，或者使用某个环境变量，但是Jenkins的Git插件又不提供给你最后一条`commit message`的环境变量。

所以说为了结合两种方式的优点，想出了如下办法解决了。

### 方法

1. 安装插件	`Environment Injector Plugin`
2. 构建步骤添加`Execute Shell`，填写
	```
	# 把commit message写入文件中
	MSG=$(git log -1 --pretty=%B)
	echo "commitMessage="${MSG} > commitMessage.txt
    ```
3. 构件步骤中添加`Inject Environment variables`，`Properties File Path`填写`${WORKSPACE}/commitMessage.txt`(也有可能是别的路径，不要写错了)
4. 最后在蒲公英插件`Upload to pgyer`上`updateDescription`中填写`${commitMessage}`


就这样子就可以了，就是把message写到文件中，然后通过文件注入环境变量，然后蒲公英插件再去用就行了。