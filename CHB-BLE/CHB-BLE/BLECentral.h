//
//  BLECentral.h
//  CHB-BLE
//
//  Created by baoshengfeng on 15/10/21.
//  Copyright (c) 2015年 baoshengfeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol blueToothDelegate <NSObject>
@optional
-(void)hasDiscoverredPeripheral:(CBPeripheral *)peripheral;
-(void)sucessfullyConnectedThePeripheral;
-(void)centralManagerHasDisconnectedPeripheral;
-(void)hasDiscoverredService:(CBUUID *)serviceUuid andCharacter:(CBCharacteristic *)character;
-(void)hasDiscoverredCharacteristic:(CBCharacteristic *)characteristic;

@end

@interface BLECentral : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic)  CBPeripheral *connectedPeripheral;//指向当前连接的蓝牙设备
@property (weak, nonatomic) id<blueToothDelegate> centralDelegate;
@property (strong, nonatomic) CBCharacteristic *theCharacteristic;

+(instancetype)sharedInstance;

-(void)startScan;
-(void)toConnectThePeripheral:(CBPeripheral *)peripheral;
-(void)sendData:(NSString *)dataStr;

@end
