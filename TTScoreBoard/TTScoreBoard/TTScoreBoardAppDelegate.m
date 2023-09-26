//
//  TTScoreBoardAppDelegate.m
//  TTScoreBoard
//
//  Created by Vlad Alexa on 8/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TTScoreBoardAppDelegate.h"
#import "VAValidation.h"

@implementation TTScoreBoardAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    

	int v = [VAValidation v];		
	int a = [VAValidation a];
	if (v+a != 0)  {		
		exit(v+a);
	}else {	
		//ok to run
	}     

    toolBar = [[ToolBar alloc] init];
    [window setToolbar:toolBar.theBar]; 
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}

- (void)dealloc {
    [toolBar dealloc];
    [super dealloc];
}

@end