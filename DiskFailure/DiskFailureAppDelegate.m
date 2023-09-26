//
//  DiskFailureAppDelegate.m
//  DiskFailure
//
//  Created by Vlad Alexa on 1/15/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import "DiskFailureAppDelegate.h"
#import "DiskFailureMainCore.h"
#import "VASandboxFileAccess.h"

#define OBSERVER_NAME_STRING @"VADiskFailureEvent"
#define PLUGIN_NAME_STRING @"DiskFailure"

@implementation DiskFailureAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
    
#if (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_8)
    //growl init, leaks NSMallocBlock
    NSBundle *myBundle = [NSBundle mainBundle];
    NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
    NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
    if (growlBundle && [growlBundle load]) {
        // Register ourselves as a Growl delegate
        [GrowlApplicationBridge setGrowlDelegate:self];
        NSLog(@"Loaded Growl.framework");
    } else {
        NSLog(@"Could not load Growl.framework");
    }
#endif    
    		
	defaults = [NSUserDefaults standardUserDefaults];	
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	        
	        
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];     
    [super dealloc];    
}

- (void) application:(NSApplication *)app willEncodeRestorableState:(NSCoder *)coder
{
    [VASandboxFileAccess willEncodeRestorableState:coder];    
}

- (void) application:(NSApplication *)app didDecodeRestorableState:(NSCoder *)coder
{
    [VASandboxFileAccess didDecodeRestorableState:coder];       
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
	if(!flag){
		[mainWindow makeKeyAndOrderFront:nil];
		[NSApp arrangeInFront:mainWindow];  
    }else {
        NSWindow *window = [NSApp keyWindow];
        if (window != nil && window.title == nil) {
            [window close];
            [window orderOut:self];
            NSLog(@"Closed nil title window");
            [mainWindow makeKeyAndOrderFront:nil];
            [NSApp arrangeInFront:mainWindow];  
        }
    }   
	return YES;
}

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doRefresh"]){
            [self doRefresh:self];    
		}        	
		if ([[notif object] isEqualToString:@"showWindow"]){
            if ([mainWindow isMainWindow]) {
                [mainWindow close];
            }else{
                [mainWindow makeKeyAndOrderFront:nil];
                [NSApp arrangeInFront:mainWindow];
            }
		}         
		if ([[notif object] isEqualToString:@"dismissModal"]){
            [self closeMsg:nil];
		}         
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"showModal"]){
            if ([[NSApp mainWindow] isKeyWindow] == YES) { //only do it if we are active
                [self showMsg:[[notif userInfo] objectForKey:@"text"]];                
            }
		}
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"doGrowl"]){	
			NSString *title = [[notif userInfo] objectForKey:@"title"];
			NSString *message = [[notif userInfo] objectForKey:@"message"];			
			[self growlNotif:title message:message];
		}	    
    }
}

-(void) growlNotif:(NSString*)title message:(NSString*)message{
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    if (notif) {
        [notif setTitle:title];
        [notif setInformativeText:message];
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:notif];
        [notif release];
    }else {
        [GrowlApplicationBridge notifyWithTitle:title description:message notificationName:@"DiskFailureGrowlNotif" iconData:nil priority:1 isSticky:NO clickContext:nil]; 	        
    }
}

-(NSDictionary *)registrationDictionaryForGrowl{
    NSArray *notifications = [NSArray arrayWithObject:@"DiskFailureGrowlNotif"];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          notifications, GROWL_NOTIFICATIONS_ALL,
                          notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];    
    return (dict);
}

-(IBAction)doRefresh:(id)sender
{
    [self showMsg:@"Refreshing, please wait."];            
    [diskFailureMainCore doCheck:@"force"];            
    [self closeMsg:nil];
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


#pragma mark sheets

- (void)showMsg:(NSString *)msg{
	[textMsg setStringValue:msg];
	[NSApp beginSheet:messageWindow modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[progMsg setUsesThreadedAnimation:YES];	
	[progMsg startAnimation:nil];
}

-(IBAction)closeMsg:(id)sender{
    if (sender == nil) sender = textMsg;
	[NSApp endSheet:[sender window]];
	//[[sender window] close];
	[[sender window] orderOut:self];	
    [progMsg stopAnimation:nil];
}

#pragma mark plugin sync




@end
