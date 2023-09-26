//
//  MenuBarIcon.h
//  Files
//
//  Created by Vlad Alexa on 5/23/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MenuBarIcon : NSView {

    BOOL mouseDown;
    NSRect imagerect;
    float pieSlice;
    float progress;
    BOOL inPogress;
}

@property     BOOL mouseDown;

+(unsigned long)APMAggressiveness;
+(BOOL)skipWorkBasedOnAPM;
+(int)cpuLoad;

@end
