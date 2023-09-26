//
//  AppDelegate.m
//  CSV Magic
//
//  Created by Vlad Alexa on 1/12/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
}

- (IBAction)openDocument:(id)sender
{
    
    NSOpenPanel *open = [NSOpenPanel openPanel];
    [open setAllowsMultipleSelection:NO];
    [open setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
    [open setShowsHiddenFiles:YES];
    [open setTreatsFilePackagesAsDirectories:YES];
    [open setTitle:@"Import CSV"];
    [open beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger result) {
        if(result==NSOKButton)
        {
            if ([[open URLs] count] == 1)
            {
                NSURL *file = [[open URLs] objectAtIndex:0];
                
                [self performSelector:@selector(openCSV:) withObject:[file path] afterDelay:0.5];

            }
        }
    }];
    
}

-(void)openCSV:(NSString*)filename
{
    [mainController reset:self];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [loadController loadCSV:filename];
    });
}

-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    
    [self performSelector:@selector(openCSV:) withObject:filename afterDelay:0.5];
    
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}

-(IBAction) showAbout:(id)sender
{
	[NSApp beginSheet:aboutWindow modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)closeSheet:(id)sender
{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
}

- (IBAction) openWebsite:(id)sender{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
	NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/csvmagic"];
	[[NSWorkspace sharedWorkspace] openURL:url];
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


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation NSColor (StringOverrides)

+(NSArray *)controlAlternatingRowBackgroundColors
{
	return [NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:0.99 alpha:1.0],[NSColor whiteColor],nil];
}

@end
#pragma clang diagnostic pop