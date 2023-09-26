//
//  LaunchButton.m
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/14/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "LaunchButton.h"

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

@implementation LaunchButton

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
		editing = NO;		
        
		[self setFocusRingType:NSFocusRingTypeNone];
		[self setButtonType:NSMomentaryChangeButton];					
		[self setImagePosition:NSImageAbove];
		[self setBordered:NO];
		[self.cell setLineBreakMode:NSLineBreakByTruncatingTail];		

		//register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:BUTTON_OBSERVER_NAME_STRING object:nil];
        
		//add delete button
		deleteButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,28,28)];
        NSImage *x = [NSImage imageNamed:@"x"];
        [x setSize:NSMakeSize(20, 20)];
        [deleteButton setImage:x];
		[deleteButton setTarget:self]; 
		[deleteButton setAction:@selector(deleteIcon)];				
		[deleteButton setToolTip:@"Remove the application, to have it show again launch it manually"];									
		[deleteButton setFocusRingType:NSFocusRingTypeNone];
		[deleteButton setBordered:NO];	
		[deleteButton setButtonType:NSMomentaryChangeButton];		
		[deleteButton setHidden:YES];
		[self addSubview:deleteButton];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hasExcluded"] == YES) [self cursorCheckLoop];
	
    }
    return self;
}

-(void)dealloc
{
	//NSLog(@"LaunchButton freed");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)deleteIcon
{
	[[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"deleteIcon" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:[self tag]] forKey:@"tag"]];
}

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:BUTTON_OBSERVER_NAME_STRING]) {
		return;
	}	
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
	}	
	if ([[notif object] isKindOfClass:[NSString class]])
    {
		if ([[notif object] isEqualToString:@"beganEditing"])
        {
			editing = YES;
			[deleteButton setHidden:NO];            
			[self animateBlink:deleteButton]; //turns on opengl
		}							
		if ([[notif object] isEqualToString:@"endedEditing"])
        {
			if (editing == YES) {
				editing = NO;	
				[deleteButton setHidden:YES];
			}
		}
		if ([[notif object] isEqualToString:@"appActive"])
        {
            appActive = YES;
		}
		if ([[notif object] isEqualToString:@"appInactive"])
        {
            appActive = NO;
		}
	}			
}

-(void)animateBlink:(NSView*)theView
{
    [theView setWantsLayer:YES];
    
	///Scale the X and Y dimmensions by a factor of 2
	CATransform3D tt = CATransform3DMakeScale(1.25,1.25,0.5);
    
	CABasicAnimation *animation = [CABasicAnimation animation];
	animation.fromValue = [NSValue valueWithCATransform3D: CATransform3DIdentity];
	animation.toValue = [NSValue valueWithCATransform3D: tt];
	animation.duration = 0.1;
	animation.removedOnCompletion = YES;
    animation.autoreverses = YES;
	animation.fillMode = kCAFillModeBoth;
	[theView.layer addAnimation:animation forKey:@"transform"];
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if (editing != YES)
    {
        [self performSelector:@selector(checkMouseHeld) withObject:nil afterDelay:2.0];
	}else{
        [self performSelector:@selector(endDelayed) withObject:nil afterDelay:1.0];
    }
    holding = YES;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (editing != YES)
    {
		[self performClick:nil];		
	}
    holding = NO;
}


-(void) checkMouseHeld
{
	if (holding == YES)
    {
		//NSLog(@"Button held for 3 seconds, should start to shake and not trigger click");
		[[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"beganEditing"];
	}
}

-(void) endDelayed
{
     [[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"endedEditing"];
}

-(void)mouseEntered:(NSEvent *)event
{
	[[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"showPopover" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:[self tag]] forKey:@"tag"]];
}

-(void)mouseExited:(NSEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"hidePopover"];
}

-(void)cursorCheckLoop
{
    //doing this because of damn NSTrackingArea bug with scrolling
    NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    mouseLocation = [self convertPoint: mouseLocation fromView:nil];
    
    if (CGRectContainsPoint([self bounds],mouseLocation))
    {
        if (cursorIsInside == NO)
        {
            [self performSelector:@selector(mouseEntered:) withObject:nil afterDelay:0.2];
            [self animateBlink:self];
            cursorIsInside = YES;
            [self performSelector:@selector(cursorCheckLoop) withObject:nil afterDelay:1];
        }
    } else {
        if (cursorIsInside == YES)
        {
            [self performSelector:@selector(cursorCheckLoop) withObject:nil afterDelay:1];
            cursorIsInside = NO;
            [self mouseExited:nil];
        }else{
            [self performSelector:@selector(cursorCheckLoop) withObject:nil afterDelay:2];
        }
    }
    
}

@end
