//
//  PopoverController.h
//  Memory Magic
//
//  Created by Vlad Alexa on 11/1/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PieView.h"

@interface PopoverController : NSViewController{
    
    NSUserDefaults *defaults;

    IBOutlet NSPopover *popOver;
    IBOutlet NSPopover *popOverBack;
    
    IBOutlet NSImageView *progressView;
    IBOutlet NSImageView *menuView;
    IBOutlet PieView *pieView;
    
    IBOutlet NSImageView *leftView;
    IBOutlet NSImageView *rightView;

    IBOutlet NSView *slideView;
    NSMutableArray *memoryStat;
    NSMutableDictionary *memoryStatBeforeRun;
    
    IBOutlet NSTextField *leftLabel;
    IBOutlet NSTextField *rightLabel;
    BOOL alternateLeft;
    BOOL alternateRight;
    
    IBOutlet NSTextField *pieMiddleLabel;
    IBOutlet NSTextField *pieSmallLabel;
    
    IBOutlet NSTextField *swipeLabel;
    
    BOOL tick;
    BOOL inProgress;
    NSTimer *tenSecTimer;
}

@property  BOOL waitAfterAppQuit;

-(IBAction)alternateLeft:(id)sender;
-(IBAction)alternateRight:(id)sender;
-(IBAction)showHelp:(id)sender;

@end
