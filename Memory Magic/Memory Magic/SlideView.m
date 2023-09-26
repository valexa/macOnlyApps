//
//  SlideView.m
//  Memory Magic
//
//  Created by Vlad Alexa on 11/8/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "SlideView.h"

@implementation SlideView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain]; /// ~/Library/Preferences/.GlobalPreferences.plist
        if ([dict objectForKey:@"com.apple.swipescrolldirection"] == nil) {
            natural = YES;
        } else {
            natural = [[dict objectForKey:@"com.apple.swipescrolldirection"] boolValue];
        }
        
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (void)keyDown:(NSEvent *)theEvent {
    
    if ([theEvent modifierFlags] & NSNumericPadKeyMask)
    {
        
        NSString *key = [theEvent charactersIgnoringModifiers];
        
        unichar keyChar = 0;
        
        if ( [key length] == 0 )  return;   // reject dead keys
        
        if ( [key length] == 1 )
        {
            keyChar = [key characterAtIndex:0];
            
            if ( keyChar == NSLeftArrowFunctionKey  ) {
                NSLog(@"Left");
                return;
            }
            
            if ( keyChar == NSRightArrowFunctionKey ) {
                NSLog(@"Right");
                return;                
            }
        }
    }
    
    [super keyDown:theEvent];    
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PopoverEvent" object:@"becameResponder" userInfo:nil];
    return YES;
}


- (void)mouseDragged:(NSEvent *)theEvent
{

}

- (void)scrollWheel:(NSEvent *)event {
	if ([event type] == 22){
		NSString *phase;
		if ([[event description] rangeOfString:@"scrollPhase"].location == NSNotFound) {
			phase = @"None";
		}else{
			NSString *object = [[[event description] componentsSeparatedByString:@" "] lastObject];
			phase = [object substringWithRange:NSMakeRange(12,[object length]-12)];
		}
		if ([phase isEqualToString:@"None"]){
			if ( ([event scrollingDeltaX] > 0  && natural == NO) || ([event scrollingDeltaX] < 0  && natural == YES) )
            {
                if (CFAbsoluteTimeGetCurrent() - triggerTime > 1.5)
                {
                    triggerTime = CFAbsoluteTimeGetCurrent();
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PopoverEvent" object:@"leftSlide" userInfo:nil];                    
                }
                
			}
			if ( ([event scrollingDeltaX] < 0  && natural == NO) || ([event scrollingDeltaX] > 0  && natural == YES) )
            {
                if (CFAbsoluteTimeGetCurrent() - triggerTime > 1.5)
                {
                    triggerTime = CFAbsoluteTimeGetCurrent();
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PopoverEvent" object:@"rightSlide" userInfo:nil];
                }

			}
		}
		if ([phase isEqualToString:@"Begin"]){
			if ( ([event scrollingDeltaX] > 0  && natural == NO) || ([event scrollingDeltaX] < 0  && natural == YES) ) {
				//NSLog(@"hard left");
			}
			if ( ([event scrollingDeltaX] < 0  && natural == NO) || ([event scrollingDeltaX] > 0  && natural == YES) ) {
				//NSLog(@"hard right");
			}
		}
	}
}


@end
