//
//  FeedBoardAppDelegate.m
//  FeedBoard
//
//  Created by Vlad Alexa on 1/15/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import "FeedBoardAppDelegate.h"
#import "VAValidation.h"
#import "FeedBoardMainWindow.h"

@implementation FeedBoardAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	int v = [VAValidation v];		
	int a = [VAValidation a];
	if (v+a != 0)  {		
		exit(v+a);
	}else {	
		//aloc FeedBoardMainWindow
		NSRect screen = [[NSScreen mainScreen] frame];
		window = [[FeedBoardMainWindow alloc] initWithContentRect:NSMakeRect(-10,-10,screen.size.width+20,screen.size.height+20) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	}		
	
	if ([self wasLaunchedByProcess:@"com.apple.loginwindow"] == NO){
		//show on launch if not started by login
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAFeedBoardEvent" object:@"readGoogle"];	
	}	
    
	[NSTimer scheduledTimerWithTimeInterval:1800 target:self selector:@selector(refreshTimer:) userInfo:nil repeats:YES];    
	
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
    NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
    [tile setBadgeLabel:nil];    
	if(!flag)[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAFeedBoardEvent" object:@"readGoogle"];	
	return YES;
}

-(void)dealloc{
	[window release];	
	[super dealloc];
}

-(void)refreshTimer:(NSTimer*)timer{
    if (![window isMainWindow]) {       
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAFeedBoardEvent" object:@"refreshGoogle"];            
    }
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


@end
