#README

## 一. block 的概念

- block 本质上是一个`OC对象`,它的内部也有`isa指针`.
- block `封装了函数调用`以及`函数调用环境`.

## 二. block 的底层结构

### 1.oc 代码转 c++代码看其底层结构.

首先看一个比较简单的 block, 然后对比其`.cpp`文件中的`c++`代码,看其底层结构是什么样的.

OC 中的 block

```objc
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        void(^block)(void) = ^{
            NSLog(@"Hello, World!");
        };
        block();
    }
    return 0;
}
```

C++ 中的 block:

```c++
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        void(*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
    }
    return 0;
}
```

### 2.oc 代码与 c++代码对比,看 block 的定义部分和执行代码块部分.

对比后发现如下:

- block 的定义部分:

```objc
// OC
void(^block)(void) = ^{
    NSLog(@"Hello, World!");
};
```

```c++
// c++
void(*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
```

- block 的执行代码块部分

```oc
// oc
block();
```

```c++
// c++
((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
```

#### 2.1 .简化上述 c++ 代码,去掉强制转化部分.

- 定义 block 部分

```c++
// 原代码:
// void(*block)(void) 指向 __main_block_impl_0 这个函数的内存地址
void(*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));

// 去掉强制转换部分,简化后的代码
void (*block)(void) = &_main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA);
```

- 执行 block 代码块部分

```c++
// 未简化代码
((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);

// 去掉强制转化后简化的代码
block->FuncPtr(block);
```

#### 2.2 `__main_block_impl_0` 函数

首先看下结构体:

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  // 构造函数,将传进来的3个参数赋值给里面的变量,其返回一个结构体对象
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

其中有个`构造函数`, `__main_block_impl_0` ,并且其有三个参数,返回一个结构体.

- 第一个参数 : `void *fp`
- 第二个参数 : `struct __main_block_desc_o *desc`
- 第三个参数 : `int flags = 0`

外面执行的函数 `void (*block)(void) = &_main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA);` 一共传进来2个参数.与上面3个参数对应(第3个参数可以不传).

- 传进来的第1个参数: `__main_block_func_0`: 其作用是封装了 block 执行逻辑的函数.
    - 其对应参数 `void *fp`, 而`impl.FuncPtr = fp;` ,所以最后`是将 __main_block_func_0 这个函数的地址传给了 impl 的 FuncPtr`

```c++
// 封装了 block 执行逻辑的函数
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_w8_wnywnfxn7zldh13vnt816cmm0000gn_T_main_0b5816_mi_0);
}
```

- 传进来的第2个参数: `&__main_block_desc_0_DATA`:
    - 将 `0` 赋值给 `size_t reserved`.
    - 将 `sizeof(struct __main_block_impl_0)` 赋值给 `size_t Block_size`, 它用来计算这个结构体占用了多少内存空间.而最后又将这个赋值给上面结构体的第2个参数`Desc`

```c++
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
```

#### 2.3 `block->FuncPtr(block)`

该标题是简化后的代码,看着通过 block 直接找到FuncPtr 调用 block 有点奇怪.下面是原先带有强制转换的代码:

```c++
 ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
```

- 将`block`强制转换为 `__block_impl`.下面看下 `__block_impl`

```c++
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};
```

- 发现其中有 `FuncPtr`.那么上面直接拿 `FuncPtr` 就是合理的.

那为什么我们可以将`block` 强制转换为 `__block_impl` 呢? `block` 最开始是指向 `__main_block_impl_0` 的.

- 因为看 `__main_block_impl_0` 的结构可知,它的第一个成员就是 `__block_impl`, 所以它的内存地址就是 `__main_block_impl_0`这个结构体的内存地址.所以这么转换没有问题.

## 三. block 变量捕获

### 1. 局部变量之 auto 变量捕获

- auto 变量
    - 自动变量,离开大括号的作用域范围就会自动销毁
    - 如下面的`int a = 30;` 其实就是`auto int a = 30;` 不过把 auto 省略了. 
