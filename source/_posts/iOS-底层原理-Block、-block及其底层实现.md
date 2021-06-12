title: iOS 底层原理 --- Block、__block及其底层实现
author: Arclin
abbrlink: 8275b854
tags:
  - iOS
  - 底层原理
categories:
  - iOS
date: 2021-06-07 23:50:00
---
本文主要简述Block、__block的本质是什么东西，文章涉及循环引用等开发常见问题，需要重点关注。

<!--more-->


## 先写一个最简单的block

```
void(^block)(void) = ^{
    NSLog(@"Block");
};

block();
```

使用命令行将`main.m`文件编译成C++文件<br/>
`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m `

编译完成后，上述代码会变成以下结构

```
void(*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA));

((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
```

可以看出是生成了一个`__main_block_impl_0`结构体类型的对象，参数1为`__main_block_func_0`，参数2为`&__main_block_desc_0_DATA`


## block的底层结构

接下来查看一下`__main_block_impl_0`是什么东西

```
/// block的结构体，引用了两个结构体和实现了一个构造方法
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

/// block的结构体引用的第一个结构体
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};

/// block的结构体引用的第二个结构体，第一个参数赋值了0，第二个参数赋值了__main_block_impl_0的结构体大小
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
```

所以拼接一下可以看出

```
struct __main_block_impl_0 {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
  size_t reserved;
  size_t Block_size;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
}
```

- ***结论1：block本质上是一个OC对象，它内部也有个isa指针***

接下来看看构造方法，第一个参数是`void *fp`意为`function pointer`函数指针，所以我们回去看看这里传了什么值进去
```
void(*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA));
```

是`__main_block_func_0`，那我们再看看`__main_block_func_0`是什么

```
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
	NSLog((NSString *)&__NSConstantStringImpl__var_folders_jj_276qbs652l5ckj94jfcx28jh0000gn_T_main_34b858_mi_0);
}

```

可以看出我们在block内写的代码被封装成了一个函数

- ***结论2：block是封装了函数调用以及函数调用环境的OC对象***

最后，看一下block的调用，被编译成了下述结构（这里我们去掉强制转换）
```
(block)->FuncPtr(block);
```

可以看出，是取出了变量中的`FuncPtr`成员变量，得到函数指针后把自己传进去，这样子就完成了block的调用

## block捕获外部变量

从上面的分析我们可以得知，局部变量的定义和使用，是在两个函数中进行的，所以为了能够给让变量跨函数访问，block需要捕获该变量 

### 局部auto类型的变量捕获

**auto ： 自动变量，离开作用域自动销毁**

平常我们定义的局部变量，默认都是`auto`修饰的

先写一个简单的demo

```
int age = 10; // 等价于 auto int age = 10;
void(^block)(void) = ^{
    NSLog(@"Block %d",age);
};
```

编译后变成如下结构(去掉强制转换)

```
int age = 10;
void(*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, age));
```

`__main_block_impl_0`也发生了变化，可以看到多了一个`age`成员变量，所以构造函数也多了一个参数

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int age;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _age, int flags=0) : age(_age) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

`age(_age)`这个语法意为将构造方法传进来的`_age`赋值到自己的的成员变量`age`，这个过程我们称作变量的**捕获**

block内编译后的函数`__main_block_func_0`也发生了变化

```
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int age = __cself->age; // bound by copy
   NSLog((NSString *)&__NSConstantStringImpl__var_folders_jj_276qbs652l5ckj94jfcx28jh0000gn_T_main_5fd8ec_mi_0,age);
}
```

可以看出函数内取出了结构体内的`age`成员变量，然后交给`NSLog`使用


由此可知，block在定义的时候就会把外部传进来的参数给存储一遍，然后调用的时候在从block对象中取出来，所以这就意味着**被block捕获的变量，在被捕获后如果修改了值，是不会应用到block中的**，举例如下

```
int age = 10;
void(^block)(void) = ^{
    NSLog(@"age = %d",age);
};
age = 20;
block(); // 调用这个方法只会输出age = 10，因为age被捕获时是10，所以后面就算改了值也没用
```

### 局部static类型的变量捕获

把上面的`age`变量加一个`static`修饰符试试看

```
static int age = 10;
void(^block)(void) = ^{
    NSLog(@"age = %d",age);
};
age = 20;
block();
```

结果会输出`age = 20`，原因是静态变量会将`static`修饰的对象转为block的指针类型的成员属性，如下

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int *age;
  ...
};

static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int *age = __cself->age; // bound by copy
  NSLog((NSString *)&__NSConstantStringImpl__var_folders_jj_276qbs652l5ckj94jfcx28jh0000gn_T_main_bb86ee_mi_0,(*age));
}
```

因为是指针传递，所以当指针指向的内容变化时，打印出来的值也就会变化了

### 全局变量不捕获

全局`static`变量不捕获，因为全局`static`变量大家都能访问，所以函数内可以直接读取值

### block内的self会被捕获吗

会，我们来举个例子

```
- (void)test {
	void(^block)(void) = ^{
    	NSLog(@"%@",self); 
    };
    block();
}
```

因为`test`方法会添加两个隐含的参数，编译后如下

```
static void _I_Person_Test(Person *self, SEL _cmd) {
	...
}
```

所以这就是为什么我们能在方法内访问`self`和`_cmd`的原因，因为方法会传进来`self`参数，又因为参数是局部变量，又因为局部变量会被捕获，所以`self`参数会被捕获，捕获后大概长这样子

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  Person *self;
  ...
};
```

