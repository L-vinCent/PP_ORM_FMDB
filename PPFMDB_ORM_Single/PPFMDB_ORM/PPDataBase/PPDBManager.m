//
//  PPDBManager.m
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/4.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPDBManager.h"
#import "PPDataBaseUtils.h"
#import "FMDB.h"
#import "PPDataModelProtocol.h"
#import <objc/runtime.h>
@interface PPDBManager()
{
    BOOL _isExist;
    
}
@end

@implementation PPDBManager

- (instancetype)initWithDBPath:(NSString *)dbPath
{
    if (self = [super init]) {
        self.dbFile = dbPath;
        self.isEncode = NO;
        self.sqliteReservedWords = [PPDataBaseUtils getSQLiteReservedWords];
        [self connect];
        self.dbQueue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
    
        NSLog(@"DBFile:%@", self.dbFile);
        
    }
    return self;
    
}

#pragma mark - table check

- (void)tableCheck:(id<PPDataModelProtocol>)data_obj
{
    NSString* table_name = NSStringFromClass([data_obj class]);
    [self tableCheck:data_obj withTableName:table_name];
}

- (void)tableCheck:(id<PPDataModelProtocol>)data_obj withTableName:(NSString *)tableName
{
    
    NSString* table_name = tableName;
    NSArray*  fileds = [data_obj g_getAllProperty];
    Class objClass = [data_obj class];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        //表是否存在
        NSString* sql = [NSString stringWithFormat:@"select count(*) from sqlite_master where type='table' and name='%@'", tableName];
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:@[]];
        
        while ([rs next]) {
            if ([rs intForColumnIndex:0] == 0) {
                NSArray* property_name_array = nil;
                if ([data_obj respondsToSelector:@selector( g_GetCustomPrimarykey)]) {
                    property_name_array = [data_obj  g_GetCustomPrimarykey];
                }
                BOOL isAuto = NO;
                if (property_name_array == nil || property_name_array.count <= 0) {
                    isAuto = YES;
                }

                [self createTableSingleKey:db table_name:tableName fileds:fileds primaryKey:property_name_array[0] objClass:objClass];
                
                [rs close];
                return ;
            }
        }
        
        [rs close];
        
        //字段是否都存在
        sql = [NSString stringWithFormat:@"select * from %@ limit 0", tableName];
        rs = [db executeQuery:sql withArgumentsInArray:@[]];
        
        
        for (NSString* property_name in fileds) {
            NSString *  property = [self processReservedWord:property_name];
            if ([rs columnIndexForName:property] == -1) {
                [self insertCol:property_name db:db objClass:objClass];
            }
        }
        
        [rs close];
    }];
    
}


- (void)createTableSingleKey:(FMDatabase*)db table_name:(NSString*)table_name fileds:(NSArray*)fileds primaryKey:(NSString*)primaryKey objClass:(Class)objClass
{
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (", table_name ];
    
    for (NSString* property_name in fileds) {
        
        objc_property_t objProperty = class_getProperty(objClass, [property_name UTF8String]);
        
        NSString* property_key = nil;
        
        NSString *sqlType = nil;
      
        if (sqlType == nil) {
            sqlType =  [self getSqlKindbyProperty:objProperty];
        }
        
        NSString * propertyname = [self processReservedWord:property_name];
        if ([primaryKey isEqualToString:property_name]) {
            property_key = [NSString stringWithFormat:@"%@ %@ primary key,", propertyname,sqlType];
        }else{
            property_key = [NSString stringWithFormat:@"%@ %@,", propertyname, sqlType];
        }
        
        [sql appendString:property_key];
        
    }
    
    [sql deleteCharactersInRange:NSMakeRange([sql length] - 1, 1)];
    [sql appendString:@")"];
    
    [db executeUpdate:sql];
}


#pragma mark - insert record Method

- (NSString *)getInsertRecordQuery:(id<PPDataModelProtocol>)dataObject
{
    NSString* table_name = NSStringFromClass([dataObject class]);
    return [self getInsertRecordQuery:dataObject withTableName:table_name];
}

- (NSString *)getInsertRecordQuery:(id<PPDataModelProtocol>)dataObject withTableName:(NSString *)tableName
{
    NSObject *data_obj = dataObject;
    NSString* table_name = tableName;//
    NSArray*  fileds = [dataObject g_getAllProperty];
    Class objClass = [data_obj class];
    
    NSMutableString* query = [[NSMutableString alloc] initWithFormat:@"insert or replace into %@ (", table_name];
    NSMutableString* values = [[NSMutableString alloc] initWithString:@" ("];
    
    for (NSString* property_name in fileds) {
        //sqlite 关键字过滤
        NSString *  propertyname = [self processReservedWord:property_name];
        NSString* property_key  = [NSString stringWithFormat:@"%@,", propertyname];
        NSString* property_value = nil;
        
        
        NSString *sqlType = nil;
    
            objc_property_t property = class_getProperty([data_obj class], property_name.UTF8String);
            if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
                
                NSString* value = [data_obj valueForKey:property_name];
                
                NSString* property_sign = [self getPropertySign:property];
                if ([property_sign isEqualToString:@"@\"NSString\""] ||
                    [property_sign isEqualToString:@"@"]) {
                    if (kStringIsEmpty(value)) {
                        value = @"?,";
                    } else {
                        value = [self base64EncodedString:value];
                    }
                }
                
                property_value = [NSString stringWithFormat:@"'%@',", value ];
                
            }else{
                property_value = [NSString stringWithFormat:@"%@,", [[data_obj valueForKey:property_name] stringValue]];
            }
        
        [query appendString:property_key];
        [values appendString:property_value];
    }
    
    [query deleteCharactersInRange:NSMakeRange([query length] - 1, 1)];
    [values deleteCharactersInRange:NSMakeRange([values length] - 1, 1)];
    
    [query appendString:@") values "];
    [values appendString:@")"];
    
    [query appendString:values];
    
    return query;
    
}

