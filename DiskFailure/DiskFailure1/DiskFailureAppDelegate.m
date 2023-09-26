//
//  DiskFailureAppDelegate.m
//  DiskFailure
//
//  Created by Vlad Alexa on 1/15/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import "DiskFailureAppDelegate.h"
#import "DiskFailureMainCore.h"
#import "PreferencesController.h"
#import "MenuBar.h"
#import "ToolBar.h"
#import "VAValidation.h"

#define OBSERVER_NAME_STRING @"VADiskFailureEvent"
#define PLUGIN_NAME_STRING @"DiskFailure"

@implementation DiskFailureAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
    int v = [VAValidation v];		
    if (v != 0)  {		
        exit(v);
    }else {	
        //ok to run
        if ([self hasDiskFailure] == YES) {
            main = [[DiskFailureMainCore alloc] init];                    
        }else{        
            [[NSAlert alertWithMessageText:@"DiskFailure was not found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This application is only for customers with DiskFailure."] runModal];                
            ProcessSerialNumber psn = { 0, kCurrentProcess };
            TransformProcessType(&psn, kProcessTransformToForegroundApplication);            
            return;
        }         
    }      
    
    preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"PrefWindow"];
    
    toolBar = [[ToolBar alloc] init];
    [preferencesController.window setToolbar:toolBar.theBar];
    
    menuBar = [[MenuBar alloc] init];        
		
	defaults = [NSUserDefaults standardUserDefaults];	
    
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	        
	    
	if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"hideDock"] boolValue] == NO) {
		// display dock icon		
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
	}	  
    
    if ([[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"autoStart"] == nil){
        [self saveSetting:[NSNumber numberWithBool:NO] forKey:@"autoStart"];        
    } 
    
    if ([[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"hideDock"] == nil){
        [self saveSetting:[NSNumber numberWithBool:NO] forKey:@"hideDock"];        
    }    
    
}

-(BOOL)hasDiskFailure{
    
    NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.vladalexa.diskfailure"];
    
    if (url) {
        NSBundle *containerAppBundle = [NSBundle bundleWithURL:url];				   
        
        //check signature
        if ([VAValidation v:containerAppBundle] != 0)  {		
            //NSLog(@"Signature invalid for %@",url);
            return NO;
        }
        //check receipt
        if ([VAValidation a:containerAppBundle] != 0)  {		
            //NSLog(@"Receipt invalid for %@",url);
            return NO;
        }
    }else{
        //NSLog(@"Unable to find DiskFailure.");
        return NO;        
    }
    
	return YES;
}

-(void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
	[main release];	   
    [preferencesController release];
    [super dealloc];    
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
	if(!flag){
		[preferencesController.window makeKeyAndOrderFront:nil];
		[NSApp arrangeInFront:preferencesController.window];  
    }
	return YES;
}


-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doRestart"]){
			[self restartApp];
		}
		if ([[notif object] isEqualToString:@"doRefresh"]){
            [self showMsg:@"Refreshing, please wait."];
            [main doCheck:@"force"];            
            [self closeMsg:nil];            
		}        
		if ([[notif object] isEqualToString:@"AutostartON"]){
			[self setAutostart];
		}
		if ([[notif object] isEqualToString:@"AutostartOFF"]){
			[self removeAutostart];
		}	
		if ([[notif object] isEqualToString:@"showWindow"]){
            [preferencesController.window makeKeyAndOrderFront:nil];
			[NSApp arrangeInFront:preferencesController.window];            
		} 
		if ([[notif object] isEqualToString:@"showAbout"]){
            [self showAbout];
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
    }
}

-(void) restartApp{
	//ignores plist launch settings and freezes if launched from xcode
	NSString *fullPath = [[NSBundle mainBundle] executablePath];
	[NSTask launchedTaskWithLaunchPath:fullPath arguments:[NSArray arrayWithObjects:nil]];
	[NSApp terminate:self];
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

#pragma mark tools

- (void)setAutostart{
	UInt32 seedValue;
	CFURLRef thePath;
	CFURLRef currentPath = (CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);	
	if (loginItems) {
		//add it to startup list
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, currentPath, NULL, NULL);		
		if (item){
			NSLog(@"Added login item %@",CFURLGetString(currentPath));			
			CFRelease(item);		
		}else{
			NSLog(@"Failed to set to autostart from %@",CFURLGetString(currentPath));
		}
		//remove entries of same app with different paths	
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for (id item in loginItemsArray) {		
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			CFStringRef currentPathComponent = CFURLCopyLastPathComponent(currentPath);
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
				CFStringRef thePathComponent = CFURLCopyLastPathComponent(thePath);
				if (CFStringCompare(thePathComponent,currentPathComponent,0) == kCFCompareEqualTo
					&& CFStringCompare(CFURLGetString(thePath),CFURLGetString(currentPath),0) != kCFCompareEqualTo	){
					LSSharedFileListItemRemove(loginItems, itemRef);
					//NSLog(@"Deleting duplicate login item at %@",CFURLGetString(thePath));				
				}
				CFRelease(thePathComponent);
				CFRelease(thePath);				
			}else{
				CFStringRef displayNameComponent = LSSharedFileListItemCopyDisplayName(itemRef);				
				//also remove those with path that do not resolve
				if (CFStringCompare(displayNameComponent,currentPathComponent,0) == kCFCompareEqualTo) {
					LSSharedFileListItemRemove(loginItems, itemRef);	
					//NSLog(@"Deleting duplicate and broken login item %@",LSSharedFileListItemCopyDisplayName(itemRef));	
				}
				CFRelease(displayNameComponent);				
			}
			CFRelease(currentPathComponent);			
		}
		[loginItemsArray release];		
		CFRelease(loginItems);		
	}else{
		NSLog(@"Failed to get login items");
	}
}

- (void)removeAutostart{
	UInt32 seedValue;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);	
	if (loginItems) {
		//remove entries of same app	
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for (id item in loginItemsArray) {		
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			CFStringRef name = LSSharedFileListItemCopyDisplayName(itemRef);
			if (CFStringCompare(name,CFSTR("DiskFailure.app"),0) == kCFCompareEqualTo){
				LSSharedFileListItemRemove(loginItems, itemRef);
				NSLog(@"Deleted login item %@",name);				
			}
			//CFRelease(itemRef);	
			CFRelease(name);							
		}
		[loginItemsArray release];	
		CFRelease(loginItems);		
	}else{
		NSLog(@"Failed to get login items");
	}
}

#pragma mark about window stuff

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key { 
    if ([key isEqualToString: @"versionString"]) return YES; 
    return NO; 
} 

- (NSString *)versionString {
	NSString *sv = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];	
	return [NSString stringWithFormat:@"version %@ (%@)",sv,v];	
}

- (IBAction) openWebsite:(id)sender{
    [self closeMsg:sender];
	NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/diskfailure"];
	[[NSWorkspace sharedWorkspace] openURL:url];
	[[NSApp keyWindow] close];
}

- (void)showAbout{
	[NSApp beginSheet:aboutWindow modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

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

@end
