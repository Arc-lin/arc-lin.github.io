title: C++基础
author: Arclin
abbrlink: f9a964a9
tags:
  - C++
categories:
  - C++
date: 2019-10-15 13:17:00
---
在iOS开发过程中，有时候会用到一些C++的库，为了避免大家用到这种库的时候一脸懵逼，这里总结一些基础知识，不写C++没关系，起码当库出了什么问题的时候至少能看懂逻辑（或许吧）。

这里全部都是基础语法知识，没事的时候可以看看熟悉一下。

<!-- more -->

## 指针和引用

略

还是简单说一下：`.`是对象访问属性的操作符，`->`是指针访问指针属性的操作符，
`(*a).b`=>`a->b`

## 权限访问

public:   可以被任意实体访问

protected:只允许子类及本类的成员函数访问

private:只允许本类的成员函数访问

## 函数

### 默认参数

跟Swift差不多

```
int func (int a , int b = 10, int c = 10); // 声明中有默认参数，实现中不能有默认参数，比如下面这么写就会报错
// 声明和实现只能其中一个有默认参数
int func (int a , int b = 10, int c = 10) { // 形参默认值，当b有默认值的时候，后面的参数都需要有默认值，不能b有c没有，但是可以c有b没有
	 return a + b + c;
}
```

### 占位参数（没啥用）

```
void func(int a,int = 0) { // 占位参数可以有默认参数，也可以没有
	cout << a << endl;
}

func(1,2);
```

其实主要是用与兼容C语言的不规范写法，因为在C语言中，传参个数可以比函数声明的参数个数还多，比如`func(1,2,3,4,5)`,会警告但是不会报错，但是C++这么写就会报错，所以为了兼容C语言的调用方式，就用占位参数，占个位但是不用它，这样子就不会报错。

### 函数重载

同一个作用域，函数名相同，参数个数不同/类型不同/顺序不同

**函数的返回值不可以作为函数重载的条件**

#### 语法

```
void func() {}
void func(int a) {}
void func(double a) {}
void func(int a, double b) {}
void func(double a, int b) {}
int func() {} // 这个会报错
```

#### 特殊情况

```
// 引用作为重载的条件
void func(int &a) { // 方法1
	cout << "func(int &a)" << endl;
}
void func(cont int &a) {  // 方法2
	cout << "func(cont int &a)" << endl;
}

int a = 10;
func(a); // 方法1

func(10); // 方法2 因为 const int &a = 10; 合法，int &a = 10; 不合法

// 函数重载碰到默认参数
void func2(int a) {
	cout << "func2(int a)" << endl;
}

void func2(int a,int b = 10) {
	cout << "func2(int a, int b)" << endl;
}

func2(10); // 出现歧义（二义性），两个方法都能走，报错，所以建议函数重载的时候不要带默认参数
```

## struct 和 class 的区别

`struct`默认权限为`public`
`class`默认权限为`private`

## 构造函数和析构函数

```
#include <iostream>
class Person
{
public:
	Person() {
       cout << "默认构造函数：系统会默认生成" << endl;
    }
	
	Person(int age) {
		cout << "带参数构造函数，写了这个系统就不生成无参构造函数" << endl;
		this->_age = age;
	}
	
	Person(int age) : _height(15) {
		cout << "初始化部分参数的构造函数" << endl;
		this->_age = age;
	}
	
	Person(int age, int height) : _height(height) {
		cout << "初始化部分参数的构造函数,并且顺便赋值了_height属性" << endl;
		this->_age = age;
	}
	
	Person(const Person &person) {
		cout << "浅拷贝函数：系统会默认生成" << endl;
		// 如果要深拷贝的话自己手动生成、赋值对象属性。
		//如果自己写拷贝构造函数的话，系统不提供其他普通构造函数（有/无参）
	}
	
	~Person() {
       cout<<"析构函数：系统默认生成"<<endl;
    }
	
	//int age; // 不建议使用跟形参同名的成员变量
	int _age; // 带个下划线吧
	int _height;
	SomeClass property; // 别的类的属性：构造时会优先进入该类构造函数，析构时会优先进入Person的析构函数，再走这个类的析构函数
};


int main() {
	Person p1; // 这样子就实例化了
	Person p2(11); // age = 11
	Person p3(11,160); // age = 11 height = 160
	return 0;
}
```

