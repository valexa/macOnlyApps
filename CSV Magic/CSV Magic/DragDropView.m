//
//  DragDropView.m
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/2/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "DragDropView.h"

@implementation DragDropView


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGRect rect = CGRectMake(self.bounds.size.width/2-(self.bounds.size.width/1.8)/2,self.bounds.size.height/2-(self.bounds.size.height/1.8)/2, self.bounds.size.width/1.8, self.bounds.size.height/1.8);
    
    [[NSColor clearColor] set];
        
    //base rectangle
    NSBezierPath *baseShape = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:24.0 yRadius:24.0];
    baseShape.lineWidth = 6.0;
    [[NSColor colorWithCalibratedWhite:0.3 alpha:0.7] setStroke];
    if (red == YES) [[NSColor colorWithCalibratedRed:0.7 green:0.5 blue:0.5 alpha:0.7] setStroke];
    const CGFloat p[2] = {14, 14};
    [baseShape setLineDash:p count:2 phase:0];
    [baseShape stroke];
    
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    return NSDragOperationCopy;    
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{

    NSPasteboard *pb = [sender draggingPasteboard];
    NSArray *objects = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
    if ([objects count] == 1)
    {
        NSURL *file = [objects objectAtIndex:0];
        if ([[file pathExtension] isEqualToString:@"csv"]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [loadController loadCSV:[file path]];
            });
        }else{
            red = YES;
            [self setNeedsDisplay:YES];
            [self performSelector:@selector(redOff) withObject:nil afterDelay:1];
        }
    }else{
        red = YES;
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(redOff) withObject:nil afterDelay:1];
    }
    
    if (red == NO) return YES;
    return NO;
}

-(void)redOff
{
    red = NO;
    [self setNeedsDisplay:YES];
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    if (context == NSDraggingContextWithinApplication) {
        return NSDragOperationGeneric;
    }
    
    return NSDragOperationNone;
}

@end
