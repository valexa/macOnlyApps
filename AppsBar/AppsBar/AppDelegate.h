//
//  AppDelegate.h
//  AppsBar
//
//  Created by Vlad Alexa on 1/23/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {

    NSStatusItem *statusItem;
	NSWindow *magicLauncher;
	NSUserDefaults *defaults;
    BOOL active;
    BOOL startedDrag;
    BOOL excluded;
    IBOutlet NSPopover *popOver;
    IBOutlet NSView *backView;
    IBOutlet NSMatrix *excludedPicker;
    IBOutlet NSView *centerButtons;
    IBOutlet NSView *toggleButtons;
    IBOutlet NSButton *twitterButton;
    NSScrollView *backScrollView;
    NSScrollView *frontScrollView;
    NSView *backRootView;
    NSView *frontRootView;
    IBOutlet NSPopover *iconPopOver;
    IBOutlet NSTextField *appTitle;
    IBOutlet NSTextField *appBid;
    IBOutlet NSTextField *appPath;
}

@property (assign) IBOutlet NSWindow *window;

-(IBAction)showApps:(id)sender;
-(IBAction)backFlip:(id)sender;
-(IBAction)frontFlip:(id)sender;
-(IBAction)showExcluded:(id)sender;

@end
