//
//  AppDelegate.h
//  OSXCommander
//
//  Created by Vlad Alexa on 11/5/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PaneController.h"
#import "ToolbarController.h"

//#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface AppDelegate : NSObject
//#else
//@interface AppDelegate : NSObject <NSApplicationDelegate> 
//#endif
{
	NSDate *startedAt;	
	PaneController *left;
	PaneController *right;	
	IBOutlet NSSplitView *splitView;	
	IBOutlet NSView *leftPane;
	IBOutlet NSView *rightPane;
	IBOutlet NSComboBox *console;
	IBOutlet NSWindow *window;	
}

@property (nonatomic, retain) NSDate *startedAt;
@property (nonatomic, assign) PaneController *left;
@property (nonatomic, assign) PaneController *right;	
@property (nonatomic, assign) IBOutlet NSSplitView *splitView;
@property (nonatomic, assign) IBOutlet NSView *leftPane;
@property (nonatomic, assign) IBOutlet NSView *rightPane;
@property (nonatomic, assign) IBOutlet NSWindow *window;

- (IBAction)startAnimations:(id)sender;

@end
