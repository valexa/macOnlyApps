//
//  DiskFailureMainCore.m
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiskFailureMainCore.h"

#import "SMARTQuery.h"

#include <IOKit/storage/IOStorage.h>
#include <IOKit/storage/ata/ATASMARTLib.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
#include <IOKit/firewire/IOFireWireLib.h>
#include <IOKit/usb/IOUSBLib.h>

//this runs under the plugins host, no changes to prefs saving code required assuming structure is same

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define OBSERVER_NAME_STRING @"MPPluginDiskFailureEvent"
    #define PREF_OBSERVER_NAME_STRING @"MPPluginDiskFailurePreferencesEvent"
#else
    #define OBSERVER_NAME_STRING @"VADiskFailureEvent"
    #define PREF_OBSERVER_NAME_STRING @"VADiskFailurePreferencesEvent"
#endif

#define MENUBAR_OBSERVER_NAME_STRING @"VADiskFailureMenuBarEvent"
#define APP_OBSERVER_NAME_STRING @"VADiskFailureEvent"
#define PLUGIN_NAME_STRING @"DiskFailure"

@implementation DiskFailureMainCore

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
		//register with growl
		NSArray *arr = [NSArray arrayWithObject:@"DiskFailureGrowlNotif"]; 	
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlApplicationRegistrationNotification" object:nil userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"DiskFailure",@"ApplicationName",
		  arr,@"AllNotifications",
		  arr,@"DefaultNotifications",
		  nil]
		 ];	        
        
		//init defaults
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//listen for events
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	
        
		//set first run value settings
        NSString *frequency;
        frequency = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"checkFrequency"];        
		if (frequency == nil){
            frequency = @"660";            
			[self saveSetting:frequency forKey:@"checkFrequency"];
        }
        
        //check it is not too low
        if ([frequency intValue] < 660){            
            NSLog(@"%@ frequency too high, prevents drives from sleeping, resetting to 660",frequency);
            frequency = @"660"; 
			[self saveSetting:frequency forKey:@"checkFrequency"];
        }    
        
        //schedule run
        [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(timerLoop:) userInfo:nil repeats:YES];         

    }
    
    return self;
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
    [super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{			
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){			
        
	}			
}

-(void)timerLoop:(id)sender{
     [[NSDistributedNotificationCenter defaultCenter] postNotificationName:APP_OBSERVER_NAME_STRING object:nil userInfo:
     [NSDictionary dictionaryWithObjectsAndKeys:@"showModal",@"what",@"Refreshing, please wait.",@"text", nil]
     ];     
    [self doCheck:nil];         
     [[NSDistributedNotificationCenter defaultCenter] postNotificationName:APP_OBSERVER_NAME_STRING object:@"dismissModal" userInfo:nil];    
}

#pragma mark core

-(void)saveSetting:(id)object forKey:(NSString*)key{   
    //this is the method for when the host application is not SytemPreferences (MagicPrefsPlugins or your standalone)    
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return;
	}       
    NSDictionary *prefs = [defaults objectForKey:PLUGIN_NAME_STRING];
    if (prefs == nil) prefs = [NSDictionary dictionary];
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

-(NSArray*)mergePrefs:(NSArray*)newDisks{
    
    NSMutableArray *ret = [newDisks mutableCopy];
    
    NSMutableArray *old = [[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"disks"] mutableCopy];    
    if (old == nil) old = [[NSMutableArray alloc] init];    
    for (NSDictionary *old_disk in old) {
        BOOL matched = NO;
        NSString *old_name = [old_disk objectForKey:@"name"];
        NSString *old_bsd = [old_disk objectForKey:@"bsd"];
        NSString *old_serial = [old_disk objectForKey:@"serial"];        
        for (NSDictionary *new_disk in newDisks) {
            NSString *new_name = [new_disk objectForKey:@"name"];
            NSString *new_bsd = [new_disk objectForKey:@"bsd"];  
            if ([old_name isEqualToString:new_name] && [old_bsd isEqualToString:new_bsd]) {
                matched = YES;
            } 
            NSString *new_serial = [new_disk objectForKey:@"serial"];            
            if ([old_serial isEqualToString:new_serial] && new_serial != nil && ![new_serial isEqualToString:@"N/A"]) {
                matched = YES;                
            }
        } 
        if (matched == NO) {
            //set value of connected to NO and add to ret        
            NSMutableDictionary *mutable = [old_disk mutableCopy];
            [mutable setObject:[NSNumber numberWithBool:NO] forKey:@"connected"];
            [ret addObject:mutable];
            [mutable release];
            continue;
        }
    } 
    [old release];
    
    return [ret autorelease];    
} 

