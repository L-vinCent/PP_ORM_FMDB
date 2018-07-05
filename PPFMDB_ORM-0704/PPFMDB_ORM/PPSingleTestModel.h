//
//  PPSingleTestModel.h
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/4.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPDataModelProtocol.h"
@interface PPSingleTestModel : NSObject<PPDataModelProtocol>

@property(nonatomic,strong)NSString *testStudent;
@property(nonatomic,assign)int testScore;
@property(nonatomic,strong)NSString *testTeacher;
@property(nonatomic,strong)NSString *testName;
@property(nonatomic,assign)int testClassNumber;
@property(nonatomic,assign)int testStuId;
@property(nonatomic,assign)int addId;


@end
