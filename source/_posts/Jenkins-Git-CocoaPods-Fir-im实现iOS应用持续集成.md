---
title: Jenkins+Git+CocoaPods+Fir.im实现iOS应用持续集成
author: Arclin
tags:
  - Jenkins
  - Git
  - CocoaPods
  - Fir
categories:
  - iOS
abbrlink: 13ecfb47
date: 2017-02-08 00:00:00
---
Jenkins 可以定时检测 Git 上的某个分支的代码，打包生成 ipa 后直接上传到 Fir.im

<!-- more -->

### 安装 Jenkins

#### JDK
Jenkins 是基于 Java 的一个应用，所以你需要先有JDK ，安装 JDK 网上有很多资料这里就跳过了

使用 Brew 安装 Jenkins

```
brew install jenkins
```

### 启动 Jenkins

`jenkins` 或者 `java -jar /usr/local/opt/jenkins/libexec/jenkins.war --httpPort=8088` 这种方法可以指定端口号执行

如果想自动启动，需要先执行以下命令，创建启动项
`ln -sfv /usr/local/opt/jenkins/*.plist ~/Library/LaunchAgents`

可以编辑一下`~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist`这个文件
`open ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist`

想要让局域网都可以访问，需要把`–httpListenAddress=127.0.0.1`改成自己的局域网IP

手动启动启动项可以执行

```
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
```

### 配置Xcode项目

使用 CocoaPods
终端进入已有项目的目录下，执行

填写 podfile 类似下面这样子

```
target 'TestJenkins' do
	pod 'MJExtension'
  target 'TestJenkinsTests' do
    inherit! :search_paths
  end
end
```

然后执行 `pod install`

执行完成之后打开`TestJenkins.xcworkspace`

打开 `Product - Scheme - Manage Scheme`

把 `Share` 下面的勾都打上

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/888.png)


### 上传到Git
在终端进入该项目根目录，执行`git init`

在 Git托管平台上新建一个项目，得到 git 远程仓库地址，然后在项目中添加该远程地址

`git remote add origin git@git.coding.net:Arclin/TestJenkins.git`

新的项目或许还需要`git pull origin master` pull一下Readme等东西

1. `git add . ` 添加项目文件
2. `git git commit -m "initial"` 提交更改
3. `git push origin master` 推送到 master远程分支

### 配置 Jenkins

在浏览器中打开 Jenkins,比如我指定了8088端口的话，那就打开`http://localhost:8088/`,然后根据提示安装，注意里面有一个选择插件的界面，根据需要选择就好。

#### 安装插件
系统管理 - 插件管理 可以安装插件,建议安装

- Git Server Plugin  
- Git Client Plugin  
- fir-plugin  （安装教程看 http://www.jianshu.com/p/9a245918a219）
- Xcode integration
- Keychains and Provisioning Profiles Management

下面我们就会用上这些插件

#### 新建一个Job

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/999.png)

进行一系列配置
设置包的保留天数还有天数。

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1001.png)

源码管理

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1002.png)

要先配置SSH Key，在Jenkins的证书管理中添加SSH。在Jenkins管理页面，选择“Credentials”，然后选择“Global credentials (unrestricted)”，点击“Add Credentials”，如下图所示，我们填写自己的SSH信息，然后点击“Save”，这样就把SSH添加到Jenkins的全局域中去了。

![](http://upload-images.jianshu.io/upload_images/1194012-6d1b6f56e4dac318.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

构建触发器
构建触发器设置这里是设置自动化测试的地方。这里涉及的内容很多，暂时我也没有深入研究，这里暂时先不设置。有自动化测试需求的可以好好研究研究这里的设置。

不过这里有两个配置还是需要是配置的

Poll SCM (poll source code management) 轮询源码管理
需要设置源码的路径才能起到轮询的效果。一般设置为类似结果： 0/5 每5分钟轮询一次
Build periodically (定时build)
一般设置为类似： 00 20 * 每天 20点执行定时build 。当然两者的设置都是一样可以通用的。

格式是这样的

分钟(0-59) 小时(0-23) 日期(1-31) 月(1-12) 周几(0-7,0和7都是周日)

例如 `H/10 * * * *` 就是每十分钟一次

#### 构建环境
iOS打包需要签名文件和证书，所以这部分我们勾选“Keychains and Code Signing Identities”和“Mobile Provisioning Profiles”。

在这之前

在系统设置中进入Keychains and Provisioning Profiles Management页面，点击“浏览”按钮，分别上传自己的keychain和证书（是这里需要的Keychain，并不是cer证书文件。这个Keychain其实在/Users/管理员用户名/Library/keychains/login.keychain,当把这个Keychain设置好了之后，Jenkins会把这个Keychain拷贝到/Users/Shared/Jenkins/Library/keychains这里，(Library是隐藏文件)。Provisioning Profiles文件也直接拷贝到/Users/Shared/Jenkins/Library/MobileDevice文件目录下）。上传成功后，我们再为keychain指明签名文件的名称。点击“Add Code Signing Identity”，最后添加成功后如下图所示

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1003.png)

password 填写你的用户密码

Code Signing Identity 的内容来源是这里


![](https://wiki.jenkins-ci.org/download/attachments/68386839/codesigning_Key_1.png?version=1&modificationDate=1375867279000)

![](https://wiki.jenkins-ci.org/download/attachments/68386839/codesigning_Key_2.png?version=2&modificationDate=1375868440000)

Provision Profiles Directory Path 的内容填上

`/Users/Shared/Jenkins/Library/MobileDevice`

![](https://wiki.jenkins-ci.org/download/attachments/68386839/Screen+Shot+2013-08-07+at+14.17.05.png?version=1&modificationDate=1375877888000)

回到项目配置

这样子填写

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1004.png)

#### 构建
点击”增加构建步骤”,先后选择 XCode 和 Execute Shell

XCode 配置如下

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1005.png)
![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1006.png)
![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1007.png)

Execute Shell 只要写入这个命令就好

`fir publish /Users/Arclin/.jenkins/workspace/TestJenkins/build/TestJenkins.ipa --token=你的fir.im Token`

如果没安装 fir 命令行工具的话

用`gem install fir-cli` 安装
如果发现问题就看这里

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1008.png)

然后保存回到Jenkins项目首页，点击立即构建，然后如果成功的话就会像下图那样子

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1009.png)

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/1010.png)

每隔一个触发器设定的时间，他就会检查一下 git 上面的代码，如果有发现更新就会自动 pull然后打包并上传到 fir.im

结束