-(NSDictionary*)processData:(NSDictionary*)dict{
    
    //NSLog(@"%@",dict);     
    
    NSString *name = nil;
    if ([[dict objectForKey:@"Physical Interconnect Location"] isEqualToString:@"External"]) {
        name = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"Vendor Name"],[dict objectForKey:@"Product Name"]];
        if ([[dict objectForKey:@"smart"] boolValue] == YES) {
            NSLog(@"Incredible, external drive %@ has SMART support, please contact the developer with these great news.",name);
        }        
    }else{
        name = [dict objectForKey:@"Product Name"];
    }
    
    if (name == nil) {
        NSLog(@"Failed to determine name from %@",dict);
        return nil;
    }else{
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //NSLog(@"Found %@",name);
    }
    
    NSString *serial = [[dict objectForKey:@"Serial Number"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];    
    if (serial == nil) serial = @"N/A";
    
    if (![[dict objectForKey:@"Physical Interconnect"] isEqualToString:[dict objectForKey:@"interface"]]) {
        NSLog(@"Type inconsistency: %@ vs %@ for %@",[dict objectForKey:@"Physical Interconnect"],[dict objectForKey:@"interface"],name);
    }    
    
    NSString *type = @"Unknown";
    if ([[dict objectForKey:@"Medium Type"] isEqualToString:@"Rotational"]) {
        type = @"HDD";
    }
    if ([[dict objectForKey:@"Medium Type"] isEqualToString:@"Solid State"]) {
        type = @"SSD";
    }
    
    NSDictionary *cache = [self cacheForDevice:name bsd:[dict objectForKey:@"bsd"] serial:serial]; 
    
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:1]; 
                
    [newDict setObject:[NSNumber numberWithBool:YES] forKey:@"connected"];
    [newDict setObject:[NSDate date] forKey:@"lastCheck"];
    [newDict setObject:name forKey:@"name"];
    [newDict setObject:[dict objectForKey:@"bsd"] forKey:@"bsd"];
    [newDict setObject:[dict objectForKey:@"interface"] forKey:@"interface"];
    [newDict setObject:type forKey:@"type"];
    [newDict setObject:serial forKey:@"serial"];    
        
    [newDict setObject:[[dict objectForKey:@"Errors (Read)"] stringValue] forKey:@"read"];    
    [newDict setObject:[[dict objectForKey:@"Errors (Write)"] stringValue] forKey:@"write"];    
    int lifeRead = [[dict objectForKey:@"Errors (Read)"] intValue] + [[cache objectForKey:@"lifeRead"] intValue];
    int lifeWrite = [[dict objectForKey:@"Errors (Write)"] intValue] + [[cache objectForKey:@"lifeWrite"] intValue];   
    [newDict setObject:[NSString stringWithFormat:@"%i",lifeRead] forKey:@"lifeRead"];    
    [newDict setObject:[NSString stringWithFormat:@"%i",lifeWrite] forKey:@"lifeWrite"]; 
    
    [newDict setObject:[[dict objectForKey:@"Operations (Read)"] stringValue] forKey:@"readOperations"];    
    [newDict setObject:[[dict objectForKey:@"Operations (Write)"] stringValue] forKey:@"writeOperations"];  
    [newDict setObject:[[dict objectForKey:@"Latency Time (Read)"] stringValue] forKey:@"readLatency"];    
    [newDict setObject:[[dict objectForKey:@"Latency Time (Write)"] stringValue] forKey:@"writeLatency"];   
    
    
    uint64_t diff = [[dict objectForKey:@"TimeSinceDeviceIdle"] intValue] / 1000ULL;    
    NSDate *lastIdle = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)diff*-1];
    if (lastIdle)  [newDict setObject:lastIdle forKey:@"lastIdle"];
    [newDict setObject:[dict objectForKey:@"sleeping"] forKey:@"sleeping"];
    [newDict setObject:[NSString stringWithFormat:@"%lld",[[dict objectForKey:@"IdleTimerPeriod"] intValue] / 1000ULL] forKey:@"sleepTimer"];    
    
    //these are used by the smart step
    [newDict setObject:[dict objectForKey:@"smartCapable"] forKey:@"smartCapable"];        
    [newDict setObject:[dict objectForKey:@"iopath"] forKey:@"iopath"];
    
    //NSLog(@"%@",newDict); 
    
    [self doNotifications:newDict]; //notify before saving the new data
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MENUBAR_OBSERVER_NAME_STRING object:@"refreshIcon" userInfo:nil];	    
    return newDict;
    
}

