//
//  ToolbarController.m
//  OSXCommander
//
//  Created by Vlad Alexa on 11/12/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "ToolbarController.h"


@implementation ToolbarController

@synthesize items;

- (id)theSender:(id)sender{

	//init array with icon params and start adding
	NSMutableDictionary *params =[[NSMutableDictionary alloc] init];
	
	[params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					   @"Website", @"Name",
					   @"Visit us on the web", @"Tip",
					   @"swap", @"Icon",
					   @"tbclickWebsite:", @"Act",
					   nil] forKey:@"1"];
	[params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					   @"Refresh", @"Name",
					   @"Refresh the list", @"Tip",
					   @"swap", @"Icon",
					   @"tbclickRefresh:", @"Act", 
					   nil] forKey:@"2"];
	[params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					   @"Info", @"Name",
					   @"Info on item", @"Tip",
					   @"swap", @"Icon",
					   @"tbclickInfo:", @"Act", 
					   nil] forKey:@"3"];	
	[params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					   @"Sharing", @"Name",
					   @"Sharing Services", @"Tip",
					   @"swap", @"Icon",
					   @"tbclickApp:", @"Act", 
					   nil] forKey:@"4"];
	[params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					   @"Login", @"Name",
					   @"Open Login Items", @"Tip",
					   @"icon", @"Icon",
					   @"tbclickAcc:", @"Act", 
					   nil] forKey:@"5"];	
	
	//create icons from params
	items = [[NSMutableDictionary alloc] init];
	for (id key in params) {
		NSDictionary *dict = [params objectForKey:key];
		[items setObject:[self configureToolbarItem: dict] forKey:[dict objectForKey: @"Name"]];
	}
	[params release];
	//add a toolbar
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"ToolbarController"];
	[toolbar setDelegate:self];
	[toolbar setShowsBaselineSeparator:NO];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[sender setToolbar:toolbar];		

	return self;	
	
}	

- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict
{
	NSToolbarItem *item=[[NSToolbarItem alloc] initWithItemIdentifier: [optionsDict objectForKey: @"Name"]];
	[item setPaletteLabel: [optionsDict objectForKey: @"Name"]];
	[item setLabel: [optionsDict objectForKey: @"Name"]];
	[item setToolTip: [optionsDict objectForKey: @"Tip"]];
	//[item setImage: [NSImage imageNamed: [optionsDict objectForKey: @"Icon"]]];
	[item setTarget:self];
	[item setAction: NSSelectorFromString([optionsDict objectForKey: @"Act"])];
	return item;
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
			NSToolbarFlexibleSpaceItemIdentifier,			
			@"Info",			
			@"Refresh",			
			NSToolbarSeparatorItemIdentifier,		
			@"Sharing",
			@"Login",
			NSToolbarSeparatorItemIdentifier,				
			@"Website",				
			NSToolbarFlexibleSpaceItemIdentifier,				
			//NSToolbarSpaceItemIdentifier,				
			//NSToolbarCustomizeToolbarItemIdentifier,						
			nil];
}

@end
