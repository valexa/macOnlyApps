//
//  LaunchButton.h
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/14/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LaunchButton : NSButton {

	BOOL editing;
    BOOL holding;
    BOOL cursorIsInside;
    BOOL appActive;
	NSButton *deleteButton;
	NSTrackingArea *trackingArea;
}

-(void)animateBlink:(NSView*)theView;

@end
