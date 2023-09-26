//
//  PieSliceLayer.m
//  PieChart
//
//  Created by Pavan Podila on 2/20/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import "PieSliceLayer.h"

#import "PieView.h"

@implementation PieSliceLayer

@dynamic startAngle, endAngle;
@synthesize fillColor, strokeColor, strokeWidth;

+ (BOOL)needsDisplayForKey:(NSString *)key
{
	if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
		return YES;
	}	
	return [super needsDisplayForKey:key];
}

-(CABasicAnimation *)makeAnimationForKey:(NSString *)key
{
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
	anim.fromValue = [[self presentationLayer] valueForKey:key];
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	anim.duration = 1.0;

	return anim;
}

-(id<CAAction>)actionForKey:(NSString *)event
{
	if ([event isEqualToString:@"startAngle"] || [event isEqualToString:@"endAngle"]) {
		return [self makeAnimationForKey:event];
	}
	
	return [super actionForKey:event];
}

- (id)init {
    self = [super init];
    if (self) {
		self.fillColor = [NSColor grayColor];
        self.strokeColor = [NSColor blackColor];
		self.strokeWidth = 1.0;
		
		[self setNeedsDisplay];
    }
	
    return self;
}

- (id)initWithLayer:(id)layer
{
	if (self = [super initWithLayer:layer]) {
		if ([layer isKindOfClass:[PieSliceLayer class]])
        {
			PieSliceLayer *other = (PieSliceLayer *)layer;
			self.startAngle = other.startAngle;
			self.endAngle = other.endAngle;
			self.fillColor = other.fillColor;

			self.strokeColor = other.strokeColor;
			self.strokeWidth = other.strokeWidth;
            
		}
	}
	
	return self;
}


-(void)drawInContext:(CGContextRef)context
{
    
	CGPoint center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
	CGFloat radius = MIN(center.x-2.0, center.y-2.0);
	CGFloat halfRadius = radius/sqrt(2);
    CGFloat halfAngle = (self.endAngle + self.startAngle)/2.0;
    //CGFloat size = (self.endAngle-self.startAngle/M_PI)*self.bounds.size.width;
    
	CGPoint o1 = CGPointMake(center.x + radius * cosf(self.startAngle), center.y + radius * sinf(self.startAngle));
	CGPoint o2 = CGPointMake(center.x + radius * cosf(self.endAngle), center.y + radius * sinf(self.endAngle));
  	CGPoint o3 = CGPointMake(center.x + (radius*sqrt(2)) * cosf(halfAngle), center.y + (radius*sqrt(2)) * sinf(halfAngle));

    CGPoint i1 = CGPointMake(center.x + halfRadius * cosf(self.startAngle), center.y + halfRadius * sinf(self.startAngle));
	CGPoint i2 = CGPointMake(center.x + halfRadius * cosf(self.endAngle), center.y + halfRadius * sinf(self.endAngle));
  	CGPoint i3 = CGPointMake(center.x + (halfRadius*sqrt(2)) * cosf(halfAngle), center.y + (halfRadius*sqrt(2)) * sinf(halfAngle));

	// begin counterclockwise drawing
	CGContextBeginPath(context);
    
    if ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask )
    {
        if ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask ){
            //vertexes
            CGContextAddRect(context,NSMakeRect(o1.x, o1.y, 4, 4));
            CGContextAddRect(context,NSMakeRect(o2.x, o2.y, 4, 4));
            CGContextAddRect(context,NSMakeRect(o3.x-4, o3.y-4, 8, 8));
            CGContextAddRect(context,NSMakeRect(i2.x, i2.y, 4, 4));
            CGContextAddRect(context,NSMakeRect(i1.x, i1.y, 4, 4));
            CGContextAddRect(context,NSMakeRect(i3.x-4, i3.y-4, 8, 8));
        }else if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask ){
            //should work
            CGContextMoveToPoint(context, o1.x, o1.y);
            CGContextAddArcToPoint(context, o3.x, o3.y, o2.x, o2.y, radius);
            CGContextAddLineToPoint(context, i2.x, i2.y);
            CGContextAddArcToPoint(context, i3.x, i3.y, i1.x, i1.y, halfRadius);
        }else{
            //inverse clockwise
            CGContextMoveToPoint(context, o2.x, o2.y);
            CGContextAddArcToPoint(context, o3.x, o3.y, o1.x, o1.y, radius);
            CGContextAddLineToPoint(context, i1.x, i1.y);
            CGContextAddArcToPoint(context, i3.x, i3.y, i2.x, i2.y, halfRadius);
        }
    }
    else if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask )
    {
        if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask ){
            //hexagonal
            CGContextMoveToPoint(context, o1.x, o1.y);
            CGContextAddLineToPoint(context, o2.x, o2.y);
            CGContextAddLineToPoint(context, i2.x, i2.y);
            CGContextAddLineToPoint(context, i1.x, i1.y);
        }else{
            //hexagonal with corners
            CGContextMoveToPoint(context, o1.x, o1.y);
            CGContextAddLineToPoint(context, o3.x, o3.y);
            CGContextAddLineToPoint(context, o2.x, o2.y);
            CGContextAddLineToPoint(context, i2.x, i2.y);
            CGContextAddLineToPoint(context, i3.x, i3.y);
            CGContextAddLineToPoint(context, i1.x, i1.y);
        }
    }
    else if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask )
    {
        //shape
        CGContextMoveToPoint(context, o1.x, o1.y);
        //CGContextAddArcToPoint(context, o3.x, o3.y, o2.x, o2.y, radius);
        CGContextAddLineToPoint(context, o2.x, o2.y);
        CGContextAddLineToPoint(context, i2.x, i2.y);
        CGContextAddLineToPoint(context, o3.x, o3.y);
        CGContextAddLineToPoint(context, i1.x, i1.y);
    }
    else if ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask )
    {
        //quad
        CGContextMoveToPoint(context, o1.x, o1.y);
        CGContextAddQuadCurveToPoint(context, o3.x, o3.y, o2.x, o2.y);
        CGContextAddLineToPoint(context, i2.x, i2.y);
        CGContextAddQuadCurveToPoint(context, i3.x, i3.y, i1.x, i1.y);
    }
    else
    {
        [self easyWay:context];
        return;  
    }

	// close    
	CGContextClosePath(context);
    
	// Color it
	CGContextSetFillColorWithColor(context, self.fillColor.CGColorCompat);
	CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColorCompat);
	CGContextSetLineWidth(context, 1.0);

	CGContextDrawPath(context, self.strokeWidth);
    
}

-(void)easyWay:(CGContextRef)context
{
	CGPoint center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
	CGFloat radius = MIN(center.x-2.0, center.y-2.0);
    
    CGContextMoveToPoint(context, center.x, center.y);
    int clockwise = self.startAngle > self.endAngle;
    CGContextAddArc(context, center.x, center.y, radius, self.startAngle, self.endAngle, clockwise);
    
	// Color it
	CGContextSetFillColorWithColor(context, self.fillColor.CGColorCompat);
	CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColorCompat);
	CGContextSetLineWidth(context, 1.0);
    
	CGContextDrawPath(context, self.strokeWidth);
    
    if (!CGContextIsPathEmpty(context)) CGContextClip(context);
    
    CGContextSetFillColorWithColor( context, [NSColor redColor].CGColorCompat );
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGRect holeRect = CGRectMake((self.bounds.size.width-185.0)/2, (self.bounds.size.height-185.0)/2, 185.0, 185.0);
    CGContextFillEllipseInRect( context, holeRect );

}

@end
