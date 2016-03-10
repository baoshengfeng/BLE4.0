//
//  HardwareUpdateViewController.m
//  CHB-BLE
//
//  Created by baoshengfeng on 15/12/7.
//  Copyright (c) 2015年 baoshengfeng. All rights reserved.
//

#import "HardwareUpdateViewController.h"
#import "BLECentral.h"
#import "BLETIOADProfile.h"
#import "BLETIOADProgressViewController.h"
#import "BLEDevice.h"

#define BATTERY_LEVEL @"0x2A19";

@interface HardwareUpdateViewController ()<UIActionSheetDelegate , UIAlertViewDelegate,blueToothDelegate>
@property (strong, nonatomic) UIButton *selectFileBn;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UILabel *versionLabel;

@property (strong,nonatomic) BLETIOADProfile *oadProfile;
@property (strong, nonatomic) BLEDevice *dev;
@property (assign, nonatomic) BOOL discoverTheFistService;   //用于配合延迟操作

@end

@implementation HardwareUpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self customInt];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFirmwareUpdate:) name:@"UpdateFirmwareProgress" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getHardwareVersion:) name:@"GetHardwareVersionInformation" object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    BLECentral *central = [BLECentral sharedInstance];
    central.centralDelegate = self;
    
    
    BLEDevice *dev = [[BLEDevice alloc]init];
    dev.p = [BLECentral sharedInstance].connectedPeripheral;
    dev.manager = [BLECentral sharedInstance].centralManager;
    self.oadProfile = [[BLETIOADProfile alloc]initWithDevice:dev];
    
    [self.oadProfile makeConfigurationForProfile];
    
    [self.oadProfile configureProfile];
}

-(void)customInt
{
    self.view.backgroundColor = [UIColor whiteColor];

    self.discoverTheFistService = NO;

    _selectFileBn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 55, self.view.frame.size.height/2 - 50, 100, 50)];
    [_selectFileBn setTitle:@"固件升级" forState:UIControlStateNormal];
    [_selectFileBn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_selectFileBn addTarget:self action:@selector(selectFile:) forControlEvents:UIControlEventTouchUpInside];
    _selectFileBn.layer.cornerRadius = 10;
    _selectFileBn.backgroundColor = [UIColor colorWithRed:151.0/255 green:1 blue:1 alpha:0.7];
    [self.view addSubview:_selectFileBn];
    
    if (!_versionLabel) {
        _versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _selectFileBn.frame.origin.y + _selectFileBn.frame.size.height + 20, self.view.frame.size.width, 50)];
        //_versionLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        _versionLabel.layer.cornerRadius = 8;
        _versionLabel.textAlignment = NSTextAlignmentCenter;
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"hardwareVersion"]) {
        _versionLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"hardwareVersion"];
    }
    [self.view addSubview:_versionLabel];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _selectFileBn.backgroundColor = [UIColor colorWithRed:151.0/255 green:1 blue:1 alpha:0.7];
        _selectFileBn.enabled = YES;
    });
}

- (void)selectFile:(id)sender
{
#if !PURIFY_OTA_MODEL_CODE
    [self.oadProfile selectImagePressed:self];
#else
    [self selectImagePressed:self]; //调用下面这个方法
#endif
}

-(void)selectImagePressed:(id)sender
{
    // NSLog(@"selectImagePressed");
    
//    if (![self.discoveredPeripheral isConnected]) {
//        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Device disconnected !" message:@"Unable to start programming when device is not connected ..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Reconnect",nil];
//        [alertView show];
//        alertView.tag = 1;
//        return;
//    }
    
    //正常情况下显示的是下面这个警告框
    UIActionSheet *selectImageActionSheet = [[UIActionSheet alloc]initWithTitle:@"Select image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Internal Image ...",@"Shared files ...",nil];
    selectImageActionSheet.tag = 0;
    [selectImageActionSheet showInView:self.view];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)receiveFirmwareUpdate:(NSNotification *)noti
{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 120, self.view.frame.size.width - 20, 30)];
        CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 5.0f);
        _progressView.transform = transform;
    }
    [self.view addSubview:_progressView];
    
    NSString *progressStr = [noti object];
    
    [_progressView setProgress:[progressStr floatValue]];
    
    NSLog(@"进度＝%@",progressStr);
}

