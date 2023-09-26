//
//  LogsController.m
//  DiskFailure
//
//  Created by Vlad Alexa on 2/21/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "LogsController.h"
#import "CloudController.h"

#include <DiskArbitration/DASession.h>

@implementation LogsController

-(void)awakeFromNib
{
    list = [[NSMutableArray alloc] init];
    listSearch = [[NSMutableArray alloc] init];    
    searchTimer = nil; 
    
    [self getData];
    [theTable expandItem:[theTable itemAtRow:0]];    
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"LogsController" object:nil];	     
    
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];     
    [super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{		
	if (![[notif name] isEqualToString:@"LogsController"]) {
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doRefresh"]){
            [self getData];
            [theTable reloadData]; 
		}        
		if ([[notif object] isEqualToString:@"switchToAll"]){
            [theTable collapseItem:[theTable itemAtRow:0]];             
            allMachines = YES;
            [self getData];
            [theTable reloadData];          
		}        
		if ([[notif object] isEqualToString:@"switchToThis"]){
            allMachines = NO;            
            [self getData];
            [theTable reloadData];            
            [theTable expandItem:[theTable itemAtRow:0]];           
		}                
	}	
}

-(void)getData
{
    [list removeAllObjects];
    NSURL *url;
    if ([cloudController isiCloudAvailable]) {
        url = [cloudController getiCloudURLFor:@"sharedData.plist" containerID:nil];            
    }else{
        //we are running unsandboxed or on 10.6, use hardcoded path        
        url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/Users/%@/Library/Containers/com.vladalexa.diskfailure/Data/Documents/sharedData.plist",NSUserName()]];
    }
    
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:url];
    NSDictionary *dict = [plist objectForKey:@"logs"];    
    for (NSString *key in dict) {
        if (allMachines == NO) {
            if (![key isEqualToString:[self machineSerial]]) continue;
        }
        NSArray *logs = [dict objectForKey:key];
        [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:key,@"root",logs,@"log", nil]];
    }     
}

-(NSString *)hostName
{
    //also in /Library/Preferences/SystemConfiguration/preferences.plist, System>Network>Hostnames "LocalHostName" , System>System "ComputerName" and System>System "HostName" which is optional and has .local apended
    
    char hostname[100];
	gethostname(hostname, 99);
    NSMutableString *ret = [NSMutableString stringWithCapacity:1];
    [ret setString:[NSString stringWithCString:hostname encoding:NSUTF8StringEncoding]];
    if ([ret length] > 6) {
        [ret replaceOccurrencesOfString:@".local" withString:@"" options:0 range:NSMakeRange([ret length]-6,6)];        
    }
    return ret;
}

-(NSString *)machineSerial
{
	NSString *ret = nil;
	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));			
	if (platformExpert) {
		CFTypeRef cfstring = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault, 0);
        if (cfstring) {
            ret = [NSString stringWithFormat:@"%@",cfstring];        
            CFRelease(cfstring);                    
        }
		IOObjectRelease(platformExpert);        
	}		
    return ret;  
}

- (NSString *) volumeNameWithBSDPath:(NSString *)bsdPath
{
    DASessionRef session;
    DADiskRef disk;
    NSDictionary *dd;
    NSString *volumeName;
    
    session = DASessionCreate(kCFAllocatorDefault);
    if (!session) return nil;
    
    disk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, [bsdPath UTF8String]);
    if (!disk) {
        CFRelease(session);
        return nil;
    }
    
    dd = (NSDictionary *) DADiskCopyDescription(disk);
    if (!dd) {
        CFRelease(session);
        CFRelease(disk);
        return nil;
    }
    
    volumeName = [[dd objectForKey:(NSString *)kDADiskDescriptionVolumeNameKey] copy];
    
    CFRelease(session);	
    CFRelease(disk);	
    [dd release];
    
    return [volumeName autorelease];
}

-(NSString*)bsdPathFromLog:(NSString*)line
{    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@": (disk\\d+s\\d+)" options:0 error:nil];
    NSArray *matches = [regex matchesInString:line options:0 range:NSMakeRange(0,[line length])];
    if ([matches count] > 0) {
        if ([[matches objectAtIndex:0] numberOfRanges] == 2) {
            //only return the first match
            return [line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
        }
    }
    
    return nil;
}

