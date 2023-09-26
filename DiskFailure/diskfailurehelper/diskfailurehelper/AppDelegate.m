//
//  AppDelegate.m
//  diskfailurehelper
//
//  Created by Vlad Alexa on 5/8/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    /*
    NSString *fullPath = [[NSBundle mainBundle] bundlePath];
    NSString *tail = [NSString stringWithFormat:@"/Contents/Library/LoginItems/%@",[fullPath lastPathComponent]];
    NSString *appPath = [fullPath stringByReplacingOccurrencesOfString:tail withString:@""];        
    NSURL *url = [NSURL fileURLWithPath:appPath];    
    NSError *err = nil;
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url options:NSWorkspaceLaunchDefault configuration:nil error:&err];    
    if (err){	
        NSLog(@"Failed to launch %@ : %@",appPath,err);
    }
    */
    
    NSArray *identifiers;
    [[NSWorkspace sharedWorkspace] openURLs:nil withAppBundleIdentifier:@"com.vladalexa.diskfailure" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifiers:&identifiers];        
    
    //[[NSWorkspace sharedWorkspace] launchApplication:@"DiskFailure"];
    [NSApp terminate:self];
}

@end
