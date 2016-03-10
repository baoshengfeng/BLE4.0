/*
 BLETIOADProfile.m
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "BLETIOADProfile.h"
#import "BLETIOADProgressDialog.h"
#import "BLEUtility.h"


@interface BLETIOADProfile()<UIAlertViewDelegate>

@end


@implementation BLETIOADProfile


-(id) initWithDevice:(BLEDevice *) dev {
    self = [[BLETIOADProfile alloc]init];
    if (self) {
        self.d = dev;
        self.canceled = FALSE;
        self.inProgramming = FALSE;
        self.start = YES;
    }
    return self;
}


//配置OAD服务及特征的UUID
-(void) makeConfigurationForProfile {
    if (!self.d.setupData) self.d.setupData = [[NSMutableDictionary alloc] init];
    // Append the UUID to make it easy for app
    [self.d.setupData setValue:@"0xF000FFC0-0451-4000-B000-000000000000" forKey:@"OAD Service UUID"];//OAD服务的UUID
    [self.d.setupData setValue:@"0xF000FFC1-0451-4000-B000-000000000000" forKey:@"OAD Image Notify UUID"]; //OAD固件身份C查询特征的UUID
    [self.d.setupData setValue:@"0xF000FFC2-0451-4000-B000-000000000000" forKey:@"OAD Image Block Request UUID"]; //OAD固件数据传输特征的UUID
    NSLog(@"%@",self.d.setupData);
    
}

//请求外设设备的固件信息
-(void) configureProfile {
    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];//获取OAD服务的UUID
    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];//获取OAD固件身份查询特征的UUID
    CBUUID *bUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Block Request UUID"]];
    
    //NSLog(@"12345外设名字:%@",self.d.p.name);
    
    [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];//订阅OAD固件身份查询特征
    [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:bUUID enable:YES];
    unsigned char data = 0x01;
    
    [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];//向OAD固件身份查询发送数据1
    NSLog(@"Send data 1 to OAD Image Notify UUID");
    
    self.imgVersion = 0xFFFF;
    self.imgUid = 0xFF;
    self.start = YES;
}

//订阅OAD固件身份查询特征
-(void) deconfigureProfile {
    NSLog(@"Deconfiguring OAD Profile");
    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];//获取OAD服务的UUID
    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];//获取OAD固件身份查询特征的UUID
    
    [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];//订阅OAD固件身份查询特征
}

#if !PURIFY_OTA_MODEL_CODE
//Select file按钮按下
-(IBAction)selectImagePressed:(id)sender {
    if (![self.d.p isConnected]) {//设备未连接，跳出警示窗口
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Device disconnected !" message:@"Unable to start programming when device is not connected ..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Reconnect",nil];
        [alertView show];
        alertView.tag = 1;
        return;
    }
    //显示文件源:Internal image还是Shared files
    UIActionSheet *selectImageActionSheet = [[UIActionSheet alloc]initWithTitle:@"Select image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Internal Image ...",@"Shared files ...",nil];
    selectImageActionSheet.tag = 0;
    [selectImageActionSheet showInView:self.view];

    
}


//按钮Select file的回调函数
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"Button clicked : %d",buttonIndex);
    switch (actionSheet.tag) {
        case 0: {
            switch(buttonIndex) {
                case 0: {//按下按钮Internal Image
                    UIActionSheet *selectInternalFirmwareSheet = [[UIActionSheet alloc]initWithTitle:@"Select Firmware image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"SensorTagImgA.bin",@"SensorTagImgB.bin", nil];
                    selectInternalFirmwareSheet.tag = 1;
                    [selectInternalFirmwareSheet showInView:self.view];
                    break;
                }
                case 1: {//按下按钮Shared files
                    NSMutableArray *files = [self findFWFiles];
                    UIActionSheet *selectSharedFileFirmware = [[UIActionSheet alloc]init];
                    selectSharedFileFirmware.title = @"Select Firmware image";
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
        case 1: {//选择Internal Image中的文件
            switch (buttonIndex) {
                case 0: {
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"SensorTagImgA.bin"];
                    [self validateImage:path];
                    break;
                }
                case 1: {
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"SensorTagImgB.bin"];
                    [self validateImage:path];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 2: {//选择Shared files中的文件
            if (buttonIndex == actionSheet.numberOfButtons - 1) break;
            NSMutableArray *files = [self findFWFiles];
            NSString *fileName = [files objectAtIndex:buttonIndex];
            [self validateImage:fileName];
            break;
        }
        default:
        break;
    }
}
#endif

//读取选取的升级文件的固件信息
-(void) uploadImage:(NSString *)filename {
    self.inProgramming = YES;
    self.canceled = NO;
    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    uint8_t requestData[OAD_IMG_HDR_SIZE + 2 + 2]; // 12Bytes
    
    //for(int ii = 0; ii < 20; ii++) {//打印固件信息首部数据
    //    NSLog(@"%02hhx",imageFileData[ii]);
    //}
    
    
    //选中文件的头信息
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    
    //获取选中文件的固件版本号
    requestData[0] = LO_UINT16(imgHeader.ver);
    requestData[1] = HI_UINT16(imgHeader.ver);
    
    //获取选中文件的固件长度
    requestData[2] = LO_UINT16(imgHeader.len);
    requestData[3] = HI_UINT16(imgHeader.len);
    
    NSLog(@"Image version = %04hx, len = %04hx",imgHeader.ver,imgHeader.len);
    
    //获取选中文件的固件ID，如4个'A'或4个'B'
    memcpy(requestData + 4, &imgHeader.uid, sizeof(imgHeader.uid));
    
    requestData[OAD_IMG_HDR_SIZE + 0] = LO_UINT16(12);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(12);
    
    requestData[OAD_IMG_HDR_SIZE + 2] = LO_UINT16(15);
    requestData[OAD_IMG_HDR_SIZE + 3] = HI_UINT16(15);

    //NSLog(@"UUID==%@",[self.d.setupData valueForKey:@"OAD Service UUID"]);
    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];

    //向OAD询问固件信息特征发送选中文件的固件信息
    [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2]];
    
    self.nBlocks = imgHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);//计算block的个数，给个block为16字节
    self.nBytes = imgHeader.len * HAL_FLASH_WORD_SIZE;//计算固件的总字节数
    self.iBlocks = 0;//传递完毕的block的个数
    self.iBytes = 0;//传递完毕的字节总数
   
    //启动一个一次性的定时器，定时时间为0.1s
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
    
}

//周期地传输升级文件的数据
-(void) programmingTimerTick:(NSTimer *)timer
{
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }
    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    //准备一个block数据帧，包括2字节的统计数据和16字节的升级文件数据快
    uint8_t requestData[2 + OAD_BLOCK_SIZE];
    
    // This block is run 4 times, this is needed to get CoreBluetooth to send consequetive packets in the same connection interval.
    for (int ii = 0; ii < 4; ii++)
    {
        //填充两个字节的统计数：传递完的字节总数
        requestData[0] = LO_UINT16(self.iBlocks);
        requestData[1] = HI_UINT16(self.iBlocks);
        //填充一个块的升级文件数据块数据
        memcpy(&requestData[2] , &imageFileData[self.iBytes], OAD_BLOCK_SIZE);
        
        CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
        CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Block Request UUID"]];
        //向OAD数据传递特征发送一个块的升级文件数据
        [BLEUtility writeNoResponseCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE]];
        
        self.iBlocks++;//已传输完毕的数据块个数
        self.iBytes += OAD_BLOCK_SIZE;//已传递完毕的的总字节数
        
        
        
        if(self.iBlocks == self.nBlocks) {//传输完毕
#if !PURIFY_OTA_MODEL_CODE
            if ([BLEUtility runningiOSSeven]) {
                [self.navCtrl popToRootViewControllerAnimated:YES];
            }
            else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
#endif
            self.inProgramming = NO;
            //[self completionDialog];
            return;
        }
        else {//启动一个一次性的定时器，定时时间按为0.09s
            if (ii == 3)[NSTimer scheduledTimerWithTimeInterval:0.07 target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
        }
    }
    
#if !PURIFY_OTA_MODEL_CODE
    self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);//显示进度条进度
    self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];//显示已完成的百分比
#endif
    float secondsPerBlock = 0.05 / 4;//传输每个数据块数据所需要的时间
    float secondsLeft = (float)(self.nBlocks - self.iBlocks) * secondsPerBlock;//计算传递完毕剩余需要的时间
    
#if !PURIFY_OTA_MODEL_CODE
    if ([BLEUtility runningiOSSeven]) {//iOS7设备
        self.progressView.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);//显示进度条进度
        self.progressView.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];//显示完成的百分比
        self.progressView.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];//显示距传输完毕的剩余时间
    }
    else {
        self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);//显示进度条进度
        self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];//显示完成的百分比
        self.progressDialog.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];//显示距传输完毕还剩余的时间
    }
#endif
    
#if PURIFY_OTA_MODEL_CODE
    float progress = (float)((float)self.iBlocks / (float)self.nBlocks);
    //NSLog(@"已完成:%0.1f%%, 剩余时间:%d:%02d", progress * 100, (int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60);
    
    NSString *progressStr = [NSString stringWithFormat:@"%f",progress];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateFirmwareProgress" object:progressStr];
    progressStr = nil;
#else
    float progress = (float)((float)self.iBlocks / (float)self.nBlocks);
    NSLog(@"%.1f", progress * 100);
#endif
    if (self.start) {
        self.start = NO;
        
#if !PURIFY_OTA_MODEL_CODE
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl pushViewController:self.progressView animated:YES];
        
        }
        else {
            self.progressDialog = [[BLETIOADProgressDialog alloc]initWithFrame:CGRectMake((self.view.bounds.size.width / 2) - 150, (self.view.bounds.size.height /2) - 80, self.view.bounds.size.width, 160)];
            self.progressDialog.delegate = self;
            [self.progressDialog show];
        }
#endif
    }
}

//处理OAD固件信息请求特征索收到的数据
-(void) didUpdateValueForProfile:(CBCharacteristic *)characteristic
{
    //NSLog(@"OAD UUID is: %@",characteristic.UUID);
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]]])  //是OAD固件信息请求特征
    {
        NSLog(@"OAD Image notify UUID receive data: %@",characteristic.value);
        if (self.imgVersion == 0xFFFF)
        {
            unsigned char data[characteristic.value.length];
            [characteristic.value getBytes:&data];//获取该特征收到的数据
            self.imgVersion = ((uint16_t)data[1] << 8 & 0xff00) | ((uint16_t)data[0] & 0xff);//提取固件的版本信息
           // NSLog(@"111111self.imgVersion == %hu",self.imgVersion);
            self.imgUid = data[4];
            NSLog(@"self.imgVersion : v%d.%d, self.imgUid : %c",data[1], data[0], self.imgUid);
            
            //发送版本通知
            NSString *versionStr = [NSString stringWithFormat:@"版本:%d.%d , 类型:%c",data[1], data[0] ,self.imgUid];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GetHardwareVersionInformation" object:versionStr];
            versionStr = nil;
         }
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Block Request UUID"]]])  //是OAD固件数据请求特征
    {
        NSLog(@"OAD Image Block UUID receive data: %@",characteristic.value);
        unsigned char data[characteristic.value.length];
        [characteristic.value getBytes:&data];//获取该特征收到的数据
        
        static uint16_t lastBlock = 0xffff;
        uint16_t curBlock = ((uint16_t)data[1] << 8 & 0xff00) | ((uint16_t)data[0] & 0xff);
        
        if (curBlock == lastBlock)
        {
            static uint8_t cnt = 0;
            if (++cnt == 20)
            {
                cnt = 0;
                self.iBlocks = curBlock;
                self.iBytes = self.iBlocks * OAD_BLOCK_SIZE;
            }
        }
        lastBlock = curBlock;
        
        if (self.iBlocks == self.nBlocks)
        {
            if ((curBlock + 1) == self.nBlocks)
            {
                [self completionDialog:(1)];//升级成功
                NSLog(@"空中升级成功");
            }
        }
    }
}

-(void) didWriteValueForProfile:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForProfile : %@",characteristic);
}

//查找.bin文件
-(NSMutableArray *) findFWFiles {
    NSMutableArray *FWFiles = [[NSMutableArray alloc]init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *publicDocumentsDir = [paths objectAtIndex:0];
    
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:publicDocumentsDir error:&error];
    
    if (files == nil) {
        NSLog(@"Could not find any firmware files ...");
        return FWFiles;
    }
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"bin" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSString *fullPath = [publicDocumentsDir stringByAppendingPathComponent:file];
            [FWFiles addObject:fullPath];
        }
    }

    return FWFiles;
}

#if !PURIFY_OTA_MODEL_CODE

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        self.canceled = TRUE;
        self.inProgramming = NO;
    }
    else if ((alertView.tag == 1) && buttonIndex == 1) {
        [self.d.manager connectPeripheral:self.d.p options:nil];
    }
}
#endif

//升级过程中，外设连接断开
-(void)deviceDisconnected:(CBPeripheral *)peripheral {
    if ([peripheral isEqual:self.d.p] && self.inProgramming) {
#if !PURIFY_OTA_MODEL_CODE
        [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
#endif
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"FW Upgrade Failed !" message:@"Device disconnected during programming, firmware upgrade was not finished !" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = 0;
        [alertView show];
        self.inProgramming = NO;
    }
}

//检测升级文件是否有效
-(BOOL)validateImage:(NSString *)filename {
    self.imageFile = [NSData dataWithContentsOfFile:filename];//获取文件名
    NSLog(@"Loaded firmware \"%@\"of size : %lu",filename,(unsigned long)self.imageFile.length);
    if ([self isCorrectImage]) [self uploadImage:filename];
    return NO;
}

//检测升级文件的类型是否正确
-(BOOL) isCorrectImage {
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    NSLog(@"imgHeader.ver: %04hx, self.imgVersion: %04hx", imgHeader.ver, self.imgVersion);
    NSLog(@"imgHeader.uid[0]: %d, self.imgUid: %d", imgHeader.uid[0], self.imgUid);
    
    if ((imgHeader.ver > self.imgVersion) && (imgHeader.uid[0] != self.imgUid)) return YES;//升级文件的固件版本比外设的固件版本高，且固件类型不相同
    
    if (imgHeader.ver <= self.imgVersion) {
        UIAlertView *wrongVersion = [[UIAlertView alloc]initWithTitle:@"Latest Version already!" message: nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [wrongVersion show];
        NSLog(@"Image file version:%04hx is lower BLE device's firmware version:%04hx", imgHeader.ver, self.imgVersion);
        return NO;
    }
    if (imgHeader.uid[0] == self.imgUid) {
        UIAlertView *wrongImage = [[UIAlertView alloc]initWithTitle:@"Wrong image type !" message:[NSString stringWithFormat:@"Image that was selected was of type : %c, which is the same as on the peripheral, please select another image",self.imgUid] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [wrongImage show];
        NSLog(@"Image file type:%c is the same as peripheral's fimeware type:%c", imgHeader.uid[0], self.imgUid);
        return  NO;
    }

    return NO;
}

//升级结束
-(void) completionDialog:(uint8_t)completeState {
    UIAlertView *complete;
    complete.delegate = self;
    if (completeState == 1)
        complete = [[UIAlertView alloc]initWithTitle:@"Firmware upgrade successed!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    else
        complete = [[UIAlertView alloc]initWithTitle:@"Firmware upgrade failed!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [complete show];
}

#pragma mark- UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"completeHardwareUpadateInformation" object:nil];
}

@end





