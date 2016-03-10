//
//  BLECentral.m
//  CHB-BLE
//
//  Created by baoshengfeng on 15/10/21.
//  Copyright (c) 2015年 baoshengfeng. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "BLECentral.h"
#import "BLETIOADProfile.h"
#import "BLETIOADProgressViewController.h"
#import "BLEDevice.h"

#define TRANSFER_SERVICE_UUID           @"0xFFE0"
#define TRANSFER_CHARACTERISTIC_UUID    @"0xFFE1"

//#define SERVICE_UUID_1 @"0x180A"
//#define SERVICE_UUID_2 @"FFE0"
//#define SERVICE_UUID_3 @"0x180F"
//
//#define S1_CHARACTERISTIC_UUID_1 @"2A24"
//#define S1_CHARACTERISTIC_UUID_2 @"2A26"
//#define S1_CHARACTERISTIC_UUID_3 @"2A29"
//#define S2_CHARACTERISTIC_UUID_1 @"FFE1"
//#define S3_CHARACTERISTIC_UUID_1 @"2A19"

static BLECentral *shareBLE;

@interface BLECentral()
@property (strong, nonatomic) NSMutableArray *discoverredPeripheralArray;

@property (strong,nonatomic) BLETIOADProfile *oadProfile;
@property (strong, nonatomic) BLEDevice *dev;
@property (assign, nonatomic) BOOL discoverTheFistService;   //用于配合延迟操作


@end

@implementation BLECentral

#pragma mark - life cycle

+(instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        shareBLE = [[BLECentral alloc] init];
        
        shareBLE.discoverTheFistService = NO;
    });

    return shareBLE;
}

-(void)startScan
{
    if (!self.centralManager) {
        //创建后若手机没开蓝牙会自动提示
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    
    if (self.discoverredPeripheralArray) {
        self.discoverredPeripheralArray = nil;
    }
    self.discoverredPeripheralArray = [[NSMutableArray alloc] init];
    
    [self scan];
}

-(void)scan
{
//    [self.centralManager scanForPeripheralsWithServices:
//                                     @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
//                                     options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    [self.centralManager retrieveConnectedPeripherals];
  //  [self.centralManager retrieveConnectedPeripheralsWithServices:@[]];
    
    NSLog(@"Scanning started");
}

-(void)toConnectThePeripheral:(CBPeripheral *)peripheral;
{
    NSLog(@"Connecting to peripheral %@", peripheral);
    
    [self.centralManager connectPeripheral:peripheral options:nil];
}

-(void)sendData:(NSString *)dataStr
{
    NSLog(@"外设备信息：%@,  特征：%@ ",self.connectedPeripheral,_theCharacteristic);

    NSData *dataSend = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.connectedPeripheral writeValue:dataSend forCharacteristic:_theCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)cleanup
{
    // Don't do anything if we're not connected
    if (self.connectedPeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.connectedPeripheral.services != nil) {
        for (CBService *service in self.connectedPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics)
                {
                   // if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
                   // {
                        if (characteristic.isNotifying)
                        {
                            // It is notifying, so unsubscribe
                            [self.connectedPeripheral setNotifyValue:NO forCharacteristic:characteristic];//不监听该特征

                            return;
                        }
                    //}
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
}


#pragma mark - CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙未开启");
        return;
    }
    
    [self scan];
}


-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
//    if (RSSI.integerValue < -100) {
//        return;
//    }

    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    for (CBPeripheral *savedPeripheral in self.discoverredPeripheralArray)
    {
        if ([savedPeripheral.name isEqualToString:peripheral.name]) {
            return;
        }
    }
    
    [self.discoverredPeripheralArray addObject:peripheral];
    
    if ([self.centralDelegate respondsToSelector:@selector(hasDiscoverredPeripheral:)]) {
        [self.centralDelegate hasDiscoverredPeripheral:peripheral];
    }
    
//    if (self.discoveredPeripheral != peripheral) {
//
//        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
//        self.discoveredPeripheral = peripheral;
//        
//        // And connect
//        NSLog(@"Connecting to peripheral %@", peripheral);
//        [self.centralManager connectPeripheral:peripheral options:nil];
//    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    self.connectedPeripheral = peripheral;
    
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");

    peripheral.delegate = self;
    
    if ([self.centralDelegate respondsToSelector:@selector(sucessfullyConnectedThePeripheral)]) {
        [self.centralDelegate sucessfullyConnectedThePeripheral];
    }
    
    //搜寻该外设的服务
   // [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
    [peripheral discoverServices:nil];
}

