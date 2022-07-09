title: 汇编指令记录
author: Arclin
date: 2021-12-26 16:35:14
tags:
---
记录一些常用的汇编指令
<!--more-->
AT&T汇编 -> iOS模拟器
ARM汇编 -> iOS真机设备 

|项目|AT&T|lntel|说明|
|---|---|---|---|
|寄存器命名|%rax|rax||
|操作数顺序|movq %rax,%rdx|mov rdx,rax|将rax的值复制给rdx|
|常数\立即数|movq $3,%rax<br/>movq $0x10,%rax|mov rax,3<br/>mov rax,0x10|将3赋值给rax,将0x10赋值给rax|
|内存赋值|movq $0xa,0x1ff7(%rip)|mov qword prt [rip+0x1ff7],0xa|将0xa赋值给地址为rip+0x1ff7的内存空间|
|取内存地址|leaq -0x18(%rbp),%rax|lea rax,[rbp - 0x18]|将rbp-0x18这个地址赋值给rax|
|jmp指令|jmp *%rdx<br/>jmp 0x4001002<br/>jmp *(%rax)|jmp rdx</br>jmp 0x4001002<br/>jmp [rax]|call和jmp写法类似|
|操作数长度|movl %eax,%edx<br/>movb $0x10,%al<br/>leaw 0x10(%dx),%ax|mov edx,eax<br/>mov al,0x10<br/>lea ax,[dx + 0x10]|b = byte(8-bit)<br/>s=short(16-bit integer or 32-bit floating point)<br/>w=word(16-bit)<br/>l=long(32-bit integer or 64-bit floating point)<br/>q=quad(64 bit)<br/>t=ten byts(80-bit floating point)|

操作数长度意味着赋值的时候，右边地址需要分配多少空间给左边的地址所带的值

寄存器名字：
r开头：64bit，8字节
e开头：32bit，4字节
ax,bx,cx：2字节
ah al：8bit，1字节

lldb常用指令：
- 读取寄存器的值
	- register read/格式
    - register read/x
    
- 修改寄存器的值
	- register write 寄存器名称 数值
    - register write rax 0
    
- 读取内存中的值
	- x/数量-格式-字节大小 内存地址
    - x/3xw 0x0000010
    
- 修改内存中的值
	- memory write 内存地址 数值
    - memory write 0x00000010 10
    
- 格式
	- x是16进制，f是浮点，d是十进制
    
- 字节大小
	- b - byte 1字节
    - h - half word 2字节
    - w - word 4字节
    - g - giant word 8字节
    
- thread step-over、next、n
	- 单步运行，把子函数当做整体一步执行（源码级别）
    
- thread step-in、step、s
	- 单步运行，遇到子函数会进入子函数（源码级别）
    
- thread step-inst-over、nexti、ni
	- 单步运行，把子函数当做整体一步执行（汇编级别）
   
- thread step-inst、stepi、si
	- 单步运行，遇到子函数会进入子函数（汇编级别）
 
- thread step-out、finish
 	- 直接执行完当前函数的所有代码，返回到上一个函数（遇到断点会卡住）
    
rip存储的是指令的地址
CPU要执行的下一条指令地址就存储在rip中
