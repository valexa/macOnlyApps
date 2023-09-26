//
//  AppDelegate.h
//  DiskSMART
//
//  Created by Vlad Alexa on 1/27/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PopoverController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTableViewDataSource> {
    NSMutableArray          *theList;
	IBOutlet NSTableView	*theTable;    
    IBOutlet NSPopover      *thePop;
    IBOutlet PopoverController *theController;
}

@property (assign) IBOutlet NSWindow *window;

-(void)getSmartDrives;
-(void)getAllDrives;

-(BOOL)hasDiskFailure;

- (NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device;
-(BOOL)isSmartCapable:(io_service_t)device;

@end
