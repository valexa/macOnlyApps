//
//  StatusView.m
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/1/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "StatusView.h"

@implementation StatusView


-(void)awakeFromNib
{
    CGSize size = CGSizeMake(self.frame.size.width, self.frame.size.height);
    [bgView setImage:[self imageFromBaseRectangle:CGSizeMake(size.width*2, size.height*2)]];    
}


-(NSImage*)imageFromBaseRectangle:(CGSize)size
{
    NSImage *ret = [[NSImage alloc] initWithSize:CGSizeMake(size.width, size.height)];
    [ret lockFocus];
    [self baseRectangle:NSMakeRect(0, 0, size.width, size.height)];
    [self createGraphContents];    
    [self drawShine:NSMakeRect(0, 0, size.width, size.height)];
    [ret unlockFocus];
    return ret;
}

-(void)createGraphContents
{
}
    
-(void)baseRectangle:(CGRect)rect
{    
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    
    [[NSColor clearColor] set];
    
    //base rectangle
    NSBezierPath *baseShape = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:12.0 yRadius:12.0];
    [[NSColor blackColor] set];
    [baseShape fill];

    
}

-(void)drawShine:(CGRect)rect
{
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    
    [[NSColor clearColor] set];
    
    //create triangle path
    CGMutablePathRef substractTriangle  = CGPathCreateMutable();
    CGPathMoveToPoint(substractTriangle, NULL,0,rect.size.height);
    CGPathAddLineToPoint(substractTriangle, NULL,0,rect.size.height/4.0);
    CGPathAddLineToPoint(substractTriangle, NULL,rect.size.width,rect.size.height);
    
    //clip anything outside triangle
    CGContextBeginPath (context);
    CGContextAddPath(context, substractTriangle);
    CGContextClosePath (context);
    CGContextClip (context);
    CGPathRelease(substractTriangle);
    
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor whiteColor] colorWithAlphaComponent:0.4] endingColor:[[NSColor whiteColor] colorWithAlphaComponent:0.0]];
    [gradient drawInRect:rect angle:180];
    
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