-(NSDictionary*)cacheForDevice:(NSString*)name bsd:(NSString*)bsd serial:(NSString*)serial{
    NSArray *disks = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"disks"];        
    if (serial != nil && ![serial isEqualToString:@"N/A"]) {
        for (NSDictionary *disk in disks) {
            NSString *s = [disk objectForKey:@"serial"];  
            if ([s isEqualToString:serial]) {
                return disk;
            }
        }
    }else{
        for (NSDictionary *disk in disks) {
            NSString *n = [disk objectForKey:@"name"];
            NSString *b = [disk objectForKey:@"bsd"];  
            if ([n isEqualToString:name] && [b isEqualToString:bsd]) {
                return disk;
            }
        }        
    }
    return nil;
}

-(NSString*)naIfNil:(id)object{
    if (object == nil) {        
        return @"N/A";
    }else{
        return [NSString stringWithFormat:@"%@",object];
    }        
    return @"ERR";
}

#pragma mark IO

-(void)doCheck:(id)sender{  
    
    [self saveSetting:[NSNumber numberWithBool:NO] forKey:@"redIcon"]; //set regular icon 
    [self saveSetting:[NSNumber numberWithBool:NO] forKey:@"litIcon"]; //set regular icon     
    
    NSMutableArray *newDevices = [NSMutableArray arrayWithCapacity:1];
        
	io_service_t root = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert"));    
    if (root) {
        io_iterator_t  iter;        
        // Create an iterator across all children of the root service object passed in.
        IORegistryEntryCreateIterator(root,kIOServicePlane,kIORegistryIterateRecursively,&iter);           
        if (iter){
            io_service_t service;            
            while ( ( service = IOIteratorNext( iter ) ) )  {
                if (service) {                                     
                    if ( IOObjectConformsTo( service, "IOBlockStorageDriver") ) {                                                
                        NSDictionary *data = [self parseIOBlockStorageDriver:service];
                        if (data != nil) {
                            [newDevices addObject:[self processData:data]];                            
                        }                        
                    }                    
                    IOObjectRelease(service);                        
                }                
            }
            IOObjectRelease(iter);            
        }else{
            NSLog(@"Error iterating AppleACPIPlatformExpert");        
        }  
        IOObjectRelease(root);        
    }else{
        NSLog(@"No AppleACPIPlatformExpert found");      
    }          
    
    //pool SMART outside of loop as not to block it
    BOOL forced = NO;
    if ([sender isKindOfClass:[NSString class]]) forced = YES;    
    NSMutableArray *pooledDevices = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *dict in newDevices) {
        [pooledDevices addObject:[self poolSmart:dict forced:forced]];
    }
    
    //merge with cached and save
    NSArray *merged = [self mergePrefs:pooledDevices];   
	[self saveSetting:merged forKey:@"disks"];   
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"doRefresh" userInfo:nil];	
}

