//
//  ReceiveAndSendDataVC.m
//  CHB-BLE
//
//  Created by baoshengfeng on 15/10/22.
//  Copyright (c) 2015年 baoshengfeng. All rights reserved.
//

#import"ReceiveAndSendDataVC.h"
#import "HardwareUpdateViewController.h"

@interface ReceiveAndSendDataVC () <UIAlertViewDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong , nonatomic) UIAlertView *disconnectAlertView;
//@property (strong , nonatomic) UITextView *tv;
@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *deviceServiceArray;
@property (strong, nonatomic) NSMutableDictionary *deviceServiceDict;

//@property (strong, nonatomic) NSMutableArray *serviceList;
//@property (strong, nonatomic) NSMutableArray *characteristicList;
@end

@implementation ReceiveAndSendDataVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self customInit];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    BLECentral *central = [BLECentral sharedInstance];
    central.centralDelegate = self;
}

-(void)customInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnectPeripheral) name:@"DISCONNECTPERIPHERAL" object:nil];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ReceiveCellRusing"];
    [self.view addSubview:_tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UIBarButtonItem  *rightBnItem = [[UIBarButtonItem alloc] initWithTitle:@"固件升级" style:UIBarButtonItemStylePlain target:self action:@selector(updateHardWare)];
    self.navigationItem.rightBarButtonItem = rightBnItem;
}

-(void)updateHardWare
{
    HardwareUpdateViewController *hardwareVC = [[HardwareUpdateViewController alloc] init];
    [self.navigationController pushViewController:hardwareVC animated:YES];
}
//发送数据给外设
//-(void)sendData
//{
//    BLECentral *centalBLE = [BLECentral sharedInstance];
//    
//    [centalBLE sendData:_tv.text];
//}

-(void)disconnectPeripheral
{
    self.disconnectAlertView = [[UIAlertView alloc] initWithTitle:@"与外设备断开连接" message:@"请重新连接" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [self.disconnectAlertView show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.disconnectAlertView) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource,UITableViewDelegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.deviceServiceArray.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *dict = [self.deviceServiceArray objectAtIndex:section];
    
    __block NSInteger i = 0;
    __block NSArray *tempArr;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        tempArr = (NSArray *)obj;
        i++;
    }];
    
    if (i > 1) {
        NSLog(@"TableView刷新错误,字典里存在2个及以上的元素,需分析错误");
        return 0;
    }
    
    return tempArr.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ReceiveCellRusing"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ReceiveCellRusing"];
    }
    
    cell.textLabel.numberOfLines = 0;
    
    __block NSInteger i = 0;
    __block NSArray *tempArr;
    //__block NSString *tempKey;
    NSDictionary *dict = [_deviceServiceArray objectAtIndex:indexPath.section];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        tempArr = obj;
        //tempKey = key;
        i++;
    }];
    
    if (i > 1) {
        NSLog(@"Cell刷新错误,字典里存在2个及以上的元素,需分析错误");
        return nil;
    }
    
    CBCharacteristic *characteristic = [tempArr objectAtIndex:indexPath.row];
    
    NSString *keyStr = [NSString stringWithFormat:@"%@",characteristic.UUID];
    if ([keyStr isEqualToString:@"Battery Level"]) {
        Byte *byte = (Byte *)[characteristic.value bytes];
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %hhu%@",characteristic.UUID,byte[0],@"%"];
        
        keyStr = nil;
        return cell;
    }
    
    keyStr = nil;

    NSString *tempStr = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",characteristic.UUID,tempStr];
    
    tempStr = nil;
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict =  [_deviceServiceArray objectAtIndex:section];
    
    __block NSInteger i = 0;
    __block NSString *tempStr;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        tempStr = (NSString *)key;
        i++;
    }];
    
    if (tempStr && i<2) {
        return tempStr;
    }
    return @"未知服务";
}

#pragma mark - blueToothDelegate
-(void)hasDiscoverredService:(CBUUID *)serviceUuid andCharacter:(CBCharacteristic *)character
{
    if (!_deviceServiceArray) {
        _deviceServiceArray = [[NSMutableArray alloc] init];
    }
    if (!_deviceServiceDict) {
        _deviceServiceDict = [[NSMutableDictionary alloc] init];
    }
    
    NSString *serviceUuidStr = [NSString stringWithFormat:@"%@",serviceUuid];
    
    if (![_deviceServiceDict.allKeys containsObject:serviceUuidStr]) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        [arr addObject:character];
        [_deviceServiceDict setObject:arr forKey:serviceUuidStr];
    } else {
        NSMutableArray *arr = [_deviceServiceDict objectForKey:serviceUuidStr];
        [arr addObject:character];
        [_deviceServiceDict setObject:arr forKey:serviceUuidStr];
    }
    
    NSMutableArray *tempArr = [[NSMutableArray alloc] init];
    [_deviceServiceDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        NSDictionary *tempDict = [NSDictionary dictionaryWithObjectsAndKeys:obj,key,nil];
        [tempArr addObject:tempDict];
    }];
    
    _deviceServiceArray = tempArr;
    tempArr = nil;
    
    //NSLog(@"数组：%@",_deviceServiceArray);
    
    [self.tableView reloadData];
}
@end
