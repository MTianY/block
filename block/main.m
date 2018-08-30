//
//  main.m
//  block
//
//  Created by 马天野 on 2018/8/28.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        void(^block)(void) = ^{
            NSLog(@"Hello, World!");
        };
        
//      void(*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
        
        // 简化后,去掉声明部分的 block 定义
//        void(*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA);
        
        
        block();
        // ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
        
        // 简化后去掉声明的 执行 block 部分
        // // block->FuncPtr(block);
    }
    return 0;
}

/*
 
int main (int argc, const char * argv[]) {
    // @autoreleasepool
  { __AtAutoreleasePool __autoreleasepool;
     void(*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
     ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
  }
  return 0;
}
 
 */
