//
//  PPDataBase.h
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/4.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPDataModelProtocol.h"
@interface PPDataBase : NSObject

-(void)databaseWithPath:(NSString *)dbPath;

/**
 不开启事务， 向数据库添加一条数据
 @return PPDataBaseD实例
 */
- (BOOL)addObject:(id<PPDataModelProtocol>)obj;


- (BOOL)addObject:(id<PPDataModelProtocol>)obj WithTableName:(NSString*)tableName;


@end
