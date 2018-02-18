title: iOS从服务器下载DAE文件并动态加载到SCNScene
author: Arclin
tags:
  - iOS
  - Scene Kit
  - ''
categories:
  - iOS
date: 2017-02-23 00:00:00
---
ViewController 已有 SCNScene,怎么从服务器下载3D模型文件(DAE)然后加载到这个 SCNScene呢？

<!-- more -->

1. 由于 `SCNScene` 不支持动态加载 DAE 文件，或者说不支持动态加载 `COLLADA` 方案下的所有3d 类型，但是测试发现直接把 DAE 文件放进 `arc.scnassets` 文件夹下的时候是可以加载的，可见系统编译的时候应该是做了某些手脚，查询资料后发现系统是执行了两个脚本，两个脚本的路径分别是`/Applications/Xcode.app/Contents/Developer/usr/bin/copySceneKitAssets`和
`/Applications/Xcode.app/Contents/Developer/usr/bin/scntool` 所以先把这两个文件拷出来

2. 新建一个文件夹，命名是 自定义名字.scnassets,例如abc.scnassets

3. 把模型文件放在里面,然后在这个文件夹外面放上copySceneKitAssets和scntool
4. 终端执行./copySceneKitAssets abc.scnassets -o abc-o.scnassets 如果没问题的话就会生成一个 abc-o.scnassets 文件夹
5. 打包 zip 上传服务器
6. 代码下载 zip包,解压,然后载入文件

```
documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:@"abc-o.scnassets/test.dae"];
SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:documentsDirectoryURL options:nil];
SCNNode *theCube = [sceneSource entryWithIdentifier:@"Cube" withClass:[SCNNode class]];
```
或者使用SCNScene这个方法

```
+ (nullable instancetype)sceneWithURL:(NSURL *)url options:(nullable NSDictionary<SCNSceneSourceLoadingOption, id> *)options error:(NSError **)error;
```
也是可以的

