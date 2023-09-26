//
//  TTScoreBoardAppDelegate.h
//  TTScoreBoard
//
//  Created by Vlad Alexa on 8/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "FSWindow.h"
#import "ToolBar.h"

@interface TTScoreBoardAppDelegate : NSObject <NSApplicationDelegate> {
    FSWindow *window;
    ToolBar *toolBar;    
}

@property (assign) IBOutlet FSWindow *window;

@end
