//
//  AboutController.m
//  Files
//
//  Created by Vlad Alexa on 5/24/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "AboutController.h"

#import <ServiceManagement/ServiceManagement.h>

@implementation AboutController

-(void)awakeFromNib
{
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self bundleIDExistsAsLoginItem:@"com.vladalexa.memorymagichelper"]) {
        [startToggle setTag:1];
        [startToggle setImage:[NSImage imageNamed:@"on"]];
    }else {
        [startToggle setTag:0];
        [startToggle setImage:[NSImage imageNamed:@"off"]];        
    }
    
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8)
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    if ([service canPerformWithItems:nil]) {
        [tweetButton setHidden:NO];
    }
#endif
    
}

#pragma mark actions

-(IBAction)tweetPush:(id)sender
{
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    NSArray * shareItems = [NSArray arrayWithObjects:@"@VladAlexaApps 💭", nil];
    [service performWithItems:shareItems];
}

- (IBAction) openWebsite:(id)sender
{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
	NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/memorymagic"];
	[[NSWorkspace sharedWorkspace] openURL:url];
	[[NSApp keyWindow] close];
}

-(IBAction) startToggle:(id)sender{
	if ([sender tag] == 0)
    {
		[self setAutostart:YES];
        [startToggle setTag:1];
        [startToggle setImage:[NSImage imageNamed:@"on"]];
		//NSLog(@"autostart on");
        
	}else if ([sender tag] == 1)
    {
		[self setAutostart:NO];
        [startToggle setTag:0];
        [startToggle setImage:[NSImage imageNamed:@"off"]];
		//NSLog(@"autostart off");
	}	
}

-(IBAction)force:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PopoverEvent" object:@"force" userInfo:nil];
}

#pragma mark version

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key { 
    if ([key isEqualToString: @"versionString"]) return YES; 
    return NO; 
} 

- (NSString *)versionString {
	NSString *sv = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];	
	return [NSString stringWithFormat:@"version %@ (%@)",sv,v];	
}


#pragma mark autostart

- (void)setAutostart:(BOOL)set
{
	NSURL *theURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/Memory Magic Helper.app"];
    NSString *theBID = @"com.vladalexa.memorymagichelper"; 
    
    Boolean success = SMLoginItemSetEnabled((__bridge CFStringRef)theBID, set);
    if (!success) {
        NSLog(@"Failed to SMLoginItemSetEnabled %@ %@",[theURL path],theBID);       
    }   
}

- (BOOL) bundleIDExistsAsLoginItem:(NSString *)bundleID {
    
    NSArray * jobDicts = nil;
    jobDicts = (__bridge_transfer NSArray *)SMCopyAllJobDictionaries( kSMDomainUserLaunchd );
    // Note: Sandbox issue when using SMJobCopyDictionary()
    
    if ( (jobDicts != nil) && [jobDicts count] > 0 ) {
        
        BOOL bOnDemand = NO;        
        for ( NSDictionary * job in jobDicts ) {        
            if ( [bundleID isEqualToString:[job objectForKey:@"Label"]] ) {
                bOnDemand = [[job objectForKey:@"OnDemand"] boolValue];                
                break;
            } 
        }

        jobDicts = nil;
        return bOnDemand;
        
    } 
    return NO;
}

@end
