//
//  MenuBar.m
//  Files
//
//  Created by Vlad Alexa on 5/23/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "MenuBar.h"

#import "NSWindow+Flipping.h"

@implementation MenuBar

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MenuBarEvent" object:nil];
        
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        
        menuBarIcon = [[MenuBarIcon alloc] init];
        [_statusItem setView:menuBarIcon];        
        
    }
    
    return self;
}


-(void)theEvent:(NSNotification*)notif
{	
	if (![[notif name] isEqualToString:@"MenuBarEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]])
    {
        if ([[notif object] isEqualToString:@"click"]) {
            [self click];
        }
        if ([[notif object] isEqualToString:@"rightclick"]) {
            [self doubleClick];
        }
        if ([[notif object] isEqualToString:@"clickOff"]) {
            [menuBarIcon setMouseDown:NO];
            [menuBarIcon setNeedsDisplay:YES];
        }
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){

    }    
}

-(void)click
{
    if ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask ){
        [self flipToAdvanced:self];
        return;
    }
    if ([popOverAdvanced isShown]) [popOverAdvanced performClose:self];
    
    if ([popOver isShown]) {
        [popOver performClose:self];
    }else{
        [popOver showRelativeToRect:menuBarIcon.bounds ofView:menuBarIcon preferredEdge:NSMinYEdge];        
    }
    if ([popOverBack isShown]) [self flipToFront:self];
}

-(void)doubleClick
{
    if ([popOverAdvanced isShown]) [popOverAdvanced performClose:self];
    
    if ([popOverBack isShown]) {
        [popOverBack performClose:self];
    }else{
        [popOverBack showRelativeToRect:menuBarIcon.bounds ofView:menuBarIcon preferredEdge:NSMinYEdge];           
    }
    if ([popOver isShown]) [self flipToBack:self];
}

-(IBAction)flipToBack:(id)sender
{
    [popOverBack showRelativeToRect:menuBarIcon.bounds ofView:menuBarIcon preferredEdge:NSMinYEdge];
    if ([popOver isShown]) [popOver.contentViewController.view.window flipToShowWindow:popOverBack.contentViewController.view.window forward:NO];
    if ([popOver isShown]) [popOver performClose:self];    
    if ([popOverAdvanced isShown]) [popOverAdvanced.contentViewController.view.window flipToShowWindow:popOverBack.contentViewController.view.window forward:NO];
    if ([popOverAdvanced isShown]) [popOverAdvanced performClose:self];     
}

-(IBAction)flipToFront:(id)sender
{
    [popOver showRelativeToRect:menuBarIcon.bounds ofView:menuBarIcon preferredEdge:NSMinYEdge];    
    [popOverBack.contentViewController.view.window flipToShowWindow:popOver.contentViewController.view.window forward:YES];
    if ([popOverBack isShown]) [popOverBack performClose:self];    
}

-(IBAction)flipToAdvanced:(id)sender
{
    if ([popOverBack isShown]) [popOverBack performClose:self];    
    [popOverAdvanced showRelativeToRect:menuBarIcon.bounds ofView:menuBarIcon preferredEdge:NSMinYEdge];
    //[popOverBack.contentViewController.view.window flipToShowWindow:popOverAdvanced.contentViewController.view.window forward:YES];
    [advButton setTitle:@"Extra monitoring ON"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AdvancedPopoverEvent" object:@"becameResponder" userInfo:nil];    
}

-(IBAction)quit:(id)sender
{
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
    [NSApp terminate:self];
}

-(IBAction)togleOnTop:(id)sender
{
    if ([popOver behavior] == NSPopoverBehaviorTransient) {
        [popOver setBehavior:NSPopoverBehaviorApplicationDefined];
    }else{
        [popOver setBehavior:NSPopoverBehaviorTransient];
    }
}

@end

