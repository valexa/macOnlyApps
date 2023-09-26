//
//  HeatSyncAppDelegate.h
//  HeatSync
//
//  Created by Vlad Alexa on 1/12/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainCore;

@interface HeatSyncAppDelegate : NSObject <NSApplicationDelegate> {
	MainCore *main;	
    NSWindow *window;
	NSUserDefaults *defaults;
}

@property (assign) IBOutlet NSWindow *window;

-(void) restartApp;
-(BOOL)showPrefPane:(BOOL)demand;

- (ProcessSerialNumber)numberToProcessSerialNumber:(NSNumber*)number;
- (NSDictionary *)copyInfoForPSN:(ProcessSerialNumberPtr const)psn;
- (BOOL)wasLaunchedByProcess:(NSString*)bundleid;
-(BOOL)appWasLaunched:(NSString*)bid;
	
@end
