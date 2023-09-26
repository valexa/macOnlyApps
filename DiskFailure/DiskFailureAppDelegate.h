//
//  DiskFailureAppDelegate.h
//  DiskFailure
//
//  Created by Vlad Alexa on 1/15/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <Growl/Growl.h>

@class DiskFailureMainCore;

@interface DiskFailureAppDelegate : NSObject <NSApplicationDelegate,GrowlApplicationBridgeDelegate> {
@private
    NSUserDefaults *defaults;    
    IBOutlet DiskFailureMainCore *diskFailureMainCore;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSWindow *messageWindow;
    IBOutlet NSTextField *textMsg;
    IBOutlet NSProgressIndicator *progMsg;     
}

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;

-(void) growlNotif:(NSString*)title message:(NSString*)message;
-(NSDictionary *)registrationDictionaryForGrowl;

-(IBAction)doRefresh:(id)sender;

- (void)showMsg:(NSString *)msg;
-(IBAction)closeMsg:(id)sender;

@end
