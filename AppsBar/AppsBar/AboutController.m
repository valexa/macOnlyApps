//
//  AboutController.m
//  Files
//
//  Created by Vlad Alexa on 5/24/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "AboutController.h"

#import <ServiceManagement/ServiceManagement.h>

#define NSAppKitVersionNumber10_8 1187

@implementation AboutController

-(void)awakeFromNib
{
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self bundleIDExistsAsLoginItem:@"com.vladalexa.appsbarhelper"]) {
        [startToggle setTag:1];
        [startToggle setImage:[NSImage imageNamed:@"on"]];
    }else {
        [startToggle setTag:0];
        [startToggle setImage:[NSImage imageNamed:@"off"]];        
    } 
    
    /*
    if ([self AXTrusted] && [defaults boolForKey:@"shortcutEnabled"] == YES){
        [shortcutToggle setTag:1];
        [shortcutToggle setImage:[NSImage imageNamed:@"on"]];
    }else if (![self AXTrusted] && [defaults boolForKey:@"shortcutEnabled"] == YES){
        [shortcutToggle setHidden:YES];
        [shortcutText setHidden:NO];
    }else {
        [shortcutToggle setTag:0];
        [shortcutToggle setImage:[NSImage imageNamed:@"off"]];
    }
    */
    
    if ([defaults boolForKey:@"gestureEnabled"] == YES){
        [gestureToggle setTag:1];
        [gestureToggle setImage:[NSImage imageNamed:@"on"]];
    }else {
        [gestureToggle setTag:0];
        [gestureToggle setImage:[NSImage imageNamed:@"off"]];
    }
    
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_8) {
        NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
        if ([service canPerformWithItems:nil]) {
            [tweetButton setHidden:NO];
        }
    }

}

#pragma mark actions

-(IBAction)tweetPush:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"dismiss"];    
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    NSArray * shareItems = [NSArray arrayWithObjects:@"@VladAlexaApps 💭", nil];
    [service performWithItems:shareItems];    
}

/*
 
-(BOOL) AXTrusted
{
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @NO};
    Boolean isTrusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    if (isTrusted == TRUE) return YES;
    return NO;
}

-(void)delayedDismiss
{
    [shortcutToggle setHidden:NO];
    [shortcutText setHidden:YES];
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    [[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"dismiss"];
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Security.prefPane"];
}

- (IBAction) openAccessibility:(id)sender
{
	if ([sender tag] == 0)
    {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"shortcutEnabled"];
        [defaults synchronize];
        [shortcutToggle setTag:1];
        [shortcutToggle setImage:[NSImage imageNamed:@"on"]];
        
	}else if ([sender tag] == 1)
    {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"shortcutEnabled"];
        [defaults synchronize];
        [shortcutToggle setTag:0];
        [shortcutToggle setImage:[NSImage imageNamed:@"off"]];
	}
    
    if (![self AXTrusted]) {
        [shortcutToggle setHidden:YES];
        [shortcutText setHidden:NO];
        [self performSelector:@selector(delayedDismiss) withObject:nil afterDelay:6];
    }

}
 
*/

- (IBAction) openWebsite:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"dismiss"];
	NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/appsbar"];
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

-(IBAction) gestureToggle:(id)sender{
	if ([sender tag] == 0)
    {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"gestureEnabled"];
        [defaults synchronize];
        [gestureToggle setTag:1];
        [gestureToggle setImage:[NSImage imageNamed:@"on"]];
        
	}else if ([sender tag] == 1)
    {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"gestureEnabled"];
        [defaults synchronize];
        [gestureToggle setTag:0];
        [gestureToggle setImage:[NSImage imageNamed:@"off"]];
	}
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
	NSURL *theURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/AppsBar Helper.app"];
    NSString *theBID = @"com.vladalexa.appsbarhelper"; 
    
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
