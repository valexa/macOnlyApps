//
//  DiskFailurePreferences.m
//  DiskFailure
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "DiskFailurePreferences.h"

//this runs under the standalone or System Preferences, standardUserDefaults must be give a domain

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define OBSERVER_NAME_STRING @"MPPluginDiskFailurePreferencesEvent"
    #define MAIN_OBSERVER_NAME_STRING @"MPPluginDiskFailureEvent"
    #define PREFS_PLIST_DOMAIN @"com.vladalexa.MagicPrefs.MagicPrefsPlugins"
    #define TABLE_HEIGHT 240
#else
    #define OBSERVER_NAME_STRING @"VADiskFailurePreferencesEvent"
    #define MAIN_OBSERVER_NAME_STRING @"VADiskFailureEvent"
    #define PREFS_PLIST_DOMAIN @"com.vladalexa.diskfailure"
    #define TABLE_HEIGHT 295
#endif

#define PLUGIN_NAME_STRING @"DiskFailure"


@implementation DiskFailurePreferences

- (void)loadView {
    [super loadView];
		
    [theTable setRowHeight:32];
    
    NSView *scroll = [[theTable superview] superview]; 
    [scroll setFrame:NSMakeRect(0,0,340,TABLE_HEIGHT)];
    
    theList = [[NSMutableArray alloc] init];
    
    //register for notifications
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];    
	
    [self getData];    

}

-(void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
    [theList release];
    [super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{		
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doRefresh"]){
            [self getData];
            [theTable reloadData]; 
		}
	}	
}

-(void)getData{
    [theList removeAllObjects];
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];	

    for (NSDictionary *dict in [settings objectForKey:@"disks"]) {
        if ([[dict objectForKey:@"connected"] boolValue] != YES) continue;
        NSString *sleeping;
        if ([[dict objectForKey:@"sleeping"] boolValue] == YES) {
            sleeping = @"YES";
        }else{
            sleeping = @"NO";            
        }        
        NSString *name = [dict objectForKey:@"name"];
        NSString *read = [dict objectForKey:@"read"];
        NSString *write = [dict objectForKey:@"write"];
        NSString *lifeRead = [dict objectForKey:@"lifeRead"];
        NSString *lifeWrite = [dict objectForKey:@"lifeWrite"];        
        NSString *smart = [dict objectForKey:@"smart"];
        NSString *badSectors = [dict objectForKey:@"badSectors"];
        NSString *loadCycles = [dict objectForKey:@"loadCycles"];         
        NSString *startStops = [dict objectForKey:@"startStops"];                 
        NSString *temp = [dict objectForKey:@"temp"];
        NSString *highestTemp = [dict objectForKey:@"highestTemp"];        
        NSDate *date = [dict objectForKey:@"lastCheck"]; 
        int readOperations = [[dict objectForKey:@"readOperations"] intValue];
        int readLatency = [[dict objectForKey:@"readLatency"] intValue]; 
        int writeLatency = [[dict objectForKey:@"writeLatency"] intValue];        
        NSImage *icon = nil;
        if ([[dict objectForKey:@"type"] isEqualToString:@"SSD"]){
            if ([read intValue] > 0 || [write intValue] > 0 || [lifeRead intValue] > 1000 || [lifeWrite intValue] > 1000 || [smart isEqualToString:@"Failing"] || [badSectors intValue] > 1000 || [temp intValue] > 68) {
                icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"failing.pdf"]] autorelease];
            }else{
                icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ok.pdf"]] autorelease];
            }            
        }else{
            if ([read intValue] > 0 || [write intValue] > 0 || [lifeRead intValue] > 100 || [lifeWrite intValue] > 100 || [smart isEqualToString:@"Failing"] || [badSectors intValue] > 10 || [temp intValue] > 68 || [loadCycles intValue] > 500000 || [startStops intValue] > 5000 ) {
                icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"failing.pdf"]] autorelease];
            }else if ( readOperations == 0 || readLatency != 0 || writeLatency != 0) {
                icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"unsure.pdf"]] autorelease];                
            }else{    
                icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ok.pdf"]] autorelease];
            }            
        }
        [theList addObject:[NSDictionary dictionaryWithObjectsAndKeys:sleeping,@"sleeping",
                            name,@"name",icon,@"icon",
                            read,@"read",write,@"write",
                            lifeRead,@"lifeRead",lifeWrite,@"lifeWrite",
                            smart,@"smart",badSectors,@"badSectors",loadCycles,@"loadCycles",startStops,@"startStops",                            
                            temp,@"temp",highestTemp,@"highestTemp",[self humanizeDate:date],@"date",
                            nil]];
    }

}

#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [theList count];	
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
    NSDictionary *item = [theList objectAtIndex:rowIndex];  
	NSString *ident = [theColumn identifier]; 
    NSString *ret = [item objectForKey:ident];
    
    if ([ret isKindOfClass:[NSString class]]){
        NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];                
        
        //make gray if sleeping    
        if ([[item objectForKey:@"sleeping"] isEqualToString:@"YES"]) {
            [attrsDictionary setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];                     
        }     
        
        ret = [[[NSAttributedString alloc] initWithString:ret attributes:attrsDictionary] autorelease];       
    }  
        
    return ret;
}

#pragma mark tools

-(NSString*)humanizeCount:(NSString*)count{
    int c = [count intValue];
    if (c > 1000){
        count = [NSString stringWithFormat:@"%ik",c/1000];
    }
    if (c > 1000000){
        count = [NSString stringWithFormat:@"%.1fm",c/1000000.0];
    }        
    if (c > 1000000000){
        count = [NSString stringWithFormat:@"%.1fb",c/1000000000.0];
    }        
    return count;
}

-(NSString*)humanizeDate:(NSDate*)date{
    return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
}

@end

@implementation NSColor (StringOverrides)

+(NSArray *)controlAlternatingRowBackgroundColors{
	return [NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0],[NSColor whiteColor],nil];
}

@end
