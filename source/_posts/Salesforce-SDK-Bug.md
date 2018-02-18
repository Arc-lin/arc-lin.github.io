title: Salesforce SDK Bug
author: Arclin
tags:
  - Salesforce
categories:
  - iOS
date: 2018-02-18 21:59:00
---
Salesforce SDK 有几个bug 不修复的话跑不起来 所以在这里记录一下

<!-- more -->

1. `SFOAuthCoordinator` 960行 

```
   if ([self isRedirectURL:requestUrl]) {
        [self handleUserAgentResponse:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
```

2. `SFSDKLoginHostListViewController` `viewDidLoad`最下面的注册cell移动到`viewDidLoad`的第一行
