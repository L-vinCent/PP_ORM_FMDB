//
//  PPDBManager+PPDBInterface.h
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/4.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPDBManager.h"
#import "PPDataModelProtocol.h"
#import <objc/runtime.h>
@class FMDatabaseQueue,FMDatabase;

@interface PPDBManager ()

@property (nonatomic, strong, readonly) FMDatabase * dataBase;
@property (nonatomic, copy  ) NSString * dbFile;
@property (nonatomic, strong) FMDatabaseQueue * dbQueue;
@property (nonatomic, strong) NSArray * sqliteReservedWords;
/// 是否开启base64编码,默认不开启
@property (nonatomic, assign) BOOL  isEncode;



- (instancetype)initWithDBPath:(NSString*)dbPath;
- (BOOL)isDbFileExist;

#pragma mark - table check

- (void)tableCheck:(id<PPDataModelProtocol>)dataObject;
- (void)tableCheck:(id<PPDataModelProtocol>)dataObject withTableName:(NSString *)tableName;


#pragma mark - table Create Method

- (void)createTableSingleKey:(FMDatabase*)db table_name:(NSString*)table_name fileds:(NSArray*)fileds primaryKey:(NSString*)primaryKey objClass:(Class)objClass;

- (NSArray*)excuteSql:(NSString*)sql withClass:(Class)clazz;







#pragma mark - insert record Method

- (NSString *)getInsertRecordQuery:(id<PPDataModelProtocol>)dataObject;
- (NSString *)getInsertRecordQuery:(id<PPDataModelProtocol>)dataObject withTableName:(NSString *)tableName;
- (void)insertCol:(NSString*)colName db:(FMDatabase*)db objClass:(Class)objClass;

/// 处理和解码sqlite 保留字段    有保留字段的需要加 中括号处理
- (NSString*)processReservedWord:(NSString*)property_key;
- (NSString*)DeProcessReservedWord:(NSString*)property_key;



#pragma mark - SQL format Method
- (NSString *)formatDeleteSQLWithObjc:(id<PPDataModelProtocol>)data_obj withTableName:(NSString*)tableName;


- (NSString*)getPropertySign:(objc_property_t)property;
- (NSString*)getSqlKindbyProperty:(objc_property_t)property;



@end