-(NSDictionary*)poolSmart:(NSDictionary*)dict forced:(BOOL)forced{
     
    BOOL capable = [[dict objectForKey:@"smartCapable"] boolValue];    
    BOOL sleeping = [[dict objectForKey:@"sleeping"] boolValue];    
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:1];        
    NSDictionary *smartDict = nil;      
    NSString *smart = nil;        
    if (capable == YES) {         
        if (sleeping == YES && forced != YES) {
            //NSLog(@"Not querying SMART for disk while it is sleeping unless manual refresh");               
        }else{            
            const char *path = [[dict objectForKey:@"iopath"] UTF8String];            
            io_service_t service = IORegistryEntryFromPath(kIOMasterPortDefault,path);
            if (service) {
                smartDict = [SMARTQuery getSMARTData:service]; 
                sleeping = NO;//we woke it up if it was
                if ([[smartDict objectForKey:@"deviceOK"] intValue] == 1) {
                    smart = @"Verified";
                }else{
                    smart = @"Failing";
                }                
            }                  
        }                   
    }        
    
    NSDictionary *cache = [self cacheForDevice:[dict objectForKey:@"name"] bsd:[dict objectForKey:@"bsd"] serial:[dict objectForKey:@"serial"]];    
    if (smartDict == nil && ![[cache objectForKey:@"smart"] isEqualToString:@"N/A"] && cache != nil) {         
        [newDict addEntriesFromDictionary:cache]; //add the old ones so if smart check is skipped this time the old ones are not lost
    }else{
        [newDict setObject:[self naIfNil:smart] forKey:@"smart"];
        [newDict setObject:[self naIfNil:[smartDict objectForKey:@"LoadCycleCount"]] forKey:@"loadCycles"];  
        [newDict setObject:[self naIfNil:[smartDict objectForKey:@"StartStopCount"]] forKey:@"startStops"]; 
        [newDict setObject:[self naIfNil:[smartDict objectForKey:@"ReallocatedSectorsCount"]] forKey:@"badSectors"];    
        [newDict setObject:[self naIfNil:[smartDict objectForKey:@"Temp"]] forKey:@"temp"]; 
        if ([[smartDict objectForKey:@"Temp"] intValue] > [[cache objectForKey:@"highestTemp"] intValue] ) {         
            [newDict setObject:[self naIfNil:[smartDict objectForKey:@"Temp"]] forKey:@"highestTemp"];        
        }else if ([cache objectForKey:@"highestTemp"] == nil) {
            [newDict setObject:[self naIfNil:[smartDict objectForKey:@"Temp"]] forKey:@"highestTemp"];        
        }else{
            [newDict setObject:[cache objectForKey:@"highestTemp"] forKey:@"highestTemp"];
        }        
    }      
    
    [newDict addEntriesFromDictionary:dict];
    
    [newDict removeObjectForKey:@"iopath"];// dont need this anymore
    
    [newDict setObject:[NSNumber numberWithBool:sleeping] forKey:@"sleeping"];
    
    return newDict;     
}