//Invoked when the central manager retrieves a list of peripherals currently connected to the system.
- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    for(CBPeripheral *peripheral in peripherals)
    {
        for (CBPeripheral *savedPeripheral in self.discoverredPeripheralArray)
        {
            if ([savedPeripheral.name isEqualToString:peripheral.name]) {
                return;
            }
        }
        
        [self.discoverredPeripheralArray addObject:peripheral];
        
        if ([self.centralDelegate respondsToSelector:@selector(hasDiscoverredPeripheral:)]) {
            [self.centralDelegate hasDiscoverredPeripheral:peripheral];
        }
    }
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
 
    for (CBService *service in peripheral.services) {
       // [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
       // [peripheral discoverCharacteristics:nil forService:service];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    //NSLog(@"服务：%@; 该服务下的外设特征：%@",service.UUID,service.characteristics);
    
//    if ([self.centralDelegate respondsToSelector:@selector(hasDiscoverredService:andCharacter:)]) {
//        [self.centralDelegate hasDiscoverredService:service.UUID andCharacter:service.characteristics];
//    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        [peripheral readValueForCharacteristic:characteristic];
        
        // And check if it's the right one
//        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
//        {
//            // If it is, subscribe to it
//            [peripheral setNotifyValue:YES forCharacteristic:characteristic]; //A Boolean value indicating whether you wish to receive notifications or indications whenever the characteristic’s value changes  //不设置YES，就不会回调- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
//            self.theCharacteristic = characteristic;
//        }
    }
}

//收到外设数据时回调
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        //NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    if ([self.centralDelegate respondsToSelector:@selector(hasDiscoverredCharacteristic:)]) {
        [self.centralDelegate hasDiscoverredCharacteristic:characteristic];
    }
    
    //NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

    //Byte *testByte = (Byte *)[characteristic.value bytes];
    //NSLog(@"收到外设数据：service.uuid=%@,cha.value = %hhu,%@",characteristic.service.UUID,testByte[0],characteristic.value);
    
    if ([self.centralDelegate respondsToSelector:@selector(hasDiscoverredService:andCharacter:)]) {
        [self.centralDelegate hasDiscoverredService:characteristic.service.UUID andCharacter:characteristic];
    }

}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.connectedPeripheral = nil;
    
    if ([self.centralDelegate respondsToSelector:@selector(centralManagerHasDisconnectedPeripheral)]) {
        [self.centralDelegate centralManagerHasDisconnectedPeripheral];
    }
    
    // We're disconnected, so start scanning again
    [self scan];
}

//The peripheral letting us know whether our subscribe/unsubscribe happened or not
//如果一个特征的值被更新，然后周边代理接收-peripheral:didUpdateNotificationStateForCharacteristic:error:。你可以用-readValueForCharacteristic:读取新的值：
//[peripheral setNotifyValue:YES forCharacteristic:characteristic];的第一个布尔参数变化时回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //NSLog(@"didUpdateNSFC:%@",characteristic);

    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@. ", characteristic);
       // [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"发送数据到外设失败error：%@",error);
    } else {
        NSLog(@"发送数据给外设成功,外设：%@, 外设的特征：%@",peripheral,characteristic);
    }
    
}
@end






