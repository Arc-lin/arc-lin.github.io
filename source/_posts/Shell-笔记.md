title: Shell 笔记
author: Arclin
abbrlink: cfe784af
date: 2018-05-17 16:10:25
tags:
---
Shell 笔记，有机会写就会继续补充
<!--more-->

1. if语句的中括号要留空格  `if空格[空格 判断语句 空格]; then xxx fi` 
2. 判断买某个路径是否是文件夹  `if [ -d “./xxx” ]; then xxx fi`
3. 建立一个数组 `check=("Wechat" "Ali" "Union" "Pay")`
4. 声明一个函数, 并取得第一个参数
	```
    function xxx() {
    	dir=$1
    }
    ```
5. 获得某个后缀名的文件 `directory=./${d%.*}".app"`
6. 执行某个命令但不输出到控制台 `unzip $xxx > /dev/null 2>&1`
7. 声明某个变量为局部变量，使用`local`关键字 `local dir=$1`
8. 大写转小写 `local file_name_lower=$(echo $file_name | tr 'A-Z' 'a-z')`
9. 小写转大写 `local file_name_lower=$(echo $file_name | tr 'a-z' 'A-Z')`
10. 遍历数组
  ```
  for item in ${check[@]}; do
      echo $item
  done
  ```
11. 字符串A是否包含字符串B `if[[ $A =~ $B ]]; then xxx fi`