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
    self.database = [[PPDataBase alloc]init];
    [self.database databaseWithPath:path];
    
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
                   
                       ];
    }
    return _dataArray;
}

- (void)insertOneRowData
{
    PPSingleTestModel *model = [[PPSingleTestModel alloc]init];
    model.testName = @"文森";
    model.testScore = 88;
    model.testStuId = 2;
    model.testTeacher = @"大老师";
    BOOL isSucess = [self.database addObject:model];
    NSLog(@"isSucess -- 单条数据插入成功%d",isSucess);

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
    
}
@end
