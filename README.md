
### PPDataBase 
---

将 FMDB  一些基本数据操作做了封装，基于线程安全。
适用于不是特别复杂的数据库处理
功能接口
* 数据的增删改查，表删除
* 批量数据插入，删除，开启事务
* 数据条件查询，支持自定义 SQL 语句，也可以使用字典
* 数据查询排序处理，数据条数限制
//todo
### 使用
将 PPDataBase 文件夹拖入到工程文件，添加 libsqlite.tbd 

初始化
``` .bash
#import "PPDataBase.h"

@property (nonatomic, strong) PPDataBase * database;


 NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:@"xx.db"];
    self.database = [PPDataBase databaseWithPath:path];
```

具体的各个方法使用请看 Demo

要查看数据是否插入成功，可以打开同步推或者ituns，找到自己的应用, 找到 xx.db文件 如果不显示，需要在info.plist里添加 Application supports iTunes file sharing 设置为 YES，重新启动就行.
![](https://upload-images.jianshu.io/upload_images/904629-401c4d9d9cacf7b8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

数据库工具推荐 [db browser for sqlite](http://sqlitebrowser.org)


[FMDB官方文档](https://github.com/ccgus/fmdb)


---


---


## 版本记录  （基于 ORM 的 FMDB 数据存储方案）
### 2018-07-03 
---
>ORM(object relation mapping) 对象关系映射关系 ,面向对象的对象模型和关系型数据之间的相互转换

说通俗点就是，我 C 端建立一个模型，可以根据模型的成员属性建表赋值，更新等。不用每次写 SQL 语句，像下面这种


``` .bash
CREATE TABLE XXTable (ID text primary key, student text,score integer,sumScore real,name text,age real,templateID text,timestamp real,type real,list text)
```
这还算中规中矩的那种，有些2，30个属性的就很难受了，更新表的时候很容易就出错，所以，需求就来了，可不可以直接操作模型来映射到数据库表呢，那当然是阔以的。从最简单的一个需求开始

在 C 端，我只需要建立一个模型，要存到数据库的时候，直接调用一个方法就能建立起对应的表，表内字段对应到模型各属性，当然，一定是线程安全的。

基于这么合理的要求，我们先看下 SQL 的建表语句和插入语句

``` .bash
CREATE TABLE XXTable (dataID text primary key,fields text,dataGroup integer,dataIndex real,name text,show real,templateID text,timestamp real,type real,list text)

insert or replace into XXTable (dataID,fields,dataGroup,dataIndex,name,show,templateID,timestamp,type,list) values  ('WOSHI_dataID','1234567',12,12,'?,',0,'?,',0,0,'?,')
```
需求简下来就是，给你一个模型，你给我拼成这么一段字符串，我直接执行 SQL 语句就行了。

这么一看其实就是字符串的拼接，不难，前提是要知道 数据库的保留字段，还有 iOS 的基本数据类型对应到数据库的类型

 流程思路大致是这样
先建数据库，然后查看数据库有没有对应的表，没有表就建表，根据模型的属性来建立字段。有表，拼接对应的 SQL 语句，就上面那种，然后 调 `executeUpdate` 执行.

基于目前只有插入单条数据的基本功能，功能类给出倆个接口，初始化。给个字符串参数，用于数据库命名。然后另外一个函数就是，插入一条数据到数据库了，参数接受是一个遵循统一`协议`的模型。

至于为什么要单独独立出来一个协议，em~~~,下面的解释应该能接受
> `Objective-c` 面向对象的C, 继承概念体现在单类继承,用协议实现C++中的`多类继承`，避免一个子类继承多个父类时的复杂性，使类层次结构扁平。
比如车作父类，下面有两个子类燃油车和电动车，若需要混合动力车，按多父类继承，混合动力车需要继承两个父类，类层次为三层；但若是用协议方式，混合动力车实现燃油和电动协议，类层次只需要两层。

> 回到 iOS 里， 比如说 `NSArray` 实现了 `NSFastEnumeration` 协议， `NSDictionary`，`NSSet` 也都实现了 `NSFastEnumeration` 协议，虽然它们的实现方式是不一样的，但是它们都可以 fast enumeration，就跟飞机和鸟都会飞是一样的，当你需要一个可以 fast enumeration 的对象时，你就不用管它具体是 `NSArray` 还是 `NSDictionary`， 只要是一个服从 `NSFastEnumeration` 协议的对象即可

具体的业务逻辑还是看代码，先贴出来 [Demo-单条数据插入](https://github.com/L-vinCent/PP_ORM_FMDB)，目前只做了单条数据插入



### 2018-07-04
---
新增
* 独立出一个扩展文件，存放数据库操作的所有函数方法接口 
* 批量数据插入，开启事务.  
* 全部数据查询 ， 以 model 形式给出


### 2018-07-05
---
新增
* 数据库单条数据删除，一组数据删除
* 建表可选主键是否自增

### 2018-07-07
---
新增
*  数据库保留字段处理，类似 DELETE，INSERT，避免模型属性出现这些保留字段无法操作
* 黑名单组，筛选掉模型对应属性，不保存到数据库
* 数据库更新对应符合条件的数据
* 数据库条件语句查询

### 2018-07-09
---
新增
* 自定义 SQL 条件语句查询
* 数据库条件语句查询,可做升序降序处理，可限制查询到的数据条数
* 获取表中符合数据的条数
* 删除表
* 部分单元测试用例
