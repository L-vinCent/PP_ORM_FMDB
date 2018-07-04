//
//  PPSingleTestModel.m
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/4.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPSingleTestModel.h"

@implementation PPSingleTestModel
PPDATABASE_IMPLEMENTATION_INJECT(PPSingleTestModel)

- (NSArray<NSString *> *)g_GetCustomPrimarykey
{
    return @[@"testStuId"];
}


+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper
{
    return @{
             @"testStuId" :@"id",
             };
}

@end
