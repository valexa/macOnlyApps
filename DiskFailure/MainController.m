//
//  PreferencesController.m
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"
#import "DiskFailurePreferences.h"
#import "CloudController.h"

#import <ServiceManagement/ServiceManagement.h>

#include <pwd.h>
#include <grp.h>

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define PREF_OBSERVER_NAME_STRING @"MPPluginDiskFailurePreferencesEvent"
#else
    #define PREF_OBSERVER_NAME_STRING @"VADiskFailurePreferencesEvent"
#endif

#define PLUGIN_NAME_STRING @"DiskFailure"
#define MAIN_OBSERVER_NAME_STRING @"VADiskFailureEvent"

#define NSAppKitVersionNumber10_8 1187

@implementation MainController

- (void)dealloc
{
    [preferences release];
    [super dealloc];    
}

- (void)awakeFromNib
{   
    
    // Initialization code here.
    defaults = [NSUserDefaults standardUserDefaults];   
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    preferences = [[DiskFailurePreferences alloc] init];        
    if ([cloudController isiCloudAvailable]) [preferences.sharedDataPath setString:[[cloudController getiCloudURLFor:@"sharedData.plist" containerID:nil] path]]; 
    [prefView addSubview:preferences.view];    
        
    if ([[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] == nil) {
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(showAbout:) userInfo:nil repeats:NO];        //show info on first run         
    }
    
    if ([self bundleIDExistsAsLoginItem:@"com.vladalexa.diskfailurehelper"]) {
		[startToggle setSelectedSegment:1];
    }else {
		[startToggle setSelectedSegment:0];      
    }    
    
    NSString *frequency = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"checkFrequency"];   
    [timerProgress setDoubleValue:0.0];
    [timerProgress setMaxValue:[frequency doubleValue]];    
    [refreshLabel setStringValue:[self refreshTimeInterval:[timerProgress maxValue]]];    

    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerMove:) userInfo:nil repeats:YES]; 
    [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(timerReset:) userInfo:nil repeats:YES];
    
    if (![self isAdmin]) [adminLabel setHidden:NO];
    
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_8) {
        NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
        if ([service canPerformWithItems:nil]) {
            [tweetButton setHidden:NO];
        }
    }
    
}

#pragma mark core

-(void)saveSetting:(id)object forKey:(NSString*)key{   
    //this is the method for when the host application is not SytemPreferences (MagicPrefsPlugins or your standalone)    
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return;
	}       
    NSDictionary *prefs = [defaults objectForKey:PLUGIN_NAME_STRING];
    if ([prefs objectForKey:@"settings"] == nil) {
        NSMutableDictionary *d = [[prefs  mutableCopy] autorelease];
        [d setObject:[[[NSDictionary alloc] init] autorelease] forKey:@"settings"];
        prefs = d;
    }
    NSDictionary *db = [self editNestedDict:prefs setObject:object forKeyHierarchy:[NSArray arrayWithObjects:@"settings",key,nil]];
    [defaults setObject:db forKey:PLUGIN_NAME_STRING];        
    [defaults synchronize];
}

