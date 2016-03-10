//
//  MainViewController.m
//  CHB-BLE
//
//  Created by baoshengfeng on 15/10/21.
//  Copyright (c) 2015年 baoshengfeng. All rights reserved.
//

#import "MainViewController.h"
#import "BLECentral.h"
#import "BLEConnectingView.h"
#import "ReceiveAndSendDataVC.h"

@interface MainViewController ()<blueToothDelegate>
{
    NSIndexPath *_connectingIndexPath;
}
@property (strong, nonatomic) NSMutableArray *peripheralArray;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customInit];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self scanPeripheral];
}

-(void)customInit
{
    self.title = @"蓝牙通信";
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellRusing"];
    
    UIBarButtonItem  *rightBnItem = [[UIBarButtonItem alloc] initWithTitle:@"扫描" style:UIBarButtonItemStylePlain target:self action:@selector(scanPeripheral)];
    self.navigationItem.rightBarButtonItem = rightBnItem;
    
    self.peripheralArray = [[NSMutableArray alloc] init];
}

-(void)scanPeripheral
{
    BLECentral *central = [BLECentral sharedInstance];
    central.centralDelegate = self;
    
    [central startScan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)sendDisconnectInformation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DISCONNECTPERIPHERAL" object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.peripheralArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellRusing"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellRusing"];

    }
    
    CBPeripheral *peripheral = [self.peripheralArray objectAtIndex:indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    // Configure the cell...
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:_connectingIndexPath];
    if (oldCell) {
        oldCell.accessoryView = nil;
        oldCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    BLEConnectingView *accessoryView = [[BLEConnectingView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.height, cell.frame.size.height)];
    cell.accessoryView = accessoryView;
    
    _connectingIndexPath = indexPath;
    
    CBPeripheral *peripheral = [self.peripheralArray objectAtIndex:indexPath.row];
    
    [[BLECentral sharedInstance] toConnectThePeripheral:peripheral];
}

#pragma mark - customDelegate

#pragma mark - blueToothDelegate
-(void)hasDiscoverredPeripheral:(CBPeripheral *)peripheral
{
    
    for (CBPeripheral *savedPeripheral in self.peripheralArray)
    {
        if ([peripheral.name isEqualToString:savedPeripheral.name]) {
            return;
        }
    }
    
    [self.peripheralArray addObject:peripheral];
    
    [self.tableView reloadData];
}

-(void)sucessfullyConnectedThePeripheral
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_connectingIndexPath];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    ReceiveAndSendDataVC *receiveVC = [[ReceiveAndSendDataVC alloc] init];
    [BLECentral sharedInstance].centralDelegate = receiveVC;
    [self.navigationController pushViewController:receiveVC animated:YES];
}

-(void)centralManagerHasDisconnectedPeripheral
{
    NSLog(@"与外设的连接发生中断");
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_connectingIndexPath];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    [self sendDisconnectInformation];
}

@end
