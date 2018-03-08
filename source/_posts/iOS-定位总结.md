title: iOS-定位总结
author: Arclin
tags:
  - iOS
categories:
  - iOS
date: 2016-10-29 00:00:00
---
iOS-定位总结
<!-- more -->

info.plist 请求用户位置授权

```
<key>NSLocationWhenInUseUsageDescription</key>
	<string>需要使用位置</string>
<key>NSLocationAlwaysUsageDescription</key>
	<string>需要使用位置</string>
```

代码


language: 要生成的位置信息的语言（’China‘还是’中国‘）

 - 中文 : @”zh-hans”
 - 英文 : @”en”
 - 日文 : @”jp”

```
- (void)locationWithLanguage:(NSString *)language location:(void(^)(NSString *country,NSString *province))location;
```

```
@interface DKLocation()<CLLocationManagerDelegate>

@property (nonatomic,strong) CLLocationManager *locationManager;

@end
@implementation DKLocation
- (void)locationWithLanguage:(NSString *)language location:(void(^)(NSString *country,NSString *province))location
{
    
    [[self rac_signalForSelector:@selector(locationManager:didUpdateToLocation:fromLocation:) fromProtocol:@protocol(CLLocationManagerDelegate)] subscribeNext:^(RACTuple *tuple) {
        // 停止位置更新
        CLLocationManager *manager = tuple.first;
        CLLocation *newLocation = tuple.second;
        
        [manager stopUpdatingLocation];
        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;
        // 保存 Device 的现语言
        NSString *userDefaultLanguages = DKUserDefaults(kAppLanguage);
        // 强制 成 英文
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:language,nil] forKey:@"AppleLanguages"];
        // 逆地理编码
        CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            if(!error){
                for (CLPlacemark * placemark in placemarks) {
                    NSString *provinceName = placemark.administrativeArea;
                    NSString *country = placemark.country;
                    location(country,provinceName);
                    DKLog(@"%@%@",country,provinceName);
                    break;
                }
            }
            // 还原Device 的语言
            [[NSUserDefaults standardUserDefaults] setObject:@[userDefaultLanguages] forKey:@"AppleLanguages"];
        }];

    }];
    
    // 初始化定位管理器
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    // 设置定位精确度到米
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    // 设置过滤器为无
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization];
    }
    //开始定位，不断调用其代理方法
    [_locationManager startUpdatingLocation];
    
}

@end
```