- (void)insertCol:(NSString*)colName db:(FMDatabase*)db objClass:(Class)objClass
{
    NSString* table_name = NSStringFromClass(objClass);
    
    
    NSString *  property = [self processReservedWord:colName];
    
    NSString *sqlType = nil;
    if (sqlType == nil) {
        objc_property_t objProperty = class_getProperty(objClass, [colName UTF8String]);
        NSString* kind =  [self getSqlKindbyProperty:objProperty];
        sqlType =  kind;
    }
    
    NSString *sql = [NSString stringWithFormat:@"alter table %@ add %@ %@", table_name, property, sqlType];
    
    [db executeUpdate:sql];
    
}


#pragma mark - 解码 sqlite 保留字段
- (NSString*)processReservedWord:(NSString*)property_key
{
    NSString *str = property_key;
    
    if ([self.sqliteReservedWords containsObject:[str uppercaseString]]) {
        str = [NSString stringWithFormat:@"[%@]",property_key];
    }
    
    return str;
}

- (NSString*)DeProcessReservedWord:(NSString*)property_key
{
    NSString *str = property_key;
    if ([self.sqliteReservedWords containsObject:[str uppercaseString]]) {
        if ([str hasPrefix:@"["] && [str hasSuffix:@"]"]) {
            str = [str stringByReplacingOccurrencesOfString:@"[" withString:@""];
            str = [str stringByReplacingOccurrencesOfString:@"]" withString:@""];
        }
    }
    return str;
}

#pragma mark-基本数据类型处理


- (NSString *)base64EncodedString:(NSString *)base64Str
{
    if (_isEncode) {
        
        return [PPDataBaseUtils base64DecodedString:base64Str];
        
    }
    return base64Str;
}


- (NSString*)getPropertySign:(objc_property_t)property
{
    return [[[[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
}

//    @"f":@"float",
//    @"i":@"int",
//    @"d":@"double",
//    @"l":@"long",
//    @"c":@"BOOL",
//    @"s":@"short",
//    @"q":@"long",
//    @"I":@"NSInteger",
//    @"Q":@"NSUInteger",
//    @"B":@"BOOL",
//    @"@":@"id"
- (NSString*)getSqlKindbyProperty:(objc_property_t)property
{
    NSString *firstType = [self getPropertySign:property];
    
    if ([firstType isEqualToString:@"f"]) {
        return @"real";
    } else if([firstType isEqualToString:@"i"]){
        return @"integer";
    } else if([firstType isEqualToString:@"d"]){
        return @"real";
    } else if([firstType isEqualToString:@"l"] || [firstType isEqualToString:@"q"]){
        return @"real";
    } else if([firstType isEqualToString:@"c"] || [firstType isEqualToString:@"B"]){
        return @"bool";
    } else if([firstType isEqualToString:@"s"]){
        return @"integer";
    } else if([firstType isEqualToString:@"I"]){
        return @"integer";
    } else if([firstType isEqualToString:@"Q"]){
        return @"integer";
    } else if([firstType isEqualToString:@"@\"NSData\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@\"NSDate\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@\"NSString\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@"]){
        return @"text";
    }else {
        return @"text";
    }
    return nil;
}
#pragma mark - public Method

-(BOOL)isDbFileExist
{
    BOOL result = _isExist;
    if (_isExist) {
        _isExist = NO;
    }
    return result;
}

#pragma mark - private Method

- (void)close{
    
    [_dataBase close];
    _dataBase = nil;
}

- (void)connect{
    
    if (!_dataBase) {
        _dataBase = [FMDatabase databaseWithPath:self.dbFile];
    }
    
    if (![_dataBase open]) {
        NSAssert(NO, @"can not open db file");
    } else {
        _isExist = YES;
    }
}

- (void)dealloc{
    
    [self close];
    self.dbFile = nil;
    self.dbQueue = nil;
}

@end
