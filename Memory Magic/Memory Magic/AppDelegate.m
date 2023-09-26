//
//  AppDelegate.m
//  Memory Magic
//
//  Created by Vlad Alexa on 11/1/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "AppDelegate.h"

#import <Carbon/Carbon.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    defaults = [NSUserDefaults standardUserDefaults];
    
	if ([[self getBIDOfParent] isEqualToString:@"com.apple.loginwindow"]){
        [self appInitRoutine:@"Login"];
    }else if ([[self getBIDOfParent] isEqualToString:@"com.apple.dt.Xcode"]) {
        [self appInitRoutine:@"Xcode"];
	}else {
        [self appInitRoutine:NSUserName()];        
	}
          
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    
	//NSLog(@"App will terminate");
    
    //clear badge so it does not remain in LaunchPad
    NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
    [tile setBadgeLabel:nil];
	
}

-(void)appInitRoutine:(NSString*)sender
{
    
    //sleep notifications
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(sleepNote:) name: NSWorkspaceWillSleepNotification object: NULL];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(wakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];
    
    NSString *msg = [NSString stringWithFormat:@"Memory Magic %@ (%@) loaded on OS X %@ by %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],[[NSProcessInfo processInfo] operatingSystemVersionString],sender];
    NSLog(@"%@",msg);

    
}


-(NSString*)getBIDOfParent
{
    ProcessSerialNumber myPSN;
    GetCurrentProcess(&myPSN);
    NSDictionary *myInfo = (NSDictionary*)CFBridgingRelease(ProcessInformationCopyDictionary(&myPSN,kProcessDictionaryIncludeAllInformationMask));
    ProcessSerialNumber parentPSN = { 0, [[myInfo objectForKey:@"ParentPSN"] intValue] };
    NSDictionary *parentInfo = (NSDictionary*)CFBridgingRelease(ProcessInformationCopyDictionary(&parentPSN,kProcessDictionaryIncludeAllInformationMask));
    NSString *ret = (NSString*)[parentInfo objectForKey:@"CFBundleIdentifier"];
    return ret;
}

#pragma mark sleep/wake

- (void) sleepNote: (NSNotification*) note
{

}

- (void) wakeNote: (NSNotification*) note
{
    [self restartSelf];
}

-(void) restartSelf
{
    //TODO, as to clean up opengl libraries, memory and stop monitoring
}

@end