-(NSDictionary*) parseIOBlockStorageDriver:(io_service_t)service{
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    //get details from itself
    NSDictionary *statistics = [self getDictForProperty:@"Statistics" device:service]; 
    [ret addEntriesFromDictionary:statistics];                        
    //get details from it's child
    io_service_t child;
    IORegistryEntryGetChildEntry(service,kIOServicePlane,&child);
    if (child) {
        NSString *bsd = [self getStringForProperty:@"BSD Name" device:child];
        if (bsd == nil) {
            IOObjectRelease(child);
            //NSLog(@"Device skiped, no bsd mount point");
            return nil; //no bsd mount point = no media = card reader or something
        }                       
        IOObjectRelease(child);
        [ret setObject:bsd forKey:@"bsd"];
    }else{
        //NSLog(@"Device skiped, no children");        
        return nil; //no child
    }                        
    //get details from it's parent                        
    io_service_t parent;
    IORegistryEntryGetParentEntry(service,kIOServicePlane,&parent);
    if (parent) {
        NSString *interface = [self interfaceType:parent];
        if (interface == nil) {
            IOObjectRelease(parent);
            //NSLog(@"Device skiped, not a known disk");             
            return nil; //not a known disk
        }
        NSDictionary *pcharacteristics = [self getDictForProperty:@"Protocol Characteristics" device:parent];
        NSDictionary *dcharacteristics = [self getDictForProperty:@"Device Characteristics" device:parent];                                                       
        NSDictionary *powerstatus = [self getPower:parent interface:interface]; //get power details from parent of parent
        NSString *path = [self getPathAsStringFor:parent];        
        BOOL capable = [self isSmartCapable:parent];
        BOOL sleeping = [self isSleeping:powerstatus];  
        IOObjectRelease(parent);
        [ret setObject:path forKey:@"iopath"];        
        [ret setObject:interface forKey:@"interface"];
        [ret setObject:[NSNumber numberWithBool:capable] forKey:@"smartCapable"];
        [ret setObject:[NSNumber numberWithBool:sleeping] forKey:@"sleeping"];         
        [ret addEntriesFromDictionary:pcharacteristics];
        [ret addEntriesFromDictionary:dcharacteristics];
        [ret addEntriesFromDictionary:powerstatus];         
    }else{
        //NSLog(@"Device skiped, no parent");        
        return nil; //no parent
    }  

    return ret;
    
}

-(NSString*)getPathAsStringFor:(io_service_t)service{
    io_string_t   devicePath;
    if (IORegistryEntryGetPath(service, kIOServicePlane, devicePath) == KERN_SUCCESS)    {
        return [NSString stringWithFormat:@"%s",&devicePath];
    }else{
        NSLog(@"Error getting path");
    }
    return nil;
}

-(NSDictionary*)getPower:(io_service_t)root interface:(NSString*)interface{  
    NSDictionary *ret = nil;
    if ([interface isEqualToString:@"USB"] || [interface isEqualToString:@"FireWire"]) {
        io_service_t parent;
        IORegistryEntryGetParentEntry(root,kIOServicePlane,&parent);
        if (parent) {  
            ret = [self getDictForProperty:@"IOPowerManagement" device:parent];            
            IOObjectRelease(parent);            
        }    
        if (ret == nil) NSLog(@"ERROR getting power management info for %@ device",interface);        
    }else if ([interface isEqualToString:@"SATA"]){
        io_iterator_t  iter;        
        // Create an iterator across all parents of object passed in
        IORegistryEntryCreateIterator(root,kIOServicePlane,kIORegistryIterateParents|kIORegistryIterateRecursively,&iter);          
        if (iter){
            io_service_t service;            
            while ( ( service = IOIteratorNext( iter ) ) )  {
                if (service) {
                    if ( IOObjectConformsTo( service, "AppleAHCIPort") ) {                    
                        //descend into IOPowerConnection/AppleAHCIDiskQueueManager                        
                        io_service_t child;
                        IORegistryEntryGetChildEntry(service,kIOPowerPlane,&child);
                        if (child) {               
                            io_service_t childofchild;
                            IORegistryEntryGetChildEntry(child,kIOPowerPlane,&childofchild);
                            if (childofchild) {
                                ret = [self getDictForProperty:@"IOPowerManagement" device:childofchild];                                            
                                IOObjectRelease( childofchild );   
                            }  
                            IOObjectRelease( child );                            
                        }  
                    }   
                    IOObjectRelease( service );
                }                
            }
            IOObjectRelease( iter );            
        }else{
            NSLog(@"Error iterating root for %@ device",interface);        
        }  
        if (ret == nil) NSLog(@"ERROR getting power management info for %@ device",interface);
    }else{
        NSLog(@"Power management info is not supported for %@ device",interface);
    } 
    return ret;
}