## 链式调用函数

在上面的Person类内加多这么一个方法
```
Person& addAge(Person &p) {
	this->_age += p._Age;
	return *this; // 返回当前对象指针！！！
}


Person pp(20);
Person pp2(10);
pp.addAge(pp2).addAge(pp2).addAge(pp2); // 爽快地链式调用
```

## 静态方法

```
class Person {
public:
	static void func() {
		cout << "静态方法只能访问静态常量" << test << endl;
	}
	
	static int test;
};

int main() {
	Person p;
	p.func(); // 可以这么调
	Person::func(); // 也可以通过类名直接调
	return 0;
}
```

## 常函数和常对象

```
#include <string>
class Person {
public:
	void funcA() const {
//		this->_name = "test";  常函数不可以访问普通成员属性
		this->_age = 1; //常函数可以访问被mutable修饰的成员属性
	}
	string _name;
	mutable int _age;
	
	void funcB() {
		
	}
}

int main() {
	const Person p;
//	p.funcB(); // 常对象不能访问普通函数
	p.funcA(); // 常对象只能访问常函数
	reutrn 0;
}
```

## 在类外部实现函数

```
class Person {
public: // 需要是public函数才可以这么玩
	Person(); // 要在外部实现的都得事先声明
	void test();
};

Person::Person() {

}

void Person::test() {

}
```

## 友元函数

友元函数可以访问被`private`修饰的属性


### 全局函数做友元
```

class Building {
    // 友元函数 可以访问私有属性
    friend void visitor(Building &building);
public:
    Building() {
        m_SittingRoom = "客厅";
        m_Bedroom = "卧室";
    }
    string m_SittingRoom;
private:
    string m_Bedroom;
};

void visitor(Building &building) {
	cout << "全局函数" << building.m_SittingRoom << endl;
    cout << "全局函数" << building.m_Bedroom << endl;
}
```

> 顺带一提：如果入参是引用的话（`&building`）,那么可以直接通过点语法访问成员属性，如果入参是指针的话（`*building`），那么就通过`->`访问，如（building->m_Bedroom）

> 顺带再提，两种函数声明和调用方式的不同

```
void visitor(Building &building) {
    cout << "全局函数" << building.m_SittingRoom << endl;
}

void visitor2(Building *building) {
    cout << "全局函数" << building->m_SittingRoom << endl;
}

int main() {
    
    Building building;  // 生成对象
    visitor(building);  // 直接传对象
    visitor2(&building); // 传对象地址
}

```

### 友元类

```
class Building {
    friend class Visitor; // 这个类下的所有函数都可以访问它的私有属性
public:
    Building() {
        m_Bedroom = "卧室";
    }
private:
    string m_Bedroom;
};

class Visitor
{
public:
	Visitor() {
		building = new Building;
	}
	void visit();
	Building *building;
};

void Visitor::visit() {
	cout << building->m_Bedroom << endl;
}

int main() {
	Visitor v;
	v.visit();
	return 0;
}

```

### 成员函数做友元函数

```
class Building;
class Visitor
{
public:
    Visitor();
    void visit();
    Building *building;
};

class Building {
    friend void Visitor::visit(); // 指定Visitor的visit成员函数可以访问私有属性
public:
    Building() {
        m_Bedroom = "卧室";
    }
private:
    string m_Bedroom;
};

// 为什么这个构造函数要写外面，不能写里面？
// 因为Visitor需要在Building上面定义，不然不给定义Visitor上的友元函数，然后因为Visitor内有Building的属性，所以要声明一下class Building; 但是因为只是声明没有实现，所以就不能new Building;了，那就只能把这个通过类外实现的方式写在Building定义的下面。
Visitor::Visitor() {  
    building = new Building;
}

void Visitor::visit() {
    cout << building->m_Bedroom << endl;
}

int main() {
    Visitor v;
    v.visit();
    return 0;
}

```

## 运算符重载

跟Swift差不多

### 成员函数的运算符重载

