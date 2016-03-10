//
//  BLEConnectingView.m
//  CHB-BLE
//
//  Created by baoshengfeng on 15/10/22.
//  Copyright (c) 2015年 baoshengfeng. All rights reserved.
//

#import "BLEConnectingView.h"

@implementation BLEConnectingView

-(void)didMoveToSuperview
{
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activity.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);

    dispatch_async(dispatch_get_main_queue(), ^{
        [activity startAnimating];
        [self addSubview:activity];
    });
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
