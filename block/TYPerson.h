//
//  TYPerson.h
//  block
//
//  Created by 马天野 on 2018/9/2.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TYPerson : NSObject

/** name */
@property (nonatomic, copy) NSString * testName;

- (void)test1;
- (void)test2;
+ (void)test3;
- (instancetype)initWithName:(NSString *)name;

@end