```
class Animal {
public:
    Animal operator + (Animal &a) {
        Animal temp;
        temp.m_A = this -> m_A + a.m_A;
        return temp;
    }
    int m_A;
};

Animal a;
a.m_A = 1;
Animal b;
b.m_A = 2;
Animal c = a + b;
cout << c.m_A << endl; // 输出 3
```

本质：`Animal c = a.operator+(b);`

### 全局函数的运算符重载

```
Animal operator - (Animal &a, Animal &b) {
    Animal temp;
    temp.m_A = a.m_A - b.m_A;
    return temp;
}

Animal a;
a.m_A = 1;
Animal b;
b.m_A = 2;
Animal c = a - b;
cout << c.m_A << endl; // 输出 -1
```

本质：`Animal c = operator-(a,b);`

### 运算符重载也可以发生函数重载

```
Animal operator + (int a, Animal &b) {
    Animal temp;
    temp.m_A = a + b.m_A;
    return temp;
}
Animal a;
a.m_A = 1;
Animal d = 10 + a;
cout << d.m_A << endl; // 输出 11
```

本质：`Animal d = operator+(10,a);`


### 左移运算符重载（比较常见输出对象细节）

```
class MyInteger {
    friend ostream& operator<<(ostream& cout,MyInteger myInt);
public:
    MyInteger() {
        this->my_int = 0;
    }
private:
    int my_int;
};

// 必须是全局函数重载 ostream是cout的类型，为了能链式调用所以返回引用ostream&
ostream& operator<<(ostream& cout,MyInteger myInt) {
    cout << myInt.my_int; // 返回对象细节
    return cout;
}

int main() {
    MyInteger myInt;
    cout << myInt << endl; // 输出 my_int 的值 0
	return 0;
}
```

### 关系运算符重载

Swift经常使用，参见`Equable`，`Comparable`协议

```
class Person
{
public:
    bool operator==(Person &p) {
        if (this->m_Name == p.m_Name) {
            return true;
        }
        return false;
    }
    bool operator!=(Person &p) {
        if (this->m_Name != p.m_Name) {
            return true;
        }
        return false;
    }
	string m_Name;
};

int main() {
	Person p1; p1.m_Name = "A";
    Person p2; p2.m_Name = "A";
    if (p1 == p2) {
        cout << "Equal" << endl; // 输出
    } else {
        cout << "Different" << endl;
    }

    if (p1 != p2) {
        cout << "Different" << endl;
    } else {
        cout << "Equal" << endl; // 输出
    }
	return 0;
}
```

### 函数调用运算符的重载（骚操作）

因为用起来很像函数，所以又叫做仿函数，STL里相当多这种骚操作

```
class MyInteger {
	int operator()(int a,int b) {
        return a + b;
    }
};

int main() {
    // MyInteger() ：匿名对象
    int result = MyInteger()(1,2);

    MyInteger i;
    int result2 = i(5,2);

    cout << result << endl;  // 5
    cout << result2 << endl; // 7
}

```

## 继承

C++有多继承，灰常厉害

### 继承方式

三种继承方式`public`,`protected`,`private`，决定着继承下来的属性和方法以什么形式修饰，`class`默认`private`,`struct`默认`public`（没错，C++中结构体可以被继承）
父类的所有非静态属性会被继承，包括`private`类型的，但是`private`类型的默认隐藏，子类无法访问。

继承语法：

```
class SubClass : public SuperClass {

};
```

### 构造和析构

父类先构造，子类先析构

```
superClass()
subClass()
~subClass()
~superClass()
```

### 同名属性/函数/静态属性/静态函数的访问

假如子类和父类拥有相同的名字的属性/函数/静态属性/静态函数，则直接调用子类对象的话都是访问子类的，如果要访问父类的话要添加作用域。