-(void)getHardwareVersion:(NSNotification *)noti
{
    if ([noti.object isKindOfClass:[NSString class]])
    {
        //保存固件的版本信息
        [[NSUserDefaults standardUserDefaults] setObject:noti.object forKey:@"hardwareVersion"];
    }
    
    //NSLog(@"版本信息：%@",noti.object);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_versionLabel) {
            _versionLabel.text = noti.object;
            
        }
        if (_progressView) {
            [_progressView removeFromSuperview]; //升级成功去掉进度条
        }
    });
}

#pragma mark- UIActionSheetDelegate

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag)
    {
        case 0:
        {
            switch(buttonIndex)
            {
                case 0: { //点击了Internal Image...
                    UIActionSheet *selectInternalFirmwareSheet = [[UIActionSheet alloc]initWithTitle:@"Select Firmware image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"1.0.bin",@"1.1.bin",@"1.2.bin",@"1.3.bin", nil];
                    selectInternalFirmwareSheet.tag = 1;
                    [selectInternalFirmwareSheet showInView:self.view];
                    break;
                }
                case 1: { //点击了Shared files......
                    NSMutableArray *files = [self.oadProfile findFWFiles];
                    UIActionSheet *selectSharedFileFirmware = [[UIActionSheet alloc]init];
                    selectSharedFileFirmware.title = @"1_Select Firmware image";
                    selectSharedFileFirmware.tag = 2;
                    selectSharedFileFirmware.delegate = self;
                    
                    for (NSString *fileName in files) {
                        [selectSharedFileFirmware addButtonWithTitle:[fileName lastPathComponent]];
                    }
                    [selectSharedFileFirmware addButtonWithTitle:@"Cancel"];
                    selectSharedFileFirmware.cancelButtonIndex = selectSharedFileFirmware.numberOfButtons - 1;
                    [selectSharedFileFirmware showInView:self.view];
                    
                    break;
                }
            }
            
            break;
        }
            
        case 1:
        {
            switch (buttonIndex)
            {
                case 0: { //点击了SensorTagImgA
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"iVebot_ImgA_v1.0.bin"];
                    [self.oadProfile validateImage:path];
                    break;
                }
                case 1: { //点击了SensorTagImgB
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"iVebot_ImgA_v1.1.bin"];
                    [self.oadProfile validateImage:path];
                    break;
                }
                case 2: { //点击了SensorTagImgB
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"iVebot_ImgB_v1.1.bin"];
                    [self.oadProfile validateImage:path];
                    break;
                }
                case 3: { //点击了SensorTagImgB
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"iVebot_ImgB_v1.2.bin"];
                    [self.oadProfile validateImage:path];
                    break;
                }
                    
                default:
                    break;
            }
            
            break;
        }
            
        case 2:
        {
            if (buttonIndex == actionSheet.numberOfButtons - 1)
                break;
            
            NSMutableArray *files = [self.oadProfile findFWFiles];
            
            NSString *fileName = [files objectAtIndex:buttonIndex];
            [self.oadProfile validateImage:fileName];
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark- UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 0) {
        self.oadProfile.canceled = TRUE;
        self.oadProfile.inProgramming = NO;
    }
    else if ((alertView.tag == 1) && buttonIndex == 1) {
        return;
    }
}

#pragma mark - blueToothDelegate
-(void)hasDiscoverredCharacteristic:(CBCharacteristic *)characteristic
{
    [self.oadProfile didUpdateValueForProfile:characteristic];
}
@end
