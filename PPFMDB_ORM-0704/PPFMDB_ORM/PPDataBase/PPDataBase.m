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
#import "PPDBInterface.h"

@interface PPDataBase()

//@property(nonatomic,strong)PPDBManager *dbManager;

@end

@implementation PPDataBase

#pragma mark init
+ (instancetype)databaseWithPath:(NSString *)dbPath
{
    return [PPDataBase databaseWithPath:dbPath isBase64Encode:NO];
}

+ (instancetype)databaseWithPath:(NSString *)dbPath isBase64Encode:(BOOL)isEncode
{
    PPDataBase *database = [[PPDataBase alloc] initWithDBPath:dbPath];
    database.isEncode = isEncode;
    return database;
}


#pragma mark 增
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
    [self tableCheck:obj];
    
    __block BOOL isSuccess = NO;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString * query = [self getInsertRecordQuery:(id<PPDataModelProtocol>)obj withTableName:tableName];
        isSuccess = [db executeUpdate:query,nil];
    }];
    return isSuccess;
}

- (BOOL)addObjectsInTransaction:(NSArray *)objs WithTableName:(NSString *)tableName
{
    if (!objs || objs.count <= 0) {
        return NO;
    }
    
    [self tableCheck:objs[0]];
    __block NSMutableArray *array = [NSMutableArray array];
    __block NSString *sheetName = tableName;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (id<PPDataModelProtocol> obj in objs) {
            if (!sheetName || [sheetName isEqualToString:@""]) {
                sheetName = NSStringFromClass([obj class]);
            }
            NSString * query = [self getInsertRecordQuery:(id<PPDataModelProtocol>)obj withTableName:sheetName];
            BOOL isSuccess = [db executeUpdate:query,nil];
            if (!isSuccess) {
                [array addObject:obj];
                *rollback = YES;
            }
        }
    }];
    return !(array.count > 0);
}

#pragma mark 删

- (BOOL)deleteObject:(id<PPDataModelProtocol>)obj
{
    if (!obj) {
        return NO;
    }
    NSString *tableName = NSStringFromClass([obj class]);
    return [self deleteObject:obj withTableName:tableName];
}


- (BOOL)deleteObject:(id<PPDataModelProtocol>)obj withTableName:(NSString *)tableName
{
    if (obj) {
        if (!tableName || [tableName isEqualToString:@""]) {
            tableName = NSStringFromClass([obj class]);
        }
        NSString *query = [self formatDeleteSQLWithObjc:obj withTableName:tableName];
        
        __block BOOL isSuccess = NO;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            isSuccess = [db executeUpdate:query,nil];
        }];
        
        return isSuccess;
    }
    
    return NO;
    
}


- (BOOL)deleteObjects:(NSArray<id<PPDataModelProtocol>>*)objs
{
    return [self deleteObjects:objs withTableName:nil];
}

- (BOOL)deleteObjects:(NSArray<id<PPDataModelProtocol>>*)objs withTableName:(NSString*)tableName
{
    __block BOOL isSuccess = NO;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __block NSString* sheetName = tableName;
        [objs enumerateObjectsUsingBlock:^(id<PPDataModelProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!sheetName || [sheetName isEqualToString:@""]) {
                sheetName = NSStringFromClass([obj class]);
            }
            NSString *query = [self formatDeleteSQLWithObjc:obj withTableName:sheetName];
            isSuccess = [db executeUpdate:query,nil];
            if (!isSuccess) {
                *rollback = YES;
            }
        }];
    }];
    return isSuccess;
}


#pragma mark 查
// 获取数据表中的全部数据
- (NSArray*)getAllObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName
{
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    NSString* sql = [NSString stringWithFormat:@"select * from %s", [tableName UTF8String]];
    return [self excuteSql:sql  withClass:clazz];
}

- (NSArray*)getAllObjectsWithClass:(Class)clazz
{
    NSString* tableName = NSStringFromClass(clazz);
    return [self getAllObjectsWithClass:clazz withTableName:tableName];
}

@end