```
class Base {
public:
    int _a = 1;
    static int _b;
    static void staticFunc() {
        cout << "Base staticFunc()" << endl;
    }
    void Func() {
        cout << "Base Func()" << endl;
    }
};
int Base::_b = 10; // 静态成员变量要在外面赋值

class Sub1 : public Base {
public:
    int _a = 2;
    static int _b;
    static void staticFunc() {
        cout << "SubClass staticFunc()" << endl;
    }
    void Func() {
        cout << "SucClass Func()" << endl;
    }
};
int Sub1::_b = 20;

int main() {

    Sub1 s;
    // 直接调用
    cout << s._a << endl;
    // 调用父类的
    cout << s.Base::_a << endl;

    // 静态直接调用
    cout << s._b << endl;
    // 静态调用父类的
    cout << s.Base::_b << endl;

    // 静态直接调用
    cout << Sub1::_b << endl;
    // 静态调用父类的
    cout << Sub1::Base::_b << endl;

    // 直接调用
    s.Func();
    // 调用父类的
    s.Base::Func();

    // 静态直接调用
    s.staticFunc();
    // 静态调用父类的
    s.Base::staticFunc();

    // 静态直接调用
    Sub1::staticFunc();
    // 静态调用父类的
    Sub1::Base::staticFunc();

    return 0;
}
```

### 多继承

不建议使用，因为麻烦事多

语法：(参照上面的代码)
```
class Other {
public:
    void Func() {
        cout << "Ohter Func()" << endl;
    }
};
//...略
class Sub1 : public Base , public Other {
//...略
}
```

当多个父类中出现同名属性/方法时，需要加作用域指定父类`s.Base::Func(); / s.Other::Func();`

### 菱形继承（钻石继承）

两个子类继承同一个基类，
又有某个类同时继承着两个子类

举例
```
class Base { int age };

class Sub1: public Base {};
class Sub2: public Base {};

class SubSub: public Sub1, public Sub2 {};
```

这时候SubSub会有两个父类，有两份 age 属性，造成资源浪费

这时候用虚继承(`virtual`)解决问题

```
class Base { public: int age }; // 这时候成为虚基类

class Sub1: virtual public Base {};
class Sub2: virtual public Base {};

class SubSub: public Sub1, public Sub2 {};
```
这时候age属性成为共享属性，最后谁改了就是谁的值

```
SubSub s;
s.Sub1::age = 1;
s.Sub2::age = 10;
cout << s.Sub1::age << endl; // 10
cout << s.Sub2::age << endl; // 10
cout << s.age << endl; // 10
```

## 多态

C++中，多态分两类

静态多态：函数重载和运算符重载属于静态多态，复用函数名
动态多态：子类和虚函数实现运行时多态

区别：

静态多态的函数地址早绑定，编译阶段确定函数地址
动态多态的函数地址晚绑定，运行阶段确定函数地址

动态多态满足条件：
1. 有继承关系
2. 子类重写父类虚函数

动态多态使用
父类的指针或者引用指向子类对象


静态多态举例：
```
class Animal {
public:
    void speak() {
        cout << "Animal Speak" << endl;
    }
};
class Cat: public Animal
{
public:
    void speak() {
        cout << "Cat Speak" << endl;
    }
};
void SomeoneSpeak(Animal &animal) {
    animal.speak();
}

int main() {
    Cat c;
    SomeoneSpeak(c); // 由于SomeoneSpeak(Animal &animal)，编译期间已经确定入参类型，所以输出 Animal Speak
```

如果想输出`Cat Speak`，只需进行如下修改

```
class Animal {
public:
    virtual void speak() { // 虚函数，可以告知由于SomeoneSpeak(Animal &animal)运行时再确定入参类型
        cout << "Animal Speak" << endl;
    }
};
```

经常地，这种情况下也是动态多态，最后会输出`Cat Speak`
```
Animal *a = new Cat;
a->speak();
```

### 纯虚函数和抽象类

父类的虚函数的实现没什么意义，所以上面的虚函数代码改写为`纯虚函数`

```
virtual void speak() = 0;
```

当类中有了纯虚函数，则这个类称为`抽象类`

抽象类**无法实例化对象**，并且**子类必须重写父类的纯虚函数**，否则也成为`抽象类`

### 虚析构和纯虚析构

当子类在堆区创建数据的时候，需要手动释放，父类需要添加虚析构或者纯虚析构函数，否则子类可能不走析构函数

比如上面的`Animate`父类，我们补充一下

```
class Animal {
public:
    virtual ~Animal() = 0; // 纯虚析构
};

Animal::~Animal() { // 析构实现
    cout << "Animal is Delete" << endl;
}
```

## 文件操作

文件打开方式

