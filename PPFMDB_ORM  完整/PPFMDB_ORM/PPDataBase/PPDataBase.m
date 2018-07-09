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



/**
 修改数据
 */

- (BOOL)updateObjectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues contionKeyDic:(NSDictionary *)conDic
{
    if (keyValues.allValues.count <= 0 || !keyValues) {
        return NO;
    }
    
    NSString *tableName = NSStringFromClass(clazz);
    
    return  [self updateTableName:tableName ObjectClazz:clazz keyValues:keyValues contionKeyDic:conDic];

}

//条件语句拼接 dataIndex = 140732710210224 and dataGroup = 4522822591
-(NSString *)getKeyAndValue:(NSDictionary *)conDic
{
    
    __block NSMutableString *conStr = @"".mutableCopy;
    [conDic enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, NSString*  _Nonnull obj, BOOL * _Nonnull stop) {
        
        
        NSString *tempStr = [NSString stringWithFormat:@"%@ = '%@'",[self processReservedWord:key],obj]; //dataIndex = 140732710210224
        
        if (!kStringIsEmpty(conStr)) {
            NSMutableString *temp = @"".mutableCopy;
            [temp appendString:@" and "];
            [temp appendString:tempStr];
            tempStr = temp;
        }
        
        [conStr appendString:tempStr];
        
    }];
    
    NSLog(@"---%@",conStr);
    return conStr;
}

- (BOOL)updateTableName:(NSString*)tableName ObjectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues contionKeyDic:(NSDictionary *)conDic
{
    //UPDATE GAppsDataViewModel SET fields='我被修改了' WHERE dataIndex = 140732710210224 and dataGroup = 4522822591
    if (keyValues.allValues.count <= 0 || !keyValues) {
        return NO;
    }
    
    __block NSString* sql = [NSString stringWithFormat:@"UPDATE %s SET", [tableName UTF8String]];

    [keyValues enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
       
        if ([self.dataBase columnExists:key inTableWithName:tableName])
        {
            
            objc_property_t property = class_getProperty(clazz, key.UTF8String);
            NSString *property_value = @"";
            if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
                
                NSString* value = [NSString stringWithFormat:@"%@" , obj];
                NSString* property_sign = [self getPropertySign:property];
                if ([property_sign isEqualToString:@"@\"NSString\""] ||
                    [property_sign isEqualToString:@"@"]) {
                    value = [self base64Str:value];
                }
                
                property_value = [NSString stringWithFormat:@"'%@'", value];;
            }else{
                property_value = [NSString stringWithFormat:@"%@", [obj stringValue]];
            }
            NSString *keyName = [self processReservedWord:key];
            sql = [NSString stringWithFormat:@"%@ %@=%@,",sql,keyName,property_value];
            
        }
  
    }];
    
    sql = [self removeLastOneChar:sql];

    NSString *conStr = [self getKeyAndValue:conDic];
    
    NSLog(@"---%@",conStr);
    
    sql = [NSString stringWithFormat:@"%@ WHERE %@",sql,conStr];
    
    __block BOOL sucess = NO;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        sucess = [db executeUpdate:sql,nil];
        
    }];
    return sucess;
 
}

#pragma mark -- 条件语句查询
/// 根据condition获取数据表中符合条件的数据
- (NSArray *)getObjectsWithClass:(Class)clazz whereCondDic:(NSDictionary *)dic
{
//    select * from SQLiteReserveModel where [desc] ='desc'

    
    NSString *tableName = NSStringFromClass(clazz);
    NSString* sql = [NSString stringWithFormat:@"select * from %s where ", [tableName UTF8String]];
    
    NSString *conStr = [self getKeyAndValue:dic];

    
    sql = [NSString stringWithFormat:@"%@ %@", sql,conStr];

    
    return [self excuteSql:sql withClass:clazz];
}

- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName orderBy:(NSString*)orderName up:(BOOL)up limit:(NSInteger)count condDic:(NSDictionary *)contionDic
{
    //select * from 表名  Y='str' and Y='str' order by C limit 10
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    
    NSString* sql = [NSString stringWithFormat:@"select * from %s ", [tableName UTF8String]];
    
    NSString *conStr = [self getKeyAndValue:contionDic];
    
    sql = [NSString stringWithFormat:@"%@ WHERE %@",sql,conStr];
    
     NSString *orderCond = up ? @"ASC" : @"DESC";
    
    if (orderName || orderName.length > 0) {
        sql = [NSString stringWithFormat:@"%@ order by %@ %@",sql,orderName,orderCond];
    }
    
    if (count > 0) {
        sql = [NSString stringWithFormat:@"%@ limit %ld",sql,count];
    }
    
    return [self excuteSql:sql withClass:clazz];
}




- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName CustomCond:(NSString *)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    NSString *condition = [[NSString alloc] initWithFormat:predicateFormat arguments:args];
    va_end(args);
    
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    NSString* sql = [NSString stringWithFormat:@"select * from %s ", [tableName UTF8String]];
    sql = [sql stringByAppendingString:[self formatConditionString:condition]];
    
    return [self excuteSql:sql withClass:clazz];
}

- (long)countInDataBaseWithClass:(Class)clazz withTableName:(NSString*)tableName condDic:(NSDictionary *)contionDic
{
    
    //select * from 表名  Y='str' and Y='str' order by C limit 10
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    
    NSString* sql = [NSString stringWithFormat:@"select  COUNT(*) from %s ", [tableName UTF8String]];
    
    NSString *conStr = [self getKeyAndValue:contionDic];
    
    sql = [NSString stringWithFormat:@"%@ WHERE %@",sql,conStr];
    
    __block long count = 0;

    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        count = [db longForQuery:sql];
        
    }];
    
    return  count;
}

- (BOOL)removeTableWithClass:(Class)clazz
{
    NSString* sheet_name = NSStringFromClass(clazz);
    return [self removeTable:sheet_name];
}

- (BOOL)removeTable:(NSString*)table_name
{
    __block BOOL tf = NO;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [@"DROP TABLE " stringByAppendingString:table_name];
        tf = [db executeUpdate:sql,nil];
    }];
    
    return tf;
}

@end
