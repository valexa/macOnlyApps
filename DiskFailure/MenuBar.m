//
//  MenuBar.m
//  DiskFailure
//
//  Created by Vlad Alexa on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuBar.h"


#define MAIN_OBSERVER_NAME_STRING @"VADiskFailureEvent"
#define OBSERVER_NAME_STRING @"VADiskFailureMenuBarEvent"
#define PLUGIN_NAME_STRING @"DiskFailure"

@implementation MenuBar

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        defaults = [NSUserDefaults standardUserDefaults];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	        
        
        //init icon
        _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
        [_statusItem setHighlightMode:YES];
        [_statusItem setToolTip:[NSString stringWithFormat:@"DiskFailure"]];
        [_statusItem setAction:@selector(iconClick:)];
        [_statusItem setDoubleAction:@selector(iconClick:)];
        [_statusItem setTarget:self];         
        
        [self setIcon];
        
    }  
    return self;
}

-(NSImage*) imageFromImage:(NSImage*)image withOpacity:(float)newOpacity andSize:(NSSize)size
{
    [image setSize:size];
    if (size.height <= 0 || size.width <= 0) return image;
    NSImage *new = [[NSImage alloc] initWithSize:size];
    [new lockFocus];
    [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:newOpacity];    
    [new unlockFocus];
    return [new autorelease];
}


- (void)dealloc
{  
    [[NSNotificationCenter defaultCenter] removeObserver:self];     
    [_statusItem release];
    [super dealloc];    
}


-(void)theEvent:(NSNotification*)notif{	
    if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
        return;
    }	
    if ([[notif object] isKindOfClass:[NSString class]]){
        if ([[notif object] isEqualToString:@"refreshIcon"]){
            [self setIcon];
        }
        if ([[notif object] isEqualToString:@"progressIcon"]){
            [self progressLoop];
        }
    }    
    
}

-(void)setIcon
{
    NSImage *image = [self menubarImage:NSMakeSize(18, 20)];
   [[NSApp dockTile] setBadgeLabel:@""];
    
    if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"redIcon"] boolValue] == YES)
    {
        image = [self imageFromImage:[NSImage imageNamed:@"failing.png"] withOpacity:1.0 andSize:NSMakeSize(18, 20)];
        [[NSApp dockTile] setBadgeLabel:@"failing"]; //bounces it on each refresh
    }
    else if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"litIcon"] boolValue] == YES)
    {
        image = [self imageFromImage:[NSImage imageNamed:@"unsure.png"] withOpacity:1.0 andSize:NSMakeSize(18, 20)];
    }
    [_statusItem setImage:image];
}

- (void) iconClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"showWindow" userInfo:nil];
}

-(void)progressLoop
{
    progress += 0.1;
    if (progress > 1) {
        progress = 0.0;
        [self setIcon];
    }else{
        [_statusItem setImage:[self menubarImage:NSMakeSize(18, 20)]];
        [self performSelector:@selector(progressLoop) withObject:nil afterDelay:0.1];
    }
}


-(NSImage*)menubarImage:(NSSize)size
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:size];
	[compositeImage setCacheMode:NSImageCacheNever];
    [compositeImage lockFocus];
    
    //base rectangle
    float width = size.width;
    float height = size.height;
    float unit = width/9.0;
    NSBezierPath *baseShape = [NSBezierPath bezierPath];
    baseShape.lineWidth = 1.0;
    [baseShape moveToPoint:NSMakePoint(unit, height/9.0)]; //bottom left
    [baseShape lineToPoint:NSMakePoint(unit/2, height/4.5)]; //middle left
    [baseShape lineToPoint:NSMakePoint(unit*2, height-unit)]; //top left
    [baseShape lineToPoint:NSMakePoint(width-unit*2, height-unit)]; //top right
    [baseShape lineToPoint:NSMakePoint(width-unit/2, height/4.5)];  //middle right
    [baseShape lineToPoint:NSMakePoint(width-unit, height/9.0)];  //bottom right
    [baseShape closePath];
    [[NSColor colorWithCalibratedWhite:0.3 alpha:0.7] setStroke];
    [baseShape stroke];
    
    if (progress > 0) {
        NSGradient *fillGradient = [[NSGradient alloc] initWithStartingColor:[NSColor blackColor] endingColor:[NSColor grayColor]];
        [fillGradient drawInBezierPath:baseShape angle:360*progress];
        [fillGradient release];
    }else{
        [[NSColor colorWithCalibratedWhite:0.7 alpha:0.5] setFill];
        [baseShape fill];
    }
    
    [compositeImage unlockFocus];
    
    return [compositeImage autorelease];
}

@end
