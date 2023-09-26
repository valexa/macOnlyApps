//
//  FeedBoardAppDelegate.h
//  FeedBoard
//
//  Created by Vlad Alexa on 1/15/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FeedBoardAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

-(BOOL)wasLaunchedByProcess:(NSString*)bundleid;

@end
