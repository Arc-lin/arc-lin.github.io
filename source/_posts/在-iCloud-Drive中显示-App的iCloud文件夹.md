---
title: 在 iCloud Drive中显示 App的iCloud文件夹
author: Arclin
tags:
  - iOS
categories:
  - iOS
abbrlink: 3eb7dc04
date: 2016-10-29 00:00:00
---
1. 修改 info.plist

  ```
  <key>NSUbiquitousContainers</key>
      <dict>
          <key>iCloud.com.example.app</key>
          <dict>
              <key>NSUbiquitousContainerIsDocumentScopePublic</key>
              <true/>
              <key>NSUbiquitousContainerName</key>
              <string>App name to display in iCloud Drive</string>
              <key>NSUbiquitousContainerSupportedFolderLevels</key>
              <string>None</string>
          </dict>
      </dict>
  ```

2. 修改版本构件号(必改)