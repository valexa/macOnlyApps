//
//  AboutController.m
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/2/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "AboutController.h"

@interface AboutController ()

@end

@implementation AboutController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction) openWebsite:(id)sender{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
	NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/musiclibrarymagic"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

-(IBAction) showAbout:(id)sender{
	[NSApp beginSheet:aboutWindow modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)closeSheet:(id)sender
{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
}

#pragma mark version

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
    if ([key isEqualToString: @"versionString"]) return YES;
    return NO;
}

- (NSString *)versionString {
	NSString *sv = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	return [NSString stringWithFormat:@"version %@ (%@)",sv,v];
}



@end