- auto 变量`可以`被捕获到 block 内部
- 且其访问方式是`值传递` .

代码如下:

```objc
int main(int argc, const char * argv[]) {
    @autoreleasepool {
    
        // 定义 auto 变量 a, 值30
        int a = 30;
        
        // 将 a 捕获进 block, 此时 block 内部存的 a 值就是 30.
        void(^testBlock)(void) = ^{
            NSLog(@"a = %d",a);
        };
        
        // 改变 a 的值为40, 执行完这之后, 变量 a 自动销毁
        a = 40;
        
        // 执行 block. 执行 `NSLog` 方法, 因为之前 block 内部存储的 a 的值是30,而此时变量 a 已经销毁了,所以打印出的 a 值还是30.
        testBlock();  
    }
    return 0;
}

// 打印结果: a = 30;
```

编译成`C++`文件看其实现过程:

```c++
nt main(int argc, const char * argv[]) {
    int a = 30;
    void(*testBlock)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, a));
    a = 40;
    ((void (*)(__block_impl *))((__block_impl *)testBlock)->FuncPtr)((__block_impl *)testBlock);
    return 0;
}
```

发现 `__main_block_impl_0` 这个结构体发生了变化:

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  // 多了个成员 a
  int a;
  // 多了个参数 _a
  // a(_a) 表示把`_a`赋值给成员`a`
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _a, int flags=0) : a(_a) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

所以 `void(*testBlock)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, a));` 将 `a` 做参数传进去. `_a`将变量`30`赋值给结构体 `__main_block_impl_0`的成员`a`.然后在下面这个方法内,拿到 `a` 打印出来.

```c++
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int a = __cself->a; // bound by copy

        NSLog((NSString *)&__NSConstantStringImpl__var_folders_w8_wnywnfxn7zldh13vnt816cmm0000gn_T_main_ffe641_mi_0,a);
    }
```

后面的`int a=40`因为是值传递,所以不能改变 block 内的值.

### 2.局部变量之 static 变量捕获

看如下代码,定义`static`变量`b`,当 b 的值改为`60`时,block 内的 b 发生变化.

```c++
int main(int argc, const char * argv[]) {
    @autoreleasepool {   
        
        // 定义 auto 变量a, static 变量 b.
        auto int a = 30;
        static int b = 30;  
        
        // block 捕获 a 和 b 的值.
        void(^testBlock)(void) = ^{
            NSLog(@"a = %d\n  b = %d\n",a,b);
        };
        
        // 将 a 重新赋值为 40
        a = 40;
        // 将 b 重新赋值为 60.
        b = 60;   
        
        /** 执行这里过后.auto 变量 a 自动销毁,而 static 变量 b 没有销毁  **/
        
        // 执行 block, 取出 a 和 b 的值.
        // 因为 block 之前捕获的 a 值为 30.而此时 a 销毁了,所以直接打印出30;
        // 因为 block 之前捕获的 b 值为30.但是此时 b 没有被销毁.而且 b 的值已经变味 60.所以打印 b 的值为60.
        testBlock();    
    }
    return 0;
}
```

看其`C++`代码实现:

```c++
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        auto int a = 30;
        static int b = 30;
        void(*testBlock)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, a, &b));
        a = 40;
        b = 60;
        ((void (*)(__block_impl *))((__block_impl *)testBlock)->FuncPtr)((__block_impl *)testBlock);
    }
    return 0;
}
```

看到上面的实现后我们发现.这里是将`b`的`地址`传进去的.`&b`.

而 `__main_block_impl_0` 结构体多了`两个`成员.

- int a;
- int *b;

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int a;
  int *b;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _a, int *_b, int flags=0) : a(_a), b(_b) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

所以会将 b 的地址赋值给 `int *b`,最后打印的时候拿到 b 的地址,将 b 取出.因为 b 最后发生了变化,所以最后打印`b = 60`.


 