`ios::in`:读文件
`ios::out`:写文件
`ios::ate`:初始位置，文件尾
`ios:app`:追加写文件
`ios:trunc`:如果文件存在先删除，再创建
`ios:binary`:二进制方式

同时两种方式则使用`|`的方式，比如`ios::in|ios:binary`

### 写文件

```
ofstream stream;

stream.open("Test.txt",ios::out);

stream << "Line 1" << endl;
stream << "Line 2" << endl;
stream << "Line 3" << endl;

stream.close();

```

### 读文件

```
ifstream ifs;
ifs.open("Test.txt",ios::out);

if(!ifs.is_open()) {
	cout << "打开文件失败" << endl;
	return 0;
}

string buf;
while (getline(ifs, buf)) { // 一行行读取
	cout << buf << endl;
}

ifs.close();
```

## 类模板

### 构建类模板与类模板做参数

```
template<class NameType,class AgeType>

class Person {
public:
    Person(NameType name, AgeType age) {
        this->_age = age;
        this->_name = name;
    }
    AgeType _age;
    NameType _name;
};

int main() {

	// 不会自动类型推导，需要自己显式声明类型
    Person<string,int> p("Haha",123);

    cout << p._name << " " << p._age << endl;

    return 0;
}

```

可以给类模板添加默认类型

`template<class NameType,class AgeType = int>`

这样子调用的时候就可以不全声明类型了

`Person<string> p("Haha",123);`

类模板做参数
```
// 指定类型的类模板做参数
void print(Person<string,int> &p) {
    p.showPerson();
}

// 模板化参数的类模板做参数
template<class T1,class T2>
void print2(Person<T1, T2> &p) {
    p.showPerson();
}

// 模板化类做参数
template<class T>
void print3(T &p) {
    p.showPerson();
}

int main() {
    Person<string,int> p("Haha",123);
    print(p);
    print2(p);
    print3(p);
    return 0;
}
```

### 类模板与继承

继承时需要指定类型

```
template<class T>
class Base
{
public:
    T m;
};

class SubClass: public Base<int> { // 指定T的类型
public:
    void print() {
        cout << m << endl;
    }
};
```

如果不想指定类型，那么可以模板化子类

```

template<class T>
class Base
{
public:
    T m;
};

template<class T1,class T2>
class SubClass: public Base<T1> {
public:
    SubClass(T1 a, T2 b) {

    }
    T2 k;
};

int main() {
	SubClass<string, int> c("String",1);
	return 0;
}
```


## STL 之 Vector容器

```
vector<int> v1; // 初始化指定容器内元素类型
v1.assign(10, 1); // 插入10个1，也可以传入其他vector,比如v1.assign(v0.begin,v0.end); 或者直接 v1 = v0; 只要保证是同种类型就好
for (vector<int>::iterator i = v1.begin(); i != v1.end() ; i++) {
	cout << *i << endl;
} // 打印10个1
cout << "Size = " << v1.size() << endl; // 长度 10
cout << "isEmpty = " << v1.empty() << endl; // 判空 0
cout << "capacity = " << v1.capacity() << endl; // 容量 10
v1.resize(20,20); // 调整容量为20，多出来的位置用20填充，这里的20可以不传，默认0
cout << "capacity = " << v1.capacity() << endl; // 现在容量变成20

v1.pop_back(); // 删除最后一个元素

cout << "Size = " << v1.size() << endl; // 长度 19
cout << "capacity = " << v1.capacity() << endl; // 容量不变 20

v1.insert(v1.begin() + 1, 199); // 下标为1的位置插入元素199
v1.insert(v1.begin() + 1, 2, 199); // 下标为1的位置插入两个元素199
v1.erase(v1.begin() + 2); // 删除第二个元素
v1.erase(v1.begin() + 2 , v1.begin() + 3); // 删除第二个到第三个元素
v1.clear(); // 清空容器

cout << "第二个元素是" << v1.at(1) << endl;
cout << "第三个元素是" << v1[2] << endl;
cout << "第一个元素" << v1.front() << endl;
cout << "最后一个元素" << v1.back() << endl;

v1.reverse(100000); // 预留空间，减少以后动态拓展的次数

v1.swap(v0); // 交换元素，假如v1的预留空间很大，可以通过交换一个小预留空间的容器达到压缩内存的效果

```