-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy{
    if (dict == nil) return dict;
    if (![dict isKindOfClass:[NSDictionary class]]) return dict;    
    NSMutableDictionary *parent = [[dict mutableCopy] autorelease];
    
    //drill down mutating each dict along the way
    NSMutableArray *structure = [NSMutableArray arrayWithCapacity:1];    
    NSMutableDictionary *prev = parent;
    for (id key in hierarchy) {
        if (key != [hierarchy lastObject]) {
            prev = [[[prev objectForKey:key] mutableCopy] autorelease];                            
            if (![prev isKindOfClass:[NSDictionary class]]) return dict;              
            [structure addObject:prev];
            //NSLog(@"loading %@",key); 
        }else{
            //NSLog(@"changing %@",key);
        }
    }   
    
    //do the change
    [[structure lastObject] setObject:object forKey:[hierarchy lastObject]];    
    
    //drill back up saving the changes each step along the way   
    for (int c = [structure count]-1; c >= 0; c--) {
        if (c == 0) {
            [parent setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }else{
            [[structure objectAtIndex:c-1] setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }
        //NSLog(@"saving %@",[hierarchy objectAtIndex:c]);        
    }
    
    return parent;
}

#pragma mark actions

-(IBAction)tweetPush:(id)sender
{
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    NSArray * shareItems = [NSArray arrayWithObjects:@"@VladAlexaApps 💭", nil];
    [service performWithItems:shareItems];
}

- (IBAction) openWebsite:(id)sender{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
	NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/diskfailure"];
	[[NSWorkspace sharedWorkspace] openURL:url];
	[[NSApp keyWindow] close];
}

-(IBAction) showAbout:(id)sender{
	[NSApp beginSheet:aboutWindow modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction) startToggle:(id)sender{
	if ([sender selectedSegment] == 1){
		[self setAutostart:YES];
		//NSLog(@"autostart on");
	}else {
		[self setAutostart:NO];
		//NSLog(@"autostart off");
	}	
}

-(void)restartDialog{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Application relaunch required" defaultButton:@"Ok quit the app" alternateButton:nil otherButton:nil informativeTextWithFormat:@"A relaunch of the application is required for the setting to take effect."];
    [alert beginSheetModalForWindow:self.window modalDelegate:NSApp didEndSelector:@selector(terminate:) contextInfo:nil]; 
}

-(IBAction)changeMachines:(id)sender
{
	if ([sender selectedSegment] == 0){
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"switchToThis"];  
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LogsController" object:@"switchToThis"];          
    } else {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"switchToAll"];    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LogsController" object:@"switchToAll"];              
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
	NSURL *theURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/diskfailurehelper.app"];    
    NSString *theBID = @"com.vladalexa.diskfailurehelper"; 
    
    Boolean success = SMLoginItemSetEnabled((CFStringRef)theBID, set);
    if (!success) {
        NSLog(@"Failed to SMLoginItemSetEnabled %@ %@",[theURL path],theBID);       
    }   
}

- (BOOL) bundleIDExistsAsLoginItem:(NSString *)bundleID {
    
    BOOL bOnDemand = NO;    
    NSArray * jobDicts = nil;
    jobDicts = (NSArray *)SMCopyAllJobDictionaries( kSMDomainUserLaunchd );
    // Note: Sandbox issue when using SMJobCopyDictionary()
    
    if ( [jobDicts count] > 0 ) {
        
        for ( NSDictionary * job in jobDicts ) {
            
            if ( [bundleID isEqualToString:[job objectForKey:@"Label"]] ) {
                bOnDemand = [[job objectForKey:@"OnDemand"] boolValue];
                break;
            }
        }        
    }
    
    if (jobDicts != nil) {
        CFRelease((CFDictionaryRef)jobDicts);
        jobDicts = nil;
    }
    
    return bOnDemand;
}

#pragma mark timer

- (void)timerMove:(NSTimer*)theTimer{    
    float notch = 1.0;
    [timerProgress setDoubleValue:[timerProgress doubleValue]+notch];        
    [refreshLabel setStringValue:[self refreshTimeInterval:[timerProgress maxValue]-([timerProgress doubleValue]/notch)]];    
}

- (void)timerReset:(NSTimer*)theTimer{
    [timerProgress setDoubleValue:0.0];        
}

-(NSString*)refreshTimeInterval:(double)time{
	NSString *ret = @"";
	
	if (time > 60) {
        int minutes = (int)time/60;
		ret = [NSString stringWithFormat:@"refresh in %i:%i",minutes,(int)time-(minutes*60)];	
	}else if (time > 0){
		ret = [NSString stringWithFormat:@"refresh in %is",(int)time];	        
    }else{
		ret = @"refreshing";	                
    }
	return ret;
}

#pragma mark tools

-(BOOL)isAdmin
{
    uid_t current_user_id = getuid();    
    struct passwd *pwentry = getpwuid(current_user_id);   
    struct group *admin_group = getgrnam("admin");
    while(*admin_group->gr_mem != NULL) {
        if (strcmp(pwentry->pw_name, *admin_group->gr_mem) == 0) {
            return YES;
        }
        admin_group->gr_mem++;
    }
    return NO;
}

@end
