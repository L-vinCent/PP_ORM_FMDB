//
//  ViewController.m
//  PPFMDB_ORM
//
//  Created by Liao PanPan on 2018/7/3.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "ViewController.h"
#import "PPDataBase.h"
#import "PPSingleTestModel.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) PPDataBase * database;
@property(nonatomic,strong)NSArray *dataArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadDataBase];
    [self.view addSubview:self.tableView];
    
    
}

- (void)loadDataBase
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:@"PPDATA.db"];
    self.database = [PPDataBase databaseWithPath:path];
    
    
}


-(UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
    
}

-(NSArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = @[
                       @"单条数据插入",
                       @"批量数据插入,开启事务",
                       @"查询所有数据,开启事务",
                       @"根据主键删除模型",
                       ];
    }
    return _dataArray;
}

- (void)insertOneRowData
{
    PPSingleTestModel *model = [[PPSingleTestModel alloc]init];
    model.testName = @"哈";
    model.testScore = 88;
    model.testTeacher = @"大老师";
    model.addId = 1;
    BOOL isSucess = [self.database addObject:model];
    NSLog(@"isSucess -- 单条数据插入成功%d",isSucess);

}


-(void)getAllSQLData
{
    NSArray * all = [self.database getAllObjectsWithClass:[PPSingleTestModel class]];
    
    for (PPSingleTestModel *model in all) {
        
        NSLog(@"%@",[model description]);
        
    }
    
}

-(void)insertLargeDataInTranscation
{

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
        NSLog(@"批量数据插入 -- %d",isSucess);
    });
  
}

-(void)deleteByMainKey
{
    
    NSArray * all = [self.database getAllObjectsWithClass:[PPSingleTestModel class]];
    if(!all.count) return;
    PPSingleTestModel *model = all[0];
    BOOL delete = [self.database deleteObject:model];
    NSLog(@"删除状态 --- %d",delete);
    
    
}

#pragma mark -- TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tableViewCell"];
    }
    NSString *title = self.dataArray[indexPath.row];
    cell.textLabel.text = title;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        [self insertOneRowData];
    }
    if (indexPath.row == 1) {
        
        [self insertLargeDataInTranscation];
    }
    if (indexPath.row == 2) {
        
        [self getAllSQLData];
    }
    
    if (indexPath.row == 3) {
        
        [self deleteByMainKey];
    }
}
@end
