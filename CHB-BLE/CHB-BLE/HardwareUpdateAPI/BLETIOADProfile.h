/*
 BLETIOADProfile.h
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#if !PURIFY_OTA_MODEL_CODE
#import "BLETIOADProgressDialog.h"
#import "BLETIOADProgressViewController.h"
#endif
#import "oad.h"
#import "BLEDevice.h"

#define HI_UINT16(a) (((a) >> 8) & 0xff)
#define LO_UINT16(a) ((a) & 0xff)

@interface BLETIOADProfile : NSObject <UIActionSheetDelegate,UIAlertViewDelegate>

@property (strong,nonatomic) NSData *imageFile;
#if !PURIFY_OTA_MODEL_CODE
@property (strong,nonatomic) BLETIOADProgressDialog *progressDialog;
#endif
@property (strong,nonatomic) BLEDevice *d;
#if !PURIFY_OTA_MODEL_CODE
@property (strong,nonatomic) UIView *view;
#endif

@property int nBlocks;
@property int nBytes;
@property int iBlocks;
@property int iBytes;
@property BOOL canceled;
@property BOOL inProgramming;
@property BOOL start;
@property (nonatomic,retain) NSTimer *imageDetectTimer;
@property uint16_t imgVersion;
@property uint16_t imgUid;


#if !PURIFY_OTA_MODEL_CODE
@property UINavigationController *navCtrl;

//In case of iOS 7.0
@property (strong,nonatomic) BLETIOADProgressViewController *progressView;
#endif

-(id) initWithDevice:(BLEDevice *) dev;
-(void) makeConfigurationForProfile;
-(void) configureProfile;
-(void) deconfigureProfile;
-(void) didUpdateValueForProfile:(CBCharacteristic *)characteristic;
-(void)deviceDisconnected:(CBPeripheral *)peripheral;

-(void) uploadImage:(NSString *)filename;

#if !PURIFY_OTA_MODEL_CODE
-(IBAction)selectImagePressed:(id)sender;
#endif
-(void) programmingTimerTick:(NSTimer *)timer;
-(void) imageDetectTimerTick:(NSTimer *)timer;

-(NSMutableArray *) findFWFiles;

-(BOOL) validateImage:(NSString *)filename;
-(BOOL) isCorrectImage;
-(void) completionDialog;

@end
