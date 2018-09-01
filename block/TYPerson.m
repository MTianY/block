//
//  TYPerson.m
//  block
//
//  Created by 马天野 on 2018/9/2.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import "TYPerson.h"

@implementation TYPerson

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        _testName = name;
    }
    return self;
}

- (void)test1 {
    void(^test1Block)(void) = ^{
        NSLog(@"%p",self);
    };
    test1Block();
}

- (void)test2 {
    void(^test2Block)(void) = ^{
        NSLog(@"%p",self);
    };
    test2Block();
}

+ (void)test3 {
    void(^test3Block)(void) = ^{
        NSLog(@"%p",self);
    };
    test3Block();
}


@end
