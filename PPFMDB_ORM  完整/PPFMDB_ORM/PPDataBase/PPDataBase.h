//
//  PPDataBase.h
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/4.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPDataModelProtocol.h"
#import "PPDBManager.h"

@interface PPDataBase : PPDBManager


/**
 构造方法
 
 @param dbPath 如果没有文件会默认创建xx.db 文件
 isEncrypt 是否开启对字符串进行base64编码,default不开启
 @return PPDataBase实例
 */
+ (instancetype)databaseWithPath:(NSString *)dbPath;
+ (instancetype)databaseWithPath:(NSString *)dbPath isBase64Encode:(BOOL)isEncode;




/**
 不开启事务， 向数据库添加一条数据
 @return PPDataBase实例
 */
- (BOOL)addObject:(id<PPDataModelProtocol>)obj;

- (BOOL)addObject:(id<PPDataModelProtocol>)obj WithTableName:(NSString*)tableName;


/**
 往数据库中增加一组数据,开始事务.
 
 @param objs objs <数组中模型需要遵守GDataObjectProtocol>
 @param tableName 数据表名,传nil则默认表明为类名
 @return YES/NO
 */
- (BOOL)addObjectsInTransaction:(NSArray*)objs WithTableName:(NSString*)tableName;



/**
 获取数据表中的全部数据
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名.
 @param clazz 需要查询的模型Class
 @return class表的全部数据，封装到Model,以数组返回
 */
- (NSArray*)getAllObjectsWithClass:(Class)clazz;
- (NSArray*)getAllObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName;


/**
 从数据库中删除一条(组)数据
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名
 
 @param obj <需要遵守GDataObjectProtocol>
 @return YES/NO
 */
- (BOOL)deleteObject:(id<PPDataModelProtocol>)obj;
- (BOOL)deleteObject:(id<PPDataModelProtocol>)obj withTableName:(NSString *)tableName;
- (BOOL)deleteObjects:(NSArray<id<PPDataModelProtocol>>*)objs;
- (BOOL)deleteObjects:(NSArray<id<PPDataModelProtocol>>*)objs withTableName:(NSString*)tableName;


/**
 更新数据
 @param clazz 要更新的数据模型,默认表名为 clazz 类名
 @param keyValues 需要更新的字段键值对 <key:属性名 value:需要更新的值>
 @param conDic 条件语句对,允许多条件语句 <key:属性名 value:需要更新的值> 就是  WHERE key = value
 @return YES/NO
 */

- (BOOL)updateObjectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues contionKeyDic:(NSDictionary *)conDic;

/**
 更新数据
 @param tableName 如果不传，默认 clazz 类名
 @param clazz 要更新的数据模型
 @param keyValues 需要更新的字段键值对 <key属性名 value需要更新的值>
 @param conDic 条件语句对,允许多条件语句 <key:属性名 value:需要更新的值> 就是  WHERE key = value
 @return YES/NO
 */
- (BOOL)updateTableName:(NSString*)tableName ObjectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues contionKeyDic:(NSDictionary *)conDic;


/**
 条件语句查询

 @param clazz 模型类
 @param dic 条件字段键值对 <key属性名 value需要查询的条件值>
 @return 数组<clazz>
 */
- (NSArray *)getObjectsWithClass:(Class)clazz whereCondDic:(NSDictionary *)dic;


/**
 条件查询，做排序处理

 @param clazz 模型类
 @param tableName 表名，不传默认以模型名做表名
 @param orderName 根据这个字段做排序处理
 @param up 默认为升序
 @param count 拿多少条数据   , 0 默认拿全部数据
 @param contionDic <key属性名 value需要查询的条件值>
 @return 数组<clazz>
 */
- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName orderBy:(NSString*)orderName up:(BOOL)up limit:(NSInteger)count condDic:(NSDictionary *)contionDic;



/**
 条件查询，支持自定义条件 SQL语句
 
 @param clazz 模型类
 @param tableName 表名，如果为空，默认为模型名
 @param predicateFormat 自定义的 SQL 语句
 @return 数组<clazz>
 
 */
- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName CustomCond:(NSString *)predicateFormat, ...;


/**
 根据condition获取数据表中数据的个数
 @breif:不传tableName 则默认使用类名作为表名.
 @param clazz 需要查询的模型Class
 @param contionDic 格式化查询条件.
 @example:[...xxxcond:@"dataID = '%@ AND id=%d'",dataID, 12]
 @return 数据表中符合条件的数据的个数
 */
- (long)countInDataBaseWithClass:(Class)clazz withTableName:(NSString*)tableName condDic:(NSDictionary *)contionDic;

/**
 删除数据表
 
 @param clazz 如果表名为class 可使用第一种
 @return YES/NO
 */
- (BOOL)removeTableWithClass:(Class)clazz;

- (BOOL)removeTable:(NSString*)table_name;

@end
