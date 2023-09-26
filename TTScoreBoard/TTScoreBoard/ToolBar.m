//
//  ToolBar.m
//  TTScoreBoard
//
//  Created by Vlad Alexa on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ToolBar.h"

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
                           @"Revoke Point", @"Name",
                           @"Remove one point from the player's score", @"Tip",
                           @"minus", @"Icon",
                           @"tbclickRevokeFirst:", @"Act", 
                           nil] forKey:@"1"];
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Revoke Point ", @"Name",
                           @"Remove one point from the player's score", @"Tip",
                           @"minus", @"Icon",
                           @"tbclickRevokeSecond:", @"Act", 
                           nil] forKey:@"2"];
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Flip", @"Name",
                           @"Flip the display around", @"Tip",
                           @"flip", @"Icon",
                           @"tbclickFlip:", @"Act", 
                           nil] forKey:@"3"];  
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Reset", @"Name",
                           @"Reset the scoreboard", @"Tip",
                           @"reset", @"Icon",
                           @"tbclickReset:", @"Act", 
                           nil] forKey:@"4"];  
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Middle Click", @"Name",
                           @"Software middle click", @"Tip",
                           @"middle", @"Icon",
                           @"tbclickMiddle:", @"Act", 
                           nil] forKey:@"5"];          
        
        //create icons from params
        items = [[NSMutableDictionary alloc] init];
        for (id key in params) {
            NSDictionary *dict = [params objectForKey:key];
            [items setObject:[self configureToolbarItem: dict] forKey:[dict objectForKey: @"Name"]];
        }
        //add a toolbar
        theBar = [[NSToolbar alloc] initWithIdentifier:@"tbar"];
        [theBar setDelegate:self];
        [theBar setAllowsUserCustomization:NO];
        //[theBar setSizeMode:NSToolbarSizeModeRegular];  
        //[theBar setDisplayMode:NSToolbarDisplayModeLabelOnly];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"ToolBarEvent" object:nil];	         
        
    }
    
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
    [items release];
    [theBar release];
    [super dealloc];
}

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:@"ToolBarEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){  
        if ([[notif object] isEqualToString:@"middle"]) {
            if ([[theBar items] count] == 13) {
                [theBar removeItemAtIndex:6];
            }
        }           
	}				
}


#pragma mark toolbar datasource

- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict
{
    NSString *name = [optionsDict objectForKey: @"Name"];
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:name];
	[item setPaletteLabel:name];
	[item setLabel:name];
	[item setToolTip:[optionsDict objectForKey: @"Tip"]];
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
            NSToolbarFlexibleSpaceItemIdentifier,            
            NSToolbarSpaceItemIdentifier,                                                                        
            @"Revoke Point",            
            NSToolbarSpaceItemIdentifier,            
            NSToolbarFlexibleSpaceItemIdentifier,            
            @"Flip",
            @"Middle Click",            
            @"Reset",            
            NSToolbarSpaceItemIdentifier,            
            NSToolbarFlexibleSpaceItemIdentifier,                               
            @"Revoke Point ",                           
            NSToolbarSpaceItemIdentifier, 
            NSToolbarFlexibleSpaceItemIdentifier,                      
            nil];
}


#pragma mark toolbar actions

- (void)tbclickRevokeFirst:(NSToolbarItem*)item{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FSWindowEvent" object:@"revokeFirstPoint" userInfo:nil];
}

- (void)tbclickRevokeSecond:(NSToolbarItem*)item{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FSWindowEvent" object:@"revokeSecondPoint" userInfo:nil];
}     

- (void)tbclickFlip:(NSToolbarItem*)item{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FSWindowEvent" object:@"flip" userInfo:nil];
}

- (void)tbclickReset:(NSToolbarItem*)item{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FSWindowEvent" object:@"reset" userInfo:nil]; 
}

- (void)tbclickMiddle:(NSToolbarItem*)item{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FSWindowEvent" object:@"middle" userInfo:nil];
}

@end
