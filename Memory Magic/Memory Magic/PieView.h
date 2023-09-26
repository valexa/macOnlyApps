//
//  PieView.h
//  PieChart
//
//  Created by Pavan Podila on 2/21/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//


@interface PieView : NSView

@property (nonatomic, strong) NSArray *sliceValues;

-(id)initWithSliceValues:(NSArray *)sliceValues;

@end

@interface NSColor (CGColorCompat)

- (CGColorRef)CGColorCompat;

@end


@interface NSBezierPath (BezierPathQuartzUtilities)

- (CGPathRef)quartzPath;

@end