-(NSString*)interfaceType:(io_service_t)device{
    if (IOObjectConformsTo(device,"IOATABlockStorageDevice")) return @"ATA";    
    if (IOObjectConformsTo(device,"IOAHCIBlockStorageDevice")) return @"SATA"; 
    if (IOObjectConformsTo(device,"IOBlockStorageServices")) return @"USB"; //IOSCSIPeripheralDeviceType00
    if (IOObjectConformsTo(device,"IOReducedBlockServices")) return @"FireWire"; //IOSCSIPeripheralDeviceType0E
    CFStringRef class = IOObjectCopyClass(device);
    if (class) {
        NSLog(@"Unknown device type %@",(NSString*)class);
        CFRelease(class);
    }
    return nil;
}

-(BOOL)isSleeping:(NSDictionary*)dict{ 
    //first check if IdleTimerPeriod is not biger than checkFrequency
    int64_t checkFrequency = [[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"checkFrequency"] intValue];    
    int64_t IdleTimerPeriod = [[dict objectForKey:@"IdleTimerPeriod"] intValue] / 1000ULL;
    if (IdleTimerPeriod > checkFrequency && [[dict objectForKey:@"DevicePowerState"] intValue] > 1) {
        NSLog(@"Drive is not sleeping and checkFrequency %lld is higher than IdleTimerPeriod %lld, will lie about the drive being asleep as to not prevent it from falling asleep",checkFrequency,IdleTimerPeriod);
        return YES;
    }
    //actual check
    if ([[dict objectForKey:@"DevicePowerState"] intValue] > 1) {
        return NO;
    }else{
        return YES;    
    }
    return NO;
}

-(BOOL)isSmartCapable:(io_service_t)device{    
    BOOL ret = NO;    
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, CFSTR("SMART Capable"), kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        ret = CFBooleanGetValue(theCFProperty) ? YES : NO;
        CFRelease(theCFProperty);
    }       
    return ret;
}

- (NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device{
	NSDictionary *ret = nil;		
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        if (CFGetTypeID(theCFProperty) != CFDictionaryGetTypeID()){
            NSLog(@"Value for %@ is not a dict",propertyName);                    
        }else{
            ret = [NSDictionary dictionaryWithDictionary:(NSDictionary *)theCFProperty];
        }        
        CFRelease(theCFProperty);           
	}else{
        NSLog(@"Could not get %@",propertyName);
    }    
	return ret;
}

- (NSString*)getStringForProperty:(NSString*)propertyName device:(io_service_t)device{
	NSString *ret = nil;    
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        if (CFGetTypeID(theCFProperty) != CFStringGetTypeID()){
            NSLog(@"Value for %@ is not a string",propertyName);                    
        }else{
            ret = [NSString stringWithString:(NSString*)theCFProperty];            
        }
        CFRelease(theCFProperty);            
	}else{
        NSLog(@"Could not get %@",propertyName);
    }    
	return ret;
}

- (int)getIntForProperty:(NSString*)propertyName device:(io_service_t)device{
	int ret = 0;    
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        if (CFGetTypeID(theCFProperty) != CFNumberGetTypeID()){
            NSLog(@"Value for %@ is not a number",propertyName);                    
        }else{
            CFNumberGetValue(theCFProperty, kCFNumberIntType,&ret);
        }   
        CFRelease(theCFProperty);            
	}else{
        NSLog(@"Could not get %@",propertyName);
    }    
	return ret;
}