-(NSString*)machineFromLog:(NSArray*)log
{
    NSString *ret = nil;
    for (NSString *string in log) {
        NSArray *parts = [string componentsSeparatedByString:@" kernel[0]: "];
        if ([parts count] == 2) {
            NSArray *part = [[parts objectAtIndex:0] componentsSeparatedByString:@" "];
            NSString *machine = [part lastObject];            
            if (machine && ![machine isEqualToString:@"localhost"]) {
                ret = machine;
            }
        }
    }
    return ret;
}

#pragma mark ibactions

-(IBAction)performFindPanelAction:(id)sender // Called when the find command is invoked by the user
{
    NSLog(@"find");
    NSScrollView *scroll = (NSScrollView*)[[theTable superview] superview];    
    
    NSTextFinder *finder = [[[NSTextFinder alloc] init] autorelease];
    [finder setFindBarContainer:scroll];
    
    [scroll setFindBarVisible:YES];    
}

#pragma  mark NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{        
    if ([item isKindOfClass:[NSDictionary class]]) {
        return YES;        
    }else {
        return NO;
    }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{    
    
    if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        if ([searchString length] > 0) {         
            return [listSearch count];              
        }else{
            return [list count];              
        }    
    }   
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        return [[item objectForKey:@"log"] count];
    }
        
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    
	if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        if ([searchString length] > 0) {         
            return [listSearch objectAtIndex:index];             
        }else{
            return [list objectAtIndex:index];             
        }        
    }
         
    if ([item isKindOfClass:[NSDictionary class]]) {
        return [[item objectForKey:@"log"] objectAtIndex:index];
    }     
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item
{          

    if ([[theColumn identifier] isEqualToString:@"log"]) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            return [NSString stringWithFormat:@"%i matches",[[item objectForKey:@"log"] count]];
        }
        if ([item isKindOfClass:[NSString class]]) {
            NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];  
            if ([item rangeOfString:@"flushing fs disk buffer returned 0x5"].location != NSNotFound || 
                [item rangeOfString:@"replay_journal"].location != NSNotFound ||
                [item rangeOfString:@"journal replay done"].location != NSNotFound            
                ) [attrsDictionary setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];              
            if ([item rangeOfString:@"operation was aborted"].location != NSNotFound || //not jnl
                [item rangeOfString:@"do_jnl_io"].location != NSNotFound ||
                [item rangeOfString:@"I/O error"].location != NSNotFound ||  //not jnl
                [item rangeOfString:@"end_transaction:"].location != NSNotFound ||
                [item rangeOfString:@"DMA failure"].location != NSNotFound  //not jnl             
                ) [attrsDictionary setObject:[NSColor colorWithDeviceRed:0.7 green:0.0 blue:0.0 alpha:1.0] forKey:NSForegroundColorAttributeName];                                                  
            return [[[NSAttributedString alloc] initWithString:item attributes:attrsDictionary] autorelease];                      
        }        
        return item;
    }else{
        if ([item isKindOfClass:[NSDictionary class]]) {
            NSString *machineName = [self machineFromLog:[item objectForKey:@"log"]];
            if (machineName) {
                return machineName;
            }else {
                return [item objectForKey:@"root"];                                         
            }
        }  
        if ([item isKindOfClass:[NSString class]]) {                    
            if (allMachines == NO) return [self volumeNameWithBSDPath:[self bsdPathFromLog:item]];
        }         
    }
        
    return nil;
}

#pragma mark find

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    NSString *string = [[aNotification object] stringValue];
    if ([searchTimer isValid]) {
        [searchTimer invalidate];
        searchTimer = nil;
    }    
    searchTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(searchStart:) userInfo:string repeats:NO]; 
} 

-(void)searchStart:(NSTimer*)timer
{
    NSString *string = [timer userInfo];
    if ([string length] > 0) [listSearch setArray:[self filterList:list forString:string]];       
    searchString = string;    
    [theTable reloadData];    
    searchTimer = nil;    
}

-(NSArray*)filterList:(NSArray*)source forString:(NSString*)query
{        
    if ([query length] < 2) return source;
    
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *dict in source) {
        NSString *desc = [NSString stringWithFormat:@"%@",dict];
        if ([desc rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [ret addObject:dict];
        }           
    }    
    
    return ret;
}

@end
