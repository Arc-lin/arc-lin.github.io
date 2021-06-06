---
title: 给 APP添加外部文件导入功能
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: d2301e87
date: 2016-10-30 00:00:00
---
给 APP添加外部文件导入功能

![](https://raw.githubusercontent.com/Arc-lin/BlogImage/master/333.jpeg)

<!-- more -->

修改 info.plist(这里是允许所有文件类型,如果要特定某种类型的文件,那么就得添加多个CFBundleTypeName CFBundleTypeRole LSHandlerRank LSItemContentTypes 具体见百度)

```
<key>CFBundleDocumentTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeIconFiles</key>
           <array/>
           <key>CFBundleTypeName</key>
           <string>data</string>
           <key>CFBundleTypeRole</key>
           <string>Viewer</string>
           <key>LSHandlerRank</key>
           <string>Default</string>
           <key>LSItemContentTypes</key>
           <array>
               <string>public.data</string>
           </array>
       </dict>
   </array>
 ```
 
APPDelegate.h

获取到根控制器,执行复制到Document文件夹方法
源路径:url.path

```
@property (strong, nonatomic) NSURL *sharedURL;

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
	if(url.fileURL){
        self.sharedURL = url;
        UIViewController *vc = self.window.rootViewController;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController * nav = (UINavigationController *)self.window.rootViewController;
            UIViewController *topVC = nav.childViewControllers.firstObject;
            if ([topVC respondsToSelector:@selector(handleSharedFile)]) {
                [topVC performSelectorOnMainThread:@selector(handleSharedFile) withObject:nil waitUntilDone:NO];
            }
        } else {
            if ([vc respondsToSelector:@selector(handleSharedFile)]) {
                [vc performSelectorOnMainThread:@selector(handleSharedFile) withObject:nil waitUntilDone:NO];
            }
        }
    }
}
```

根控制器方法(头文件需要声明方法)

```
- (void)handleSharedFile {
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (app.sharedURL != nil) {
        self.sharedURL = [app.sharedURL copy];
        app.sharedURL = nil;
        [self saveSharedFile:self.sharedURL];
    }
}
- (void)saveSharedFile:(NSURL *)url {
    MBProgressHUD *hud = [MBProgressHUD showButtonHUDAddedTo:self.view animated:YES];
    DKFile *file = [[DKFile alloc] init];
    file.fullPath = url.path;
    file.fileName = url.path.lastPathComponent;
    [[DKFileManager sharedInstance] copyItemsOfSelectFiles:@[file] fromStorage:DKFileStorageTypeInternal toStorage:DKFileStorageTypeInternal toPath:[DKFileManager defaultPath:kShareDirectory storage:DKFileStorageTypeInternal] progressHUD:hud complete:^{
        [SVProgressHUD showSuccessWithStatus:@"已保存到 iPhone -> SharedFiles"];
    } failure:^(NSError *errors) {
        
    }];
}
```