-(int64_t)machineIdleTime{
    int64_t idlesecs = -1;
    io_iterator_t iter = 0;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHIDSystem"), &iter) == KERN_SUCCESS) {
        io_registry_entry_t entry = IOIteratorNext(iter);
        if (entry) {
            CFMutableDictionaryRef dict = NULL;
            if (IORegistryEntryCreateCFProperties(entry, &dict, kCFAllocatorDefault, 0) == KERN_SUCCESS) {
                CFNumberRef obj = CFDictionaryGetValue(dict, CFSTR("HIDIdleTime"));
                if (obj) {
                    int64_t nanoseconds = 0;
                    if (CFNumberGetValue(obj, kCFNumberSInt64Type, &nanoseconds)) {
                        idlesecs = nanoseconds / 1000ULL;
                    }
                }
                CFRelease(dict);
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(iter);
    }
    return idlesecs;
}


#pragma mark notifs

-(void)doNotifications:(NSDictionary*)dict{
    NSString *bsd = [dict objectForKey:@"bsd"];    
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
    NSDictionary *cache = [self cacheForDevice:name bsd:bsd serial:[dict objectForKey:@"serial"]];         
    int readOperations = [[dict objectForKey:@"readOperations"] intValue];
    int writeOperations =  [[dict objectForKey:@"writeOperations"] intValue];
    int readLatency = [[dict objectForKey:@"readLatency"] intValue]; 
    int writeLatency = [[dict objectForKey:@"writeLatency"] intValue];
    
    if ([[dict objectForKey:@"type"] isEqualToString:@"SSD"]){
        //for SSD
        if ([read intValue] > 0 || [write intValue] > 0 || [lifeRead intValue] > 1000 || [lifeWrite intValue] > 1000 || [smart isEqualToString:@"Failing"] || [badSectors intValue] > 1000 || [temp intValue] > 68) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"redIcon"]; //set red icon
        }   
        if ( readOperations == 0 || readLatency != 0 || writeLatency != 0) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"litIcon"]; //lit icon
        }         
    }else{
        //for rest
        if ([read intValue] > 0 || [write intValue] > 0 || [lifeRead intValue] > 100 || [lifeWrite intValue] > 100 || [smart isEqualToString:@"Failing"] || [badSectors intValue] > 10 || [temp intValue] > 68 || [loadCycles intValue] > 500000 || [startStops intValue] > 5000 ) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"redIcon"]; //set red icon
        }     
        if ( readOperations == 0 || readLatency != 0 || writeLatency != 0) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"litIcon"]; //lit icon
        }                 
        if ([loadCycles intValue] == 500000 || [loadCycles intValue] == 410000 || [loadCycles intValue] == 420000 || [loadCycles intValue] == 430000  || [loadCycles intValue] == 440000 || [loadCycles intValue] == 450000 || [loadCycles intValue] == 460000 || [loadCycles intValue] == 470000 || [loadCycles intValue] == 480000 || [loadCycles intValue] == 490000){
            NSString *title = [NSString stringWithFormat:@"Disk %@ load cycles nearing maximum.",name];
            NSString *desc = @"Typically a drive is near the end of it's life if it nears 500000, this value is incremented every time the drive parks it's needles.";
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
        }   
        if ([startStops intValue] == 5000 || [startStops intValue] == 4100 || [startStops intValue] == 4200 || [startStops intValue] == 4300  || [startStops intValue] == 4400 || [startStops intValue] == 4500 || [startStops intValue] == 4600 || [startStops intValue] == 4700 || [startStops intValue] == 4800 || [startStops intValue] == 4900){
            NSString *title = [NSString stringWithFormat:@"Disk %@ start/stops nearing maximum.",name];
            NSString *desc = @"Typically a drive is near the end of it's life if it nears 5000, this value is incremented every time the drive spins up/down.";
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
        }        
    }   
    //for all
    int readwrite = [read intValue]+[write intValue];
    if ( readwrite > 0){
        if ( readwrite > 0 && readwrite == ([lifeRead intValue]+[lifeWrite intValue])){
            NSString *title = [NSString stringWithFormat:@"Disk %@ experiencing read/write errors.",name];
            NSString *desc = @"This is a strong indicator for iminent failure and was detected for the first time on this drive.";                
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
            [self showAlert:desc title:title];                
        } else {
            NSString *title = [NSString stringWithFormat:@"Disk %@ experiencing read/write errors.",name];
            NSString *desc = @"This is a strong indicator for iminent failure and it is not the first time this drive is experiencing it.";                
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];                
        }           
    }
    if ([temp intValue] > 68 && [temp intValue] > [[cache objectForKey:@"highestTemp"] intValue]){
        NSString *title = [NSString stringWithFormat:@"Disk %@ temperature over 68°C/155°F.",name];
        NSString *desc = @"This is above recomended operating temperature and there is strong evidence that it can lead to degradation of the drive.";
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
        [self showAlert:desc title:title];
    }
    if ([smart isEqualToString:@"Failing"] && [[cache objectForKey:@"smart"] isEqualToString:@"Verified"]){
        NSString *title = [NSString stringWithFormat:@"Disk %@ SMART status changed to failing.",name];
        NSString *desc = @"This means the drive is reporting one or more conditions have exceeded normal values which means imminent failure.";
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
        [self showAlert:desc title:title];
    }  
    int newBads  = [badSectors intValue] - [[cache objectForKey:@"badSectors"] intValue];
    if (newBads > 0){
        if ([[cache objectForKey:@"badSectors"] intValue] == 0) {
            NSString *title = [NSString stringWithFormat:@"Disk %@ reporting %i bad sectors.",name,newBads];
            NSString *desc = @"This is a strong indicator for iminent failure and was detected for the first time on this drive.";                
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
            [self showAlert:desc title:title];             
        }else{
            NSString *title = [NSString stringWithFormat:@"Disk %@ reporting %i new bad sectors.",name,newBads];
            NSString *desc = @"This is a strong indicator for iminent failure and it is not the first time this drive is experiencing it.";               
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];            
        }
    }else if (newBads < 0){
        NSString *title = [NSString stringWithFormat:@"Disk %@ count of bad sectors decreased by %i.",name,newBads*-1];
        NSString *desc = @"The disk could genuinely have succeeded to recover previously corrupted areas or had them marked in error to begin with.";
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
        [self showAlert:desc title:title];        
    }
    //these ones are less definitive
    if ( readOperations == 0 ){
        NSString *title = [NSString stringWithFormat:@"Disk %@ reports zero read operations.",name];
        NSString *desc = @"This could signal drive failure, typically even drives without partitions are read for low level information.";                
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];              
    }
    if ( writeOperations == 0 ){
        NSString *title = [NSString stringWithFormat:@"Disk %@ reports zero write operations.",name];
        NSString *desc = @"This could be fine if the disk has no partitions or they are mounted read only, otherwise it could signal drive failure.";                
        NSLog(@"%@,%@",title,desc);        
    }   
    if ( readLatency != 0 || writeLatency != 0 ){
        NSString *title = [NSString stringWithFormat:@"Disk %@ reports latency (%i/read %i/write).",name,readLatency,writeLatency];
        NSString *desc = @"This is not a definitive indication of probelms but it should not normally hapen on healthy drives.";                
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];              
    }    
}

-(void)sendGrowlNotification:(NSString*)desc title:(NSString*)title{
    NSLog(@"Notified with growl:%@,%@",title,desc);
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlNotification" object:nil userInfo:
     [NSDictionary dictionaryWithObjectsAndKeys:@"DiskFailure",@"ApplicationName",@"DiskFailureGrowlNotif",@"NotificationName",
      title,@"NotificationTitle",
      desc,@"NotificationDescription",
      nil]
     ];	
}

-(void)showAlert:(NSString*)desc title:(NSString*)title{
    if (desc == nil) {
        NSLog(@"Empty alert %@",title);
        desc = @"";        
    }
    NSAlert *alert =[NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:desc];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal]; 
}

@end
