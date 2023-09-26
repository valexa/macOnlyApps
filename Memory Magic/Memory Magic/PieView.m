//
//  PieView.m
//  PieChart
//
//  Created by Pavan Podila on 2/21/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import "PieView.h"
#import "PieSliceLayer.h"
#import <QuartzCore/QuartzCore.h>

#define DEG2RAD(angle) angle*M_PI/180.0


@interface PieView() {
	CALayer *_containerLayer;
}

-(void)updateSlices;
@end

@implementation PieView
@synthesize sliceValues = _sliceValues;

-(void)doInitialSetup {
    [self setWantsLayer:YES];//important
	_containerLayer = [CALayer layer];
	[self.layer addSublayer:_containerLayer];
    

	CAShapeLayer *circleLayer = [CAShapeLayer layer];
    
	CGPoint offset = CGPointMake((self.bounds.size.width-195.0)/2, (self.bounds.size.height-195.0)/2);
    NSBezierPath *piePath = [NSBezierPath bezierPath];
    [piePath appendBezierPathWithOvalInRect:CGRectMake(offset.x, offset.y, 195.0, 195.0)];
    
	circleLayer.path = [piePath quartzPath];
	circleLayer.fillColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.1].CGColorCompat;
    
	[self.layer addSublayer:circleLayer];
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self doInitialSetup];
    }
	
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self doInitialSetup];
	}
	
	return self;
}

-(id)initWithSliceValues:(NSArray *)sliceValues {
	if (self) {
		[self doInitialSetup];
		self.sliceValues = sliceValues;
	}
	
	return self;
}

-(void)setSliceValues:(NSArray *)sliceValues {
	_sliceValues = sliceValues;

	[self updateSlices];
}


-(void)removeLayers
{
    NSUInteger count = _containerLayer.sublayers.count;
    
    for (int i = 0; i < count; i++) {
        [[_containerLayer.sublayers objectAtIndex:0] removeFromSuperlayer];
    }
}

-(void)updateSlices {

    if ([[_containerLayer sublayers] count] < [_sliceValues count])
    {
        for (NSNumber *num in _sliceValues)
        {
            PieSliceLayer *slice = [PieSliceLayer layer];
            slice.frame = self.bounds;
            [slice setContentsScale:[self pixelScaling]];
            [_containerLayer addSublayer:slice];              
        }
    }
    else if  ([[_containerLayer sublayers] count] > [_sliceValues count])
    {
		NSUInteger count = _containerLayer.sublayers.count - _sliceValues.count;
        
		for (int i = 0; i < count; i++) {
			[[_containerLayer.sublayers objectAtIndex:0] removeFromSuperlayer];
		}
    }

	_containerLayer.frame = self.bounds;
    
	CGFloat endAngle = DEG2RAD(90.0);
	int index = 0;
    
    NSArray *colors = [NSArray arrayWithObjects:
                       [NSColor colorWithCalibratedRed:0.83 green:0.32 blue:0.09 alpha:1.0],
                       [NSColor colorWithCalibratedRed:0.92 green:0.54 blue:0.2 alpha:1.0],
                       [NSColor lightGrayColor],
                       LGRAY_COLOR,
                       nil];
    
    NSArray *colorsSteve = [NSArray arrayWithObjects:
                       [NSColor blackColor],
                       [NSColor darkGrayColor],
                       [NSColor lightGrayColor],
                       LGRAY_COLOR,
                       nil];
    
    NSArray *colorsUSA = [NSArray arrayWithObjects:
                            [NSColor blueColor],
                            [NSColor redColor],
                            [NSColor lightGrayColor],
                            LGRAY_COLOR,
                            nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"d MMM"];
    if ([[dateFormatter stringFromDate:[NSDate date]] isEqualToString:@"4 Jul"]) colors = colorsUSA;
    if ([[dateFormatter stringFromDate:[NSDate date]] isEqualToString:@"22 Nov"]) colors = colorsUSA;
    if ([[dateFormatter stringFromDate:[NSDate date]] isEqualToString:@"5 Oct"]) colors = colorsSteve;
    
	for (NSNumber *num in _sliceValues)
    {
		PieSliceLayer *slice = [_containerLayer.sublayers objectAtIndex:index];
        
		CGFloat angle = num.floatValue * 2 * M_PI;
        slice.startAngle = endAngle - angle;
        slice.endAngle = endAngle;
       
        endAngle -= angle;
        
        slice.fillColor = [colors objectAtIndex:index];
        slice.strokeWidth = 0;

        index++;
    }
	
}


-(CGFloat)pixelScaling
{
    NSRect pixelBounds = [self convertRectToBacking:self.bounds];
    return pixelBounds.size.width/self.bounds.size.width;
}

@end

@implementation NSColor (CGColorCompat)

- (CGColorRef)CGColorCompat
{

    if( [self respondsToSelector:@selector(CGColor)])
    {
        return [self CGColor]; //10.8+
    }else{
        const NSInteger numberOfComponents = [self numberOfComponents];
        CGFloat components[numberOfComponents];
        [self getComponents:(CGFloat *)&components];
        
        return CGColorCreate([[self colorSpace] CGColorSpace], components);
        //we leak it on 10.7//TODO
    }
}

@end

@implementation NSBezierPath (BezierPathQuartzUtilities)
// This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath
{
    NSInteger i, numElements;
    
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [self elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        
        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}
@end
