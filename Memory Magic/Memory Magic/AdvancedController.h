//
//  AdvancedController.h
//  Memory Magic
//
//  Created by Vlad Alexa on 12/18/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MMMonitor.h"

@interface AdvancedController : NSViewController
{
    
    MMMonitor *monitor;
    
    NSMutableArray *swapStat;
    
    NSMutableArray *recoveryStat;
    
    NSUserDefaults *defaults;
    
    NSTimer *swapTimer;
    
    NSTimer *recoveryTimer;
    
    IBOutlet NSImageView *topView;
    IBOutlet NSImageView *bottomView;
}

-(IBAction)showTopHelp:(id)sender;
-(IBAction)showBottomHelp:(id)sender;

@end
