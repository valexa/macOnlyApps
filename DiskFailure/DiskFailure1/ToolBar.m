//
//  ToolBar.m
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ToolBar.h"
#import "DiskFailureAppDelegate.h"

#define MAIN_OBSERVER_NAME_STRING @"VADiskFailureEvent"

@implementation ToolBar

@synthesize theBar;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
	
        //init array with icon params and start adding
        NSMutableDictionary *params =[NSMutableDictionary dictionaryWithCapacity:1];
        
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Quit", @"Name",
                           @"Quit DiskFailure", @"Tip",
                           @"quit", @"Icon",
                           @"tbclickQuit:", @"Act", 
                           nil] forKey:@"1"];
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Refresh", @"Name",
                           @"Refresh the list", @"Tip",
                           @"refresh", @"Icon",
                           @"tbclickRefresh:", @"Act", 
                           nil] forKey:@"2"];
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"About", @"Name",
                           @"Visit us on the web", @"Tip",
                           @"info", @"Icon",
                           @"tbclickAbout:", @"Act",
                           nil] forKey:@"4"];        	        
        
        //create icons from params
        items = [[NSMutableDictionary alloc] init];
        id key;
        NSEnumerator *loop = [params keyEnumerator];
        while ((key = [loop nextObject])) {
            NSDictionary *dict = [params objectForKey:key];
            [items setObject:[self configureToolbarItem: dict] forKey:[dict objectForKey: @"Name"]];
        }
        //add a toolbar
        theBar = [[NSToolbar alloc] initWithIdentifier:@"tbar"];
        [theBar setDelegate:self];
        [theBar setAllowsUserCustomization:YES];
        [theBar setAutosavesConfiguration:YES];
        
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark toolbar datasource

- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:[optionsDict objectForKey: @"Name"]];
	[item setPaletteLabel: [optionsDict objectForKey: @"Name"]];
	[item setLabel: [optionsDict objectForKey: @"Name"]];
	[item setToolTip: [optionsDict objectForKey: @"Tip"]];
	[item setImage: [NSImage imageNamed: [optionsDict objectForKey: @"Icon"]]];
	[item setTarget:self];
	[item setAction: NSSelectorFromString([optionsDict objectForKey: @"Act"])];
	return [item autorelease];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)thetoolbar itemForItemIdentifier:(NSString *)itemIdentifier  willBeInsertedIntoToolbar:(BOOL)flag 
{
    return [items objectForKey:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)thetoolbar
{
    return [items allKeys];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)thetoolbar
{
    return [NSArray arrayWithObjects:             
            NSToolbarSpaceItemIdentifier,                                                             
            @"Refresh",            
            NSToolbarSpaceItemIdentifier,                           
            @"About",
            NSToolbarSpaceItemIdentifier,            
            @"Quit",                                                   
            NSToolbarFlexibleSpaceItemIdentifier,
            //NSToolbarSeparatorItemIdentifier,            
            nil];
}


#pragma mark toolbar actions

- (void)tbclickAbout:(NSToolbarItem*)item{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"showAbout" userInfo:nil];  
}

- (void)tbclickRefresh:(NSToolbarItem*)item{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"doRefresh" userInfo:nil];     
}     

- (void)tbclickQuit:(NSToolbarItem*)item{
    [NSApp terminate:nil];
}

@end
