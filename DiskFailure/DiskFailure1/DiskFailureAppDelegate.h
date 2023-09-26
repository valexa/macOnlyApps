//
//  DiskFailureAppDelegate.h
//  DiskFailure
//
//  Created by Vlad Alexa on 1/15/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DiskFailureMainCore;
@class PreferencesController;
@class ToolBar;
@class MenuBar;

@interface DiskFailureAppDelegate : NSObject <NSApplicationDelegate> {
@private
    DiskFailureMainCore *main;
    NSUserDefaults *defaults;
    PreferencesController *preferencesController;
    ToolBar *toolBar;
    MenuBar *menuBar;
    
	IBOutlet NSWindow *aboutWindow; 
    IBOutlet NSWindow *messageWindow;
    IBOutlet NSTextField *textMsg;
    IBOutlet NSProgressIndicator *progMsg;     
}


-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;

-(BOOL)hasDiskFailure;

- (void) restartApp;
- (void)setAutostart;
- (void)removeAutostart;

- (IBAction) openWebsite:(id)sender;

- (void)showAbout;
- (void)showMsg:(NSString *)msg;
-(IBAction)closeMsg:(id)sender;

@end
