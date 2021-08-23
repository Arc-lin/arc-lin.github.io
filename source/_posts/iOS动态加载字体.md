title: iOS动态加载字体
tags:
  - iOS
categories:
  - iOS
abbrlink: f82939c6
date: 2021-03-17 10:42:42
---
当你某个在开发某个SDK时需要使用到特殊字体，因为无法修改应用的info.plist，所以这时候我们需要采用动态注册字体的方式加载字体，方法如下

<!--more-->

- OC

	方法调用
	
	```oc
	[UIFont fontWithName:<#(nonnull NSString *)#> size:<#(CGFloat)#>]
	```

	如果上述方法返回nil,则你需要注册你的字体
	```oc
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *fontURL = [bundle URLForResource:<#fontName#> withExtension:@"otf"/*or TTF*/];
    NSData *inData = [NSData dataWithContentsOfURL:fontURL];
    CFErrorRef error;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
    CFStringRef errorDescription = CFErrorCopyDescription(error);
    NSLog(@"Failed to load font: %@", errorDescription);
    CFRelease(errorDescription);
    }
    CFSafeRelease(font);
    CFSafeRelease(provider);
	```

	```objective-c
    void CFSafeRelease(CFTypeRef cf) {
        if (cf != NULL) {
            CFRelease(cf);
        }
    }
	```
	
- Swift

	方法调用
	```swift
	UIFont.customFont(name:"xxx" size: 12)
	```

	```swift
    extension UIFont {
	    static func customFont(fontName:String, size: CGFloat) -> UIFont {
        if let font = UIFont(name: fontName, size: size) {
            return font
        } else {
            _ = self.registerFont(bundle: Bundle.init(for: XXXX.self), fontName: fontName, fontExtension: "otf") // 也可以写ttf,看具体格式
            if let newFont = UIFont(name: fontName, size: size) {
                return newFont
            }
            return UIFont.customFont(ofSize: size)
        }
    }
    
    static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) -> Bool {
        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension) else {
            fatalError("Couldn't find font \(fontName)")
        }
        
        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL) else {
            fatalError("Couldn't load data from the font \(fontName)")
        }
        
        guard let font = CGFont(fontDataProvider) else {
            fatalError("Couldn't create font from data")
        }
        
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterGraphicsFont(font, &error)
        guard success else {
            print("Error registering font: maybe it was already registered.")
            return false
        }
        
        return true
    }

	```
	
参考资料：
	[https://stackoverflow.com/questions/12919513/how-do-i-add-a-custom-font-to-a-cocoapod](https://stackoverflow.com/questions/12919513/how-do-i-add-a-custom-font-to-a-cocoapod)