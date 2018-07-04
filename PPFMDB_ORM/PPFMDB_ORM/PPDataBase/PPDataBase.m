//
//  PPDataBase.m
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/4.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPDataBase.h"
#import "FMDB.h"
#import <objc/runtime.h>
#import "PPDBManager.h"
@interface PPDataBase()

@property(nonatomic,strong)PPDBManager *dbManager;

@end

@implementation PPDataBase

-(void)databaseWithPath:(NSString *)dbPath
{
   self.dbManager = [[PPDBManager alloc]initWithDBPath:dbPath];
}

- (BOOL)addObject:(id<PPDataModelProtocol>)obj
{
    return [self addObject:obj WithTableName:NSStringFromClass([obj class])];
}

- (BOOL)addObject:(id<PPDataModelProtocol>)obj WithTableName:(NSString*)tableName
{
    if (!obj) {
        return NO;
    }
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass([obj class]);
    }
    [self.dbManager tableCheck:obj];
    
    __block BOOL isSuccess = NO;
    [self.dbManager.dbQueue inDatabase:^(FMDatabase *db) {
        NSString * query = [self.dbManager getInsertRecordQuery:(id<PPDataModelProtocol>)obj withTableName:tableName];
        isSuccess = [db executeUpdate:query,nil];
    }];
    return isSuccess;
}

@end
