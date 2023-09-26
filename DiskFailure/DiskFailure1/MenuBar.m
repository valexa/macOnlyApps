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
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	        
        
        //init icon
        _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
        [_statusItem setHighlightMode:YES];
        [_statusItem setToolTip:[NSString stringWithFormat:@"DiskFailure"]];
        [_statusItem setAlternateImage:[NSImage imageNamed:@"mbar_"]];	        
        [_statusItem setAction:@selector(iconClick:)];
        [_statusItem setDoubleAction:@selector(iconClick:)];
        [_statusItem setTarget:self];         
        
        if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"redIcon"] boolValue] == YES) {              
            [_statusItem setImage:[NSImage imageNamed:@"mbar_red"]];                
        } else if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"litIcon"] boolValue] == YES) { 
            [_statusItem setImage:[NSImage imageNamed:@"mbar_yellow"]];      
        } else {
            [_statusItem setImage:[NSImage imageNamed:@"mbar"]];            
        }
        
    }  
    return self;
}

- (void)dealloc
{  
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
    [_statusItem release];
    [super dealloc];    
}


-(void)theEvent:(NSNotification*)notif{	
    if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
        return;
    }	
    if ([[notif object] isKindOfClass:[NSString class]]){
        if ([[notif object] isEqualToString:@"refreshIcon"]){            
            if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"redIcon"] boolValue] == YES) {              
                [_statusItem setImage:[NSImage imageNamed:@"mbar_red"]];   
                [[NSApp dockTile] setBadgeLabel:@"failing"]; //bounces it on each refresh                      
            } else if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]  objectForKey:@"litIcon"] boolValue] == YES) { 
                [_statusItem setImage:[NSImage imageNamed:@"mbar_yellow"]];                
            } else {
                [_statusItem setImage:[NSImage imageNamed:@"mbar"]];            
            }            
        }        
    }
    
}

- (void) iconClick:(id)sender {			
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"showWindow" userInfo:nil];				
}



@end
