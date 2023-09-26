//
//  NSMonitorAppDelegate.h
//  NSMonitor
//
//  Created by Vlad Alexa on 1/7/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CarbonCore/FSEvents.h>

//@class CGEventsController;
@class TableController;

@interface NSMonitorAppDelegate : NSObject <NSApplicationDelegate,NSNetServiceBrowserDelegate> {
    
    IBOutlet TableController *cGEventsController;
    IBOutlet TableController *ioregistryController;    
    
    IBOutlet TableController *fseventsController;    
    IBOutlet TableController *distributedController;
    IBOutlet TableController *workspaceController;        
    
    IBOutlet TableController *networkController;
    IBOutlet TableController *socketsController;    
    IBOutlet TableController *filesController; 
    
    IBOutlet NSWindow *windowCreateNotif;
    
   	NSWindow *window;
    NSUserDefaults *defaults;  
    NSSound *breatheSound;  
    BOOL doBreath;
	IBOutlet NSTabView *theTab;
	
	IBOutlet NSButton *statusLed;	
	NSTimer *statusTimer;
    IBOutlet NSPopover *statusPopover;
    
    NSMutableArray *lastLsof;
    
    IONotificationPortRef gNotifyPort;
    io_iterator_t publishIter;
    io_iterator_t terminateIter;
    
}

@property (strong) IBOutlet NSWindow *window;

-(void)lsofLoop;

-(void)onREGevent:(io_iterator_t)iterator action:(NSString*)action;
-(void)onCGevent:(CGEventRef)event;
-(void)onFSevent:(NSArray *)paths;

- (void)tapcheck;
- (NSDictionary *)getTaps;
- (NSDictionary *)infoForPID:(pid_t)pid;

-(void)blinkStatus:(NSString*)color;

-(IBAction)statusPopover:(id)sender;

-(IBAction)ONOFFCheck:(id)sender;

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args;

-(BOOL) tabPaused:(int)index name:(NSString*)name setting:(NSString*)setting;


-(IBAction)createNotification:(id)sender;
-(IBAction)createNotificationCancel:(id)sender;

@end
