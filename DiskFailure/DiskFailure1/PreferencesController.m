//
//  PreferencesController.m
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"
#import "DiskFailurePreferences.h"

#define PLUGIN_NAME_STRING @"DiskFailure"
#define MAIN_OBSERVER_NAME_STRING @"VADiskFailureEvent"

@implementation PreferencesController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
        defaults = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}

- (void)dealloc
{
    [preferences release];
    [super dealloc];    
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    preferences = [[DiskFailurePreferences alloc] init];        
    [prefView addSubview:preferences.view];    
    
	if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"autoStart"] boolValue] == YES) {
		[startToggle setSelectedSegment:1];
	}else {
		[startToggle setSelectedSegment:0];		
	}
	if ([[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"hideDock"] boolValue] == YES) {
		[dockToggle setSelectedSegment:1];
	}else {
		[dockToggle setSelectedSegment:0];		
	}
    
    NSString *frequency = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"checkFrequency"];   
    float factor = 1.0;
    if ([frequency intValue] > 100) factor = 10.0;
    if ([frequency intValue] > 1000) factor = 100.0;    
    [timerLevel setTag:factor];
    [timerLevel setDoubleValue:0.0];
    [timerLevel setMaxValue:[frequency doubleValue]/factor-1.0];    
    [refreshLabel setStringValue:[self refreshTimeInterval:[timerLevel maxValue]*factor]];    

    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerMove:) userInfo:nil repeats:YES]; 
    [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(timerReset:) userInfo:nil repeats:YES];     
    
}

#pragma mark core

-(void)saveSetting:(id)object forKey:(NSString*)key{   
    //this is the method for when the host application is not SytemPreferences (MagicPrefsPlugins or your standalone)    
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return;
	}       
    NSDictionary *prefs = [defaults objectForKey:PLUGIN_NAME_STRING];
    if ([prefs objectForKey:@"settings"] == nil) {
        NSMutableDictionary *d = [[prefs  mutableCopy] autorelease];
        [d setObject:[[[NSDictionary alloc] init] autorelease] forKey:@"settings"];
        prefs = d;
    }
    NSDictionary *db = [self editNestedDict:prefs setObject:object forKeyHierarchy:[NSArray arrayWithObjects:@"settings",key,nil]];
    [defaults setObject:db forKey:PLUGIN_NAME_STRING];        
    [defaults synchronize];
}

-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy{
    if (dict == nil) return dict;
    if (![dict isKindOfClass:[NSDictionary class]]) return dict;    
    NSMutableDictionary *parent = [[dict mutableCopy] autorelease];
    
    //drill down mutating each dict along the way
    NSMutableArray *structure = [NSMutableArray arrayWithCapacity:1];    
    NSMutableDictionary *prev = parent;
    for (id key in hierarchy) {
        if (key != [hierarchy lastObject]) {
            prev = [[[prev objectForKey:key] mutableCopy] autorelease];                            
            if (![prev isKindOfClass:[NSDictionary class]]) return dict;              
            [structure addObject:prev];
            //NSLog(@"loading %@",key); 
        }else{
            //NSLog(@"changing %@",key);
        }
    }   
    
    //do the change
    [[structure lastObject] setObject:object forKey:[hierarchy lastObject]];    
    
    //drill back up saving the changes each step along the way   
    for (int c = [structure count]-1; c >= 0; c--) {
        if (c == 0) {
            [parent setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }else{
            [[structure objectAtIndex:c-1] setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }
        //NSLog(@"saving %@",[hierarchy objectAtIndex:c]);        
    }
    
    return parent;
}

#pragma mark actions

-(IBAction) startToggle:(id)sender{
	if ([sender selectedSegment] == 1){
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"autoStart"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"AutostartON" userInfo:nil];;
		//NSLog(@"autostart on");
	}else {
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"autoStart"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"AutostartOFF" userInfo:nil];	
		//NSLog(@"autostart off");
	}	
}

-(IBAction) dockToggle:(id)sender{
	if ([sender selectedSegment] == 1){
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"hideDock"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"doRestart"];		
		//NSLog(@"dock icon hiden");
	}else {
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"hideDock"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"doRestart"];		
		//NSLog(@"dock icon shown");
	}	
}

#pragma mark timer

- (void)timerMove:(NSTimer*)theTimer{    
    int factor = [timerLevel tag];
    float notch = 1.0/factor;
    [timerLevel setDoubleValue:[timerLevel doubleValue]+notch];        
    [refreshLabel setStringValue:[self refreshTimeInterval:([timerLevel maxValue]*factor)-[timerLevel doubleValue]/notch]];    
}

- (void)timerReset:(NSTimer*)theTimer{
    [timerLevel setDoubleValue:0.0];        
}

-(NSString*)refreshTimeInterval:(double)time{
	NSString *ret = @"";
	
	if (time > 60) {
        int minutes = (int)time/60;
		ret = [NSString stringWithFormat:@"refresh in %i:%i",minutes,(int)time-(minutes*60)];	
	}else if (time > 0){
		ret = [NSString stringWithFormat:@"refresh in %is",(int)time];	        
    }else{
		ret = @"refreshing";	                
    }
	return ret;
}

@end
