//
//  AppDelegate.m
//  OSXCommander
//
//  Created by Vlad Alexa on 11/5/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize startedAt,left,right,rightPane,leftPane,splitView,window;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}

- (void)awakeFromNib {

	self.startedAt = [NSDate date];
	//NSLog(@"Awake");		
	
	//[splitView constrainMinCoordinate:100.0 ofSubviewAt:0];

	left=[[PaneController alloc] theName:@"left" theType:@"file" theSender:leftPane];
	right=[[PaneController alloc] theName:@"right" theType:@"file" theSender:rightPane];	

	//CFShow(left);
	//CFShow(right);	
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	//NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	//[defaults setObject:@"I Saved it" forKey:@"didSave"];
	//[defaults synchronize];
	//NSString* str = [defaults objectForKey:@"didSave"];	

	NSArray *leftArr = [[[leftPane subviews] objectAtIndex:0] subviews];
	NSArray *rightArr = [[[rightPane subviews] objectAtIndex:0] subviews];
	[[leftArr objectAtIndex:2] setTitleWithMnemonic:@"left"];
	[[rightArr objectAtIndex:2] setTitleWithMnemonic:@"right"];
	
	//[leftPane setHidden:NO];
	//[rightPane setHidden:NO];
	//[splitView setNeedsDisplay:YES];	
	
	ToolbarController *foo = [[ToolbarController alloc] theSender:window];
	//CFShow(foo);
	
	//NSLog(@"finish launching");
	NSLog(@"OSXCommander launched in %f sec",[[NSDate date] timeIntervalSinceDate:startedAt]);		
}

- (IBAction)startAnimations:(id)sender
{
	//fix zooming issue if panes are resized , TODO!
	NSLog(@"switching tabs");
    NSViewAnimation *theAnim;
    NSMutableDictionary* firstViewDict;
    NSMutableDictionary* secondViewDict;
	
    {
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [firstViewDict setObject:leftPane forKey:NSViewAnimationTargetKey];
        [firstViewDict setObject:[NSValue valueWithRect:[leftPane frame]] forKey:NSViewAnimationStartFrameKey];
        [firstViewDict setObject:[NSValue valueWithRect:[rightPane frame]] forKey:NSViewAnimationEndFrameKey];	
    }
	
    {
        secondViewDict = [NSMutableDictionary dictionaryWithCapacity:3];		
        [secondViewDict setObject:rightPane forKey:NSViewAnimationTargetKey];
        [secondViewDict setObject:[NSValue valueWithRect:[rightPane frame]] forKey:NSViewAnimationStartFrameKey];		
        [secondViewDict setObject:[NSValue valueWithRect:[leftPane frame]] forKey:NSViewAnimationEndFrameKey];
    }

    [firstViewDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];			
	[secondViewDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];	
    // Create the view animation object.
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict, secondViewDict, nil]];
    [theAnim setDuration:0.5];
    [theAnim setAnimationCurve:NSAnimationEaseOut];
    [theAnim startAnimation];
    [theAnim release];	
}

- (void)dealloc {
	[left release];
	[right release];	
	[super dealloc];
}


@end