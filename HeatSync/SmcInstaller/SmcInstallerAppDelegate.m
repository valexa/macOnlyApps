//
//  SmcInstallerAppDelegate.m
//  SmcInstaller
//
//  Created by Vlad Alexa on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SmcInstallerAppDelegate.h"
#import "smcWrapper.h"

@implementation SmcInstallerAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [smcWrapper setupHelper];
    
    [NSApp terminate:self];    
}

@end
