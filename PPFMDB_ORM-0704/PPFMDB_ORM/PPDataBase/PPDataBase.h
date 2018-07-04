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
 @return GDataBase实例
 */
+ (instancetype)databaseWithPath:(NSString *)dbPath;
+ (instancetype)databaseWithPath:(NSString *)dbPath isBase64Encode:(BOOL)isEncode;




/**
 不开启事务， 向数据库添加一条数据
 @return PPDataBaseD实例
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



@end
