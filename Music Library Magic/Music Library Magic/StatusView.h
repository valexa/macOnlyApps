//
//  StatusView.h
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/1/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusView : NSView{
    IBOutlet NSImageView *bgView;
}

@end


@interface NSBezierPath (BezierPathQuartzUtilities)

- (CGPathRef)quartzPath;

@end