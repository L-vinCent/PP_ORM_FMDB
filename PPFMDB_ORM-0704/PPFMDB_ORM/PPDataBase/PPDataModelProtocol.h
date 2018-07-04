//
//  PPDataModelProtocol.h
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/3.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
@protocol PPDataModelProtocol <NSObject>

@required

/*
 如果使用 PPDATABASE_IMPLEMENTATION_INJECT 宏， 就无需再实现该协议方法
 注意 必须在@implementation xxxClass 后,第一行注入该宏定义
 return 属性列表
 */
- (NSArray*)g_getAllProperty;

/**
 黑名单
 @breif: 如果模型中部分属性,无需存入数据库,在使用GDATABASE_IMPLEMENTATION_INJECT宏的情况下
 实现<+g_blackList>类方法,key为需要忽略的属性名.value可随意填写.
 如果没有使用GDATABASE_IMPLEMENTATION_INJECT宏. 可以在<-g_getAllProperty>方法中过滤相关属性.
 @return 黑名单列表
 */
- (NSDictionary<NSString *,NSString*> *)g_blackList;


@optional
/*
 如果需要返回多个主键，实现该协议
 默认为自增主键'PPAUTOPRIMARYKEY'
 */
- (NSArray<NSString *> *)g_GetCustomPrimarykey;


- (void)g_setValue:(id)value forUndefinedKey:(NSString *)key;



/**
 在使用GDATABASE_IMPLEMENTATION_INJECT宏的情况下, 模型类中如需额外初始化
 请实现'g_init'. 或者自定义其他构造方法.调用 '[super init]'
 */
- (void)g_init;

@end

/// 自增主键字段名称
#define PPAUTOPRIMARYKEY @"PPAUTOPRIMARYKEY"


/// 属性自定义归档支持转化sqltype字段
#define GTEXT_TYPE @"text"
#define GBLOB_TYPE @"blob"
//容错处理宏
#define kStringIsEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )



/*
 默认方法注入宏
 @breif: 1,默认实现了以下方法
 {
 - (NSArray<NSString *> *)g_getPrimarykey;
 - (NSArray*)g_getAllProperty;
 - (void)setValue:(id)value forUndefinedKey:(NSString *)key;
 }
 2,必须在@implementation xxxClass 后,第一行注入该宏定义
 @param clazz
 @return
 */
#define PPDATABASE_IMPLEMENTATION_INJECT(clazz) {\
NSMutableArray *_g_properties;\
long    _PPAUTOPRIMARYKEY;\
}\
- (instancetype)init\
{\
self = [super init];\
if (self) {\
_g_properties = [NSMutableArray array];\
[self g_loadAllProperties];\
if ([self respondsToSelector:@selector(g_init)]) {\
[self g_init];\
}\
}\
return self;\
}\
- (long)g_getAutoPrimaryKey{\
return _PPAUTOPRIMARYKEY;\
}\
- (NSArray*)g_getAllProperty\
{\
return _g_properties;\
}\
- (void)g_loadAllProperties\
{\
u_int count;\
objc_property_t *properties = class_copyPropertyList([self class], &count);\
NSAssert(count > 0, @"missting properties can not create table filed");\
NSMutableDictionary *defaultBlackList = [NSMutableDictionary dictionary];\
[defaultBlackList setObject:@"hash" forKey:@"hash"];\
[defaultBlackList setObject:@"superclass" forKey:@"superclass"];\
[defaultBlackList setObject:@"description" forKey:@"description"];\
[defaultBlackList setObject:@"debugDescription" forKey:@"debugDescription"];\
if ([self respondsToSelector:@selector(g_blackList)]) {\
NSDictionary *dict = [self g_blackList];\
[defaultBlackList setValuesForKeysWithDictionary:dict];\
}\
for (int i = 0; i < count ; i++)\
{\
const char* propertyName = property_getName(properties[i]);\
NSString *proNameStr = [NSString stringWithUTF8String: propertyName];\
if (![defaultBlackList objectForKey:proNameStr]) {\
[_g_properties addObject:proNameStr];\
}\
}\
free(properties);\
}\
- (void)setValue:(id)value forUndefinedKey:(NSString *)key\
{\
NSLog(@"ForUndefinedKey-- %@",key);\
if ([key isEqualToString:PPAUTOPRIMARYKEY]) {\
_PPAUTOPRIMARYKEY = [value longValue];\
}\
if ([self respondsToSelector:@selector(g_setValue:forUndefinedKey:)]) {\
[self g_setValue:value forUndefinedKey:key];\
}\
}\