## Block的类型


Block有三种类型，可以通过调用class方法或者isa指针查看具体类型，最终都是继承自NSBlock类型

|存储区域|类名|特点|调用copy后的效果|
|---|---|---|---|
|数据区域 .data区|`__NSGlobalBlock__`|没有访问auto变量|无效果|
|栈区|`__NSStackBlock__`|访问了auto变量|从栈复制到堆|
|堆区|`__NSMallocBlock__`|`__NSStackBlock__`调用了copy|引用计数增加|

### `__NSGlobalBlock__`

```
void(^block)(void) = ^{
    NSLog(@"Hello world");
};
```

### `__NSStackBlock__`

```
int age = 20;
void(^block)(void) = ^{
   NSLog(@"Block %d",age);
};
```

因为在ARC环境下，栈区block会自动copy，所以要测试这个类型的时候，需要使用MRC环境

**栈区数据的特点是会自动销毁，离开了作用域，数据都会销毁**

**栈区block存在的问题是，捕获的变量会存放在栈区，所以一旦离开了作用域，捕获的内容就销毁了，将来再去访问这个block内捕获的变量，访问到的可能就是一个未知的内容**

以下情况编译器会自动将栈上的block复制到堆上：
1. block作为函数返回值时，比如
	```
    typedef void(^Block)(void);
    Block myBlock() {
    	int age = 10
        return ^{
        	NSLog(@"---------%d",age);
        };
    }
    ```
2. 将block赋值给__strong指针时
	- __strong是是id类型和对象类型默认的所有权修饰符，所以平时在ARC环境下写的引用外部auto局部变量的block都会自动copy到堆中，原因是block默认被__strong修饰了
3. block作为Cocoa API中方法名含有usingBlock的方法参数时
	- 比如NSArray的`enumerateObjectsUsingBlock:`方法，block传进去之后就会被copy一下
4. block作为GCD API的方法参数时
	- 比如GCD的`dispatch_after(dispatch_time_t when, dispatch_queue_t queue,
		dispatch_block_t block);`方法，block传进去之后就会被copy一下


### `__NSMallocBlock__`

将`__NSStackBlock__`进行一次copy，即可得到`__NSMallocBlock__`

```
int age = 20;
void(^block)(void) = [^{
   NSLog(@"Block %d",age);
} copy];
```


## 捕获对象类型的auto变量

当block内部访问了对象类型的auto变量时，如下

```
Person *person = [[Person alloc] init];
void(^block)(void) = ^{
    NSLog(@"Person %@",person);
};
block();
```
我们在ARC环境下编译，这时候block会在堆上（因为被自动copy了），执行命令行`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m`，会发现block结构体的person属性多了一个`__strong`的修饰符，证明他被block强持有了。

```
struct __main_block_impl_0 {
  ...
  Person *__strong person;
  ...
}
```

但是我们如果编译的时候去掉`-fobjc-arc`，默认就是MRC环境了，这时候block会在栈上，查看编译后的c++文件发现不会有`__strong`修饰符，如果我们在block执行前加一行`[person release]`，那么这时候`person`就会直接释放，证明block没有持有`person变量`

- 结论1：如果block是在栈上，将不会对auto变量产生强引用
    
如果我们给person添加`__weak`修饰符

```
__weak Person *person = [[Person alloc] init];
void(^block)(void) = ^{
    NSLog(@"Person %@",person);
};
block();
```

则block将会对person对象进行弱引用，编译后如下：

```
struct __main_block_impl_0 {
  ...
  Person *__weak person;
  ...
}
```

所以使用`__weak`修饰符可以避免block对外部变量的强引用操作

我们来看看block的结构体内的`__main_block_desc_0`是个什么东西

```
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
```

可以发现，多了两个函数指针，`copy`和`dispose`，分别指向`__main_block_copy_0`和`__main_block_dispose_0`

这两个函数的实现如下

```
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {
	_Block_object_assign((void*)&dst->person, (void*)src->person, 3/*BLOCK_FIELD_IS_OBJECT*/);
}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {
	_Block_object_dispose((void*)src->person, 3/*BLOCK_FIELD_IS_OBJECT*/);
}
```

`_Block_object_assign`函数内部会对person进行引用计数器的操作，如果`__main_block_impl_0`结构体内person指针是`__strong`类型，则为强引用，引用计数+1，如果`__main_block_impl_0`结构体内person指针是`__weak`类型，则为弱引用，引用计数不变。

