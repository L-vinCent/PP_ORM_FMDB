//
//  PPInsertTest.m
//  PPFMDB_ORMTests
//
//  Created by Liao PanPan on 2018/7/9.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PPDataBase.h"
#import "PPSingleTestModel.h"
@interface PPInsertTest : XCTestCase

@property (nonatomic, strong) PPDataBase * database;

@end

@implementation PPInsertTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:@"DATATest.db"];
    self.database = [PPDataBase databaseWithPath:path];
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    PPSingleTestModel *model = [[PPSingleTestModel alloc]init];
    model.testName = @"插入数据测试用例";
    model.testScore = arc4random()%100;
    model.addId = 1;
    BOOL isSucess = [self.database addObject:model];
    
//    NSLog(@"isSucess -- 单条数据插入成功%d",isSucess);
    XCTAssertTrue(isSucess,@"单条数据插入不通过");
}


-(void)testGetAllData
{
    PPSingleTestModel *model = [[PPSingleTestModel alloc]init];
    model.testName = @"插入数据测试用例";
    model.testScore = arc4random()%100;
    model.addId = 1;
    BOOL isSucess = [self.database addObject:model];
    
    if (isSucess) {
        NSArray *dataArr = [self.database getAllObjectsWithClass:[PPSingleTestModel class]];
        XCTAssertTrue(dataArr.count>0,@"数据表查询测试用例不通过");
    }
    
}

- (void)testUpdateSqlData
{
    BOOL isSucess = [self.database updateObjectClazz:[PPSingleTestModel class] keyValues:@{@"testName":@"条件更新测试"} contionKeyDic:@{PPAUTOPRIMARYKEY:@"1"}];
    
    //数据库没数据的时候默认跳过测试
    NSInteger count = [self getDBDataCount];
    if(!count)  XCTAssertTrue(YES,@"数据库无数据，默认不测试直接通过");
    XCTAssertTrue(isSucess,@"数据更新测试不通过");
}

-(void)testInsertLargeDataInTranscation
{

    //性能测试
    [self measureBlock:^{
        
        NSMutableArray *modelArr = @[].mutableCopy;
        
        __weak typeof(self) weakSelf = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            for (int i=0; i<50; i++) {
                PPSingleTestModel *model = [[PPSingleTestModel alloc]init];
                model.testName = @"哈哈哈";
                model.testScore = 88;
                model.testStuId = i;
                model.testTeacher = @"大老师";
                [modelArr addObject:model];
            }
            BOOL isSucess = [weakSelf.database addObjectsInTransaction:modelArr WithTableName:nil];
            XCTAssertTrue(isSucess,@"开启事务插入数据用例测试不通过");
            
        });
        
    }];
    
   
    
    
}

-(NSInteger )getDBDataCount
{
    
    NSArray *dataArr = [self.database getAllObjectsWithClass:[PPSingleTestModel class]];
    return dataArr.count;
    
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
