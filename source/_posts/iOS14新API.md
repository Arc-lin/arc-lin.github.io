---
title: iOS 14新API
abbrlink: 36f1cd4f
date: 2020-06-29 11:08:18
tags:
  - iOS
  - feature
categories:
  - iOS
---

iOS 14 新API

<!-- more -->

### Control Appearance update

控件外观更新，比如UISlider、 UIProgressView、UIActivityIndicatorView，长得稍微有点不一样，不影响适配。

![](https://s1.ax1x.com/2020/06/29/NfJ6zt.png)

UIPageControl样式改变并且可以自定义icon

![](https://s1.ax1x.com/2020/06/29/NfYs7F.png)

自定义小心心icon和书签icon

![](https://s1.ax1x.com/2020/06/29/NfYO1I.png)


### Color Picker

新增颜色选择器`UIColorPickerViewController`

支持取色器 收藏常用颜色等等

可以配置是否支持调整透明度等等，具体配置项目参考api文档

建议Present弹出

<a href="https://sm.ms/image/iz1WnGFImlUvkty" target="_blank"><img src="https://i.loli.net/2020/06/29/iz1WnGFImlUvkty.png" width=50% ></a>

### Date Picker

UIDatePicker更新UI

两种样式

支持农历

<a href="https://sm.ms/image/wMmTIykghRNqWQn" target="_blank"><img src="https://i.loli.net/2020/06/29/wMmTIykghRNqWQn.png" width=50% ></a>

<a href="https://sm.ms/image/uF3WonxPAsDyXaO" target="_blank"><img src="https://i.loli.net/2020/06/29/uF3WonxPAsDyXaO.png" width=50% ></a>

### Menus 

貌似可以替代我们常有的角标弹窗列表按钮需求

基于`UIButton`和`UIBarButtonItem`的新增的`menu`属性，可以配置长按或者单击(配置 `button.showsMenuAsPrimaryAction = true`)弹出菜单列表

<a href="https://sm.ms/image/L1XmoD2d7EKj49Y" target="_blank"><img src="https://i.loli.net/2020/06/29/L1XmoD2d7EKj49Y.png" width=50% ></a>

<a href="https://sm.ms/image/ZflMaksQFDuKp3T" target="_blank"><img src="https://i.loli.net/2020/06/29/ZflMaksQFDuKp3T.png" width=50% ></a>


UINavigationBar 的原生返回按钮长按会弹出菜单，可以跳回导航栏栈中的任意一个页面，按钮标题为前面控制器的标题


<a href="https://sm.ms/image/FVdgXvpGeTBfYKZ" target="_blank"><img src="https://i.loli.net/2020/06/29/FVdgXvpGeTBfYKZ.png" width=50% ></a>


更新弹出菜单内容，将会实时更新并自带系统动画：

`updateVisibleMenu(_ block: (UIMenu) -> UIMenu)`

### UIActions

UIBarButtonItem 新增 fixedSpace(width:) 和 flexibleSpace方法 去调节item之间的间隔，不用像之前那样子创建一个fixedSpace类型的UIBarButtonItem去占位

UIButton新增了一个初始化方法init(type:primaryAction:) type默认为.system 标题为primaryAction.title ，图片为 primaryAction.image


### WidgetKit 

iOS14 重大新特性之一 支持三种宽度的widget，具体内容另外开篇再讲
<a href="https://sm.ms/image/eiXyvjhfgAqQURr" target="_blank"><img src="https://i.loli.net/2020/06/29/eiXyvjhfgAqQURr.png" width=50% ></a>


### 让你的app支持物理键盘

[具体内容查看文档](https://developer.apple.com/documentation/uikit/keyboards_and_input/adding_hardware_keyboard_support_to_your_app)

### Asynchronously Loading Images into Table and Collection Views

[文档](https://developer.apple.com/documentation/uikit/uiimage/asynchronously_loading_images_into_table_and_collection_views)

tableView和CollectionView异步加载网络图片的API

### PHPicker 图片选择器

新的图片选择器，支持多选，不需要用户允许相册访问权限，可以选择图片（包括livePhoto）和视频

<a href="https://sm.ms/image/R9fc3SZIlpLhuwB" target="_blank"><img src="https://i.loli.net/2020/06/29/R9fc3SZIlpLhuwB.png" width=50% ></a>

### 定位权限更新

旧的定位权限弹窗如下：

<a href="https://sm.ms/image/kSgBdY3hjRWG21E" target="_blank"><img src="https://i.loli.net/2020/06/29/kSgBdY3hjRWG21E.png" width=50% ></a>

新的定位权限弹窗如下：

<a href="https://sm.ms/image/svo9OnAS1BZdLDP" target="_blank"><img src="https://i.loli.net/2020/06/29/svo9OnAS1BZdLDP.png" width=50% ></a>

多了个小地图，并且小地图的左上角多了个按钮，点击选择是否允许准确定位。

若不允许的话，开发者获取的定位会变成一个±5公里的范围，并且只能持续定位最多20分钟

通过一个枚举值得知是否用户选择了模糊定位：

<a href="https://sm.ms/image/9gh6mbKL7VWe3uH" target="_blank"><img src="https://i.loli.net/2020/06/29/9gh6mbKL7VWe3uH.png" ></a>

用户可以改变设置，是否允许app获取准确定位

<a href="https://sm.ms/image/jsQr4xoevXNa2Ju" target="_blank"><img src="https://i.loli.net/2020/06/29/jsQr4xoevXNa2Ju.png" ></a>

开发者可以通过在`info.plist`里面配置信息解释为何需要用户选择准确定位

<a href="https://sm.ms/image/X5CRUopcnOHG3I2" target="_blank"><img src="https://i.loli.net/2020/06/29/X5CRUopcnOHG3I2.png" ></a>

让隐私弹窗默认选择模糊定位

<a href="https://sm.ms/image/UeLtJhGXOvbKmns" target="_blank"><img src="https://i.loli.net/2020/06/29/UeLtJhGXOvbKmns.png" width=50%></a>

### UICollectionView重大更新

UICollection从数据源协议到Cell都有了新的API，开发者可以为cell添加各种“附件”，已适配复杂的列表样式，如下第二张图，另外可以在collectionView上使用类似tableView的样式，如下图

<a href="https://sm.ms/image/Iaho8TuHE1P4iRx" target="_blank"><img src="https://i.loli.net/2020/06/30/Iaho8TuHE1P4iRx.png" ></a>

<a href="https://sm.ms/image/taEDOVHfAk2LnQe" target="_blank"><img src="https://i.loli.net/2020/06/30/taEDOVHfAk2LnQe.png"  width=50% ></a>

通过新的配置类，可以做成如下效果

<a href="https://sm.ms/image/nlrR8VBkzqy2SdP" target="_blank"><img src="https://i.loli.net/2020/06/30/nlrR8VBkzqy2SdP.png"  width=50% ></a>

<a href="https://sm.ms/image/PhtUgJrCR2OTQwY" target="_blank"><img src="https://i.loli.net/2020/06/30/PhtUgJrCR2OTQwY.png"  width=50% ></a>

新增一个UICollectionListViewCell，可以做出如下样式的cell

<a href="https://sm.ms/image/jlZKFpCybNJPoET" target="_blank"><img src="https://i.loli.net/2020/06/30/jlZKFpCybNJPoET.png" width=50%  ></a>

Cell的注册方式也有所改变，可以看出苹果从API层面已经进入MVVM架构模式了，注册cell需要带上对应的CellViewModel

<a href="https://sm.ms/image/2awdL6yOmUzIGrZ" target="_blank"><img src="https://i.loli.net/2020/06/30/2awdL6yOmUzIGrZ.jpg" width=50% ></a>

另外也支持像UITableViewCell的侧滑操作等等，详细内容将会另外开篇讲述。

具体查看[视频](https://developer.apple.com/videos/play/wwdc2020/10097/)