`_Block_object_dispose`会对person对象做释放操作，类似于release，也就是断开对person对象的引用，而person究竟是否被释放还是取决于person对象自己的引用计数


- 结论2：如果block被拷贝到堆上
	- 会调用block内部的copy函数
    - copy函数内部会调用_Block_object_assign函数
    - _Block_object_assign函数会根据auto变量的修饰符（`__strong`，`__weak`，`__unsafe_unretained`）做出相应的操作，类似于retain(形成强引用、弱引用)
    
	> __unsafe_unretained修饰的变量不会增加引用计数，当销毁时，该指针不会置空，会造成不安全的情况。
    
- 结论3：如果block从堆上移除
	- 会调用block内部的dispose函数
    - dispose函数内部会调用_Block_object_assign函数
    - _Block_object_dispose函数会自动释放引用的auto变量，类似于release
    
|函数|调用时机|
|---|---|
|copy函数|栈上的Block复制到堆时|
|dispose函数|堆上的Block被废弃时|


## __block

一般情况下我们是无法改变block捕获的外部的值的

```
Person *person = [[Person alloc] init];
void(^block)(void) = ^{
	person = nil;  /// 这种情况是会编译失败的
};
block();
```

从上面的内容我们也可以知道原因。就是因为外部的person所在的内存空间和block内（单独开辟了一个函数）的内存空间不在同一个位置，所以block内是访问不到的外部的person的。

但是我们如果添加了`__block`关键字的话，就可以访问了，所以我们编译一下看看添加`__block`之后的情况

```
__block Person *person = [[Person alloc] init];
void(^block)(void) = ^{
	person = nil;  // 编译成功
};
block();
```

编译后长这样

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_person_0 *person; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_person_0 *_person, int flags=0) : person(_person->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

可以看到person对象被封装成了一个`__Block_byref_person_0 *`类型的属性

继续看看`__Block_byref_person_0`是什么

```
struct __Block_byref_person_0 {
  void *__isa;
__Block_byref_person_0 *__forwarding;
 int __flags;
 int __size;
 void (*__Block_byref_id_object_copy)(void*, void*);
 void (*__Block_byref_id_object_dispose)(void*);
 Person *__strong person;
};
```

`__Block_byref_person_0`有isa指针，是一个OC对象，里面有一个强引用的person对象（指向的内容等同于外面的person指针指向的内容），和我们熟悉的`__Block_byref_id_object_copy`和`__Block_byref_id_object_dispose`方法用于处理内存管理问题，还有指向自身的`forwarding`指针（这个指针指向对象自身），`flag`和`size`，分别表示标记位和这个结构体的占用内存空间大小。

person被封装成了结构体对象之后，原先的block函数就变成了

```
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
	__Block_byref_person_0 *person = __cself->person; // bound by ref
	(person->__forwarding->person) = __null;
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_jj_276qbs652l5ckj94jfcx28jh0000gn_T_main_250618_mi_0,(person->__forwarding->person));
}
```

可以看出，但我们要改变person指针的值的时候，首先是取出person对象，即`__Block_byref_person_0 *person`，然后再通过`forwarding`指针拿到自己，再拿到最里面的person，最后就可以修改了。

1. 通过内存打印，我们可以得知`__Block_byref_person_0`内的person对象和外部的person对象的地址是一致的，所以我们在block内修改外部的person就是相当于修改`__Block_byref_person_0`内的person对象
2. 为什么要绕一个圈，不直接`person->person`而是要`person->__forwarding->person`？原因是防止block从栈复制到堆之后，栈上面的block访问person访问到的是栈上的person而不是堆上的person，所以栈上的forwarding指针要指向堆的block，这样子就能一直访问到堆上的person了

3. 封装的`__Block_byref_person_0`结构体内的`__Block_byref_id_object_copy`函数会管理他自己的person对象的内存，实现代码如下:
	`_Block_object_assign((char*)dst + 40, *(void * *) ((char*)src + 40), 131);`，这里的40是person对象的偏移值，可以看到结构体内person前面的4个指针加2个整型刚好40个字节。
4. `__Block_byref_person_0`在`__main_block_impl_0`内必定是强引用，跟我们上面所说的不一样，就算在`__block`之前再添加`__weak`修饰，`__Block_byref_person_0`在`__main_block_impl_0`内依旧是强引用

- 注意 MRC环境下，__block 不会对变量造成强引用，即以下情况person会提前释放

	```
	__block Person *person = [Person new];
	void(^block)(void) = ^{
		NSLog(@"%@",person);
	};
	block(); /// 这时候person已经释放了
	```

> 注意：__block只能用于修饰auto变量，不能修饰全局变量和静态（static）变量

## 循环引用

- 以下代码会产生循环引用
	
	```
	Person *person = [Person alloc] init];
	person.age = 10;
	person.block = ^{
		NSLog(@"age is %d",person.age);
	};
	```

- __weak: 不会产生强引用，指向的对象销毁时，会自动让指针至nil
- __unsafe_unretain: 不会产生强引用，不安全，指向的对象销毁时，指针存储的地址值不变