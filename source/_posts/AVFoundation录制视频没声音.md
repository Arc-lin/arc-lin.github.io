title: AVFoundation录制视频没声音?
author: Arclin
tags:
  - iOS
categories:
  - iOS
date: 2017-03-04 00:00:00
---
先说结论 , 加一行代码 

```
_captureMovieFileOutput.movieFragmentInterval = kCMTimeInvalid
```

<!-- more -->

看看`movieFragmentInterval` 属性的说明

```
/*!
 @property movieFragmentInterval
 @abstract
    Specifies the frequency with which movie fragments should be written.

 @discussion
    When movie fragments are used, a partially written QuickTime movie file whose writing is unexpectedly interrupted can be successfully opened and played up to multiples of the specified time interval. A value of kCMTimeInvalid indicates that movie fragments should not be used, but that only a movie atom describing all of the media in the file should be written. The default value of this property is ten seconds.

    Changing the value of this property will not affect the movie fragment interval of the file currently being written, if there is one.
 */
@property(nonatomic) CMTime movieFragmentInterval;
```

用拙略的英语水平翻译一下就是,`movieFragmentInterval`这东西代表一个时间间隔,每隔x秒就会把视频片段写入内存,这是为了保证当意外中断视频文件写入的时候还可以有一个可以播放的视频片段,默认是十秒,如果你给他赋了这个值`kCMTimeInvalid`,就表示要一直写入直到调用某个方法结束视频录制,之后他就会给视频文件加上文件尾部,所以如果没有设置这个值的话,十秒到二十秒的视频中间就会出现没声音的状况.
