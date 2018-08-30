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


 


