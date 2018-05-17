---
title: ipad和iphone使用UIAlertViewController
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: f0080c3e
date: 2016-10-17 00:00:00
---
ipad和iphone使用UIAlertViewController

```
id aController;
    if(DKDeviceiPad){
    alertC.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popPc = alertC.popoverPresentationController;
    popPc.barButtonItem = self.downloadItem;
    popPc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    aController = alertC;
}else{
    aController = alertC;
}
[window.rootViewController presentViewController:aController animated:YES completion:nil];
```