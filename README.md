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
void(*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));

// 去掉强制转换部分,简化后的代码
void (*block)(void) = &_main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA));
```

- 执行 block 代码块部分

```c++
// 未简化代码
((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);

// 去掉强制转化后简化的代码
block->FuncPtr(block);
```

