//
//  HeatSyncAppDelegate.m
//  HeatSync
//
//  Created by Vlad Alexa on 1/12/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import "HeatSyncAppDelegate.h"
#import "MainCore.h"
#import "smcWrapper.h"

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
	#define PREF_OBSERVER_NAME_STRING @"MPPluginHeatSyncPreferencesEvent"
#else
	#define PREF_OBSERVER_NAME_STRING @"VAHeatSyncPreferencesEvent"
#endif

#define OBSERVER_NAME_STRING @"VAHeatSyncEvent"

@implementation HeatSyncAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	    
    [smcWrapper setupHelper];     
		
	defaults = [NSUserDefaults standardUserDefaults];	
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	
  
	if ([[[[defaults objectForKey:@"HeatSync"] objectForKey:@"settings"] objectForKey:@"hideDock"] boolValue] == NO) {
		// display dock icon		
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
	}	    
    
    if ([self wasLaunchedByProcess:@"com.apple.loginwindow"] == NO){
        //show on launch if not started by login
        [self showPrefPane:YES];        
    }else{
        //only show if we have to copy it otherwise
        [self showPrefPane:NO];        
    }    
    
    
    main = [[MainCore alloc] init];    
	
}

-(void)dealloc{
	[super dealloc];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];		
	[main release];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
	if(!flag){
        [self showPrefPane:YES];
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
		if ([[notif object] isEqualToString:@"copyHelper"]){
            //copy it if it does not exist or if md5 does not match	
            NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"smc" ofType:@""];
            [smcWrapper installAndCheckHelper:bundlePath];
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"syncUI" userInfo:nil];				
		}
		if ([[notif object] isEqualToString:@"removeHelper"]){
			[smcWrapper removeHelper];
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"syncUI" userInfo:nil];				
		}		
	}
}

-(void) restartApp{
	//ignores plist launch settings and freezes if launched from xcode
	NSString *fullPath = [[NSBundle mainBundle] executablePath];
	[NSTask launchedTaskWithLaunchPath:fullPath arguments:[NSArray arrayWithObjects:nil]];
	[NSApp terminate:self];
}

-(BOOL)showPrefPane:(BOOL)demand{
    //open pref pane, from disk if found and not old, from bundle otherwise to trigger copy
    NSString *bundledPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"HeatSync.prefPane"];    
	NSString *allUsersPath = @"/Library/PreferencePanes/HeatSync.prefPane"; 
	NSString *userPath = [NSString stringWithFormat:@"%@/Library/PreferencePanes/HeatSync.prefPane",NSHomeDirectory()];    
    NSString *path = nil;
    BOOL opened;
	if ([[NSFileManager defaultManager] fileExistsAtPath:allUsersPath] == YES) {
        path = allUsersPath;
    }     
	if ([[NSFileManager defaultManager] fileExistsAtPath:userPath] == YES) {
        path = userPath;
    }     
    if (path) { //osx loads the user one is both present so we do the same        
        NSString *bundledVersion = [[NSBundle bundleWithPath:bundledPath] objectForInfoDictionaryKey:@"CFBundleVersion"];        
        NSString *foundVersion = [[NSBundle bundleWithPath:path] objectForInfoDictionaryKey:@"CFBundleVersion"];        
        if (![bundledVersion isEqualToString:foundVersion]) {	            
            //open from bunddle to trigger copy as it is old version            
            if ([self appWasLaunched:@"com.apple.systempreferences"]){
                system("killall 'System Preferences'");	
                sleep(1);
            }            
            opened = [[NSWorkspace sharedWorkspace] openFile:bundledPath];	            
        }else{
            if (demand == YES){
                opened = [[NSWorkspace sharedWorkspace] openFile:path];                
            }	             
        }        
    }else{
        //open from bunddle to trigger copy as it is not installed yet
        opened = [[NSWorkspace sharedWorkspace] openFile:bundledPath];       
    }      
	
	if (opened == YES) {
		return YES;		
	}else {					
		NSLog(@"Failed to open the preferences pane %@.",path);		
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Unable to open the preferences pane"];
		[alert setInformativeText:@"Please contact the developer with information about how this happened."];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];	
	}	
	return NO;
}


#pragma mark process

- (ProcessSerialNumber)numberToProcessSerialNumber:(NSNumber*)number {
	// There is a bug in Tiger where they were packing ProcessSerialNumbers
	// incorrectly into the longlong that they stored in the dictionary.
	// This fixes it.
	ProcessSerialNumber outPSN = { kNoProcess, kNoProcess};
	if (number) {
		long long temp = [number longLongValue];
		UInt32 hi = (UInt32)((temp >> 32) & 0x00000000FFFFFFFFLL);
		UInt32 lo = (UInt32)((temp >> 0) & 0x00000000FFFFFFFFLL);
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
		outPSN.highLongOfPSN = hi;
		outPSN.lowLongOfPSN = lo;
#else  // MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		if ([GTMSystemVersion isLeopardOrGreater]) {
			outPSN.highLongOfPSN = hi;
			outPSN.lowLongOfPSN = lo;
		} else {
#if TARGET_RT_BIG_ENDIAN
			outPSN.highLongOfPSN = hi;
			outPSN.lowLongOfPSN = lo;
#else
			outPSN.highLongOfPSN = lo;
			outPSN.lowLongOfPSN = hi;
#endif  // TARGET_RT_BIG_ENDIAN
		}
#endif  // MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	}
	return outPSN;
}

- (NSDictionary *)copyInfoForPSN:(ProcessSerialNumberPtr const)psn {
	NSDictionary *dict = nil;
	if (psn) {
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(psn,kProcessDictionaryIncludeAllInformationMask);
		dict = (NSDictionary *)cfDict;
	}
	return dict;
}

- (BOOL)wasLaunchedByProcess:(NSString*)bundleid {
	BOOL ret = NO;
	NSDictionary *processInfo = nil;
	ProcessSerialNumber selfNumber;
	if (MacGetCurrentProcess(&selfNumber) == noErr) {
		processInfo = [self copyInfoForPSN:&selfNumber];
	}	
	if (processInfo) {
		NSNumber *processNumber	= [processInfo objectForKey:@"ParentPSN"];
		ProcessSerialNumber parentPSN = [self numberToProcessSerialNumber:processNumber];
		NSDictionary *parentProcessInfo	= [self copyInfoForPSN:&parentPSN];
		NSString *parentBundle = [parentProcessInfo objectForKey:(NSString *)kCFBundleIdentifierKey];
		ret = [parentBundle isEqualToString:bundleid];	
		[parentProcessInfo release];		
		[processInfo release];
	}
	return ret;
}

-(BOOL)appWasLaunched:(NSString*)bid{
	for (id dict in [[NSWorkspace sharedWorkspace] launchedApplications]){
		if ([bid isEqualToString:[dict objectForKey:@"NSApplicationBundleIdentifier"]]) {
			//NSLog(@"%@ running",bid);
			return YES;
		}
	}	
	//NSLog(@"%@ not running",bid);
	return NO;
}

@end
