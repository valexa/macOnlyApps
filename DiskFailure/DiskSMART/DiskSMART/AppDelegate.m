//
//  AppDelegate.m
//  DiskSMART
//
//  Created by Vlad Alexa on 1/27/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "AppDelegate.h"
#import "SMARTQuery.h"

#include <IOKit/storage/ata/ATASMARTLib.h>
#include <mach/mach_error.h>

#import "VAValidation.h"

@implementation AppDelegate

@synthesize window = _window;

- (id)init {
    self = [super init];
    if (self) {           
        theList = [[NSMutableArray alloc] init]; 
        
        int v = [VAValidation v];		
        if (v != 0)  {		
            exit(v);
        }else {	
            //ok to run
        }     
        
    }
    return self;
}

- (void)dealloc
{
    [theList release];
    [super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([self hasDiskFailure] == YES) {
        [theTable setRowHeight:48];     
        [self getAllDrives];           
        [theTable reloadData];        
    }else{
        [_window close];         
        [[NSAlert alertWithMessageText:@"DiskFailure was not found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This application is only for customers with DiskFailure."] runModal];                
    }    
}

-(BOOL)hasDiskFailure{
    
    NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.vladalexa.diskfailure"];
    
    if (url) {
        NSBundle *containerAppBundle = [NSBundle bundleWithURL:url];				   
        
        //check signature
        if ([VAValidation v:containerAppBundle] != 0)  {		
            //NSLog(@"Signature invalid for %@",url);
            return NO;
        }
        //check receipt
        if ([VAValidation a:containerAppBundle] != 0)  {		
            //NSLog(@"Receipt invalid for %@",url);
            return NO;
        }
    }else{
        //NSLog(@"Unable to find DiskFailure.");
        return NO;        
    }

	return YES;
}

-(void)getSmartDrives
{
	IOReturn				error 			= kIOReturnSuccess;
	NSMutableDictionary		*matchingDict	= [[NSMutableDictionary alloc] initWithCapacity:8];
	NSMutableDictionary 	*subDict		= [[NSMutableDictionary alloc] initWithCapacity:8];
	io_iterator_t			iter			= IO_OBJECT_NULL;
	io_object_t				obj				= IO_OBJECT_NULL;  
	
	[subDict setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithCString:kIOPropertySMARTCapableKey encoding:NSUTF8StringEncoding]];
	
	// Add the dictionary to the main dictionary with the key "IOPropertyMatch" to
	// narrow the search to the above dictionary.
	[matchingDict setObject:subDict forKey:[NSString stringWithCString:kIOPropertyMatchKey encoding:NSUTF8StringEncoding]];
	
	[subDict release];
	subDict = NULL;
    
	// Remember - this call eats one reference to the matching dictionary.  In this case, removing the need to release it later
	error = IOServiceGetMatchingServices (kIOMasterPortDefault, (CFDictionaryRef)matchingDict, &iter);
	if (error != kIOReturnSuccess) {
		NSLog(@"Error finding SMART Capable disks: %s(%x)\n", mach_error_string(error), error);
	} else {
		while ((obj = IOIteratorNext(iter)) != IO_OBJECT_NULL) {		
            [theList addObject:[SMARTQuery getSMARTData:obj]];
			IOObjectRelease(obj);
		}
	}    
}

-(void)getAllDrives
{   
	IOReturn				error 			= kIOReturnSuccess;
	NSMutableDictionary		*matchingDict	= [[NSMutableDictionary alloc] initWithCapacity:1];
	io_iterator_t			iter			= IO_OBJECT_NULL;
	io_object_t				obj				= IO_OBJECT_NULL;     
    
    matchingDict	= (NSMutableDictionary *)IOServiceNameMatching("IOBlockStorageDriver");
    
    // Remember - this call eats one reference to the matching dictionary.  In this case, removing the need to release it later
    error = IOServiceGetMatchingServices (kIOMasterPortDefault, (CFDictionaryRef)matchingDict, &iter);
    if (error != kIOReturnSuccess) {
		NSLog(@"Error finding disks: %s(%x)\n", mach_error_string(error), error);
    } else {
        while ((obj = IOIteratorNext(iter)) != IO_OBJECT_NULL) {		
            io_service_t parent;
            IORegistryEntryGetParentEntry(obj,kIOServicePlane,&parent);
            if (parent) {
                NSDictionary *dcharacteristics = [self getDictForProperty:@"Device Characteristics" device:parent];                
                if ([self isSmartCapable:parent]) {
                    [theList addObject:[SMARTQuery getSMARTData:parent]];                                
                }else{
                    [theList addObject:[dcharacteristics objectForKey:@"Product Name"]];
                }
                IOObjectRelease(parent);                                                    
            }  
            IOObjectRelease(obj);
        }
    }
	
	IOObjectRelease(iter);
	iter = IO_OBJECT_NULL;    
           
}

- (NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device
{
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

-(BOOL)isSmartCapable:(io_service_t)device
{    
    BOOL ret = NO;    
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, CFSTR("SMART Capable"), kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        ret = CFBooleanGetValue(theCFProperty) ? YES : NO;
        CFRelease(theCFProperty);
    }       
    return ret;
}


#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [theList count];	
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
    NSDictionary *item = [theList objectAtIndex:rowIndex];  
	NSString *ident = [theColumn identifier]; 

    if ([ident isEqualToString:@"text"]) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            if ([[item objectForKey:@"deviceOK"] boolValue] == YES) {
                return [NSString stringWithFormat:@"\n%@\nSMART OK",[item objectForKey:@"model"]];
            }else{
                return [NSString stringWithFormat:@"\n%@\nSMART NOT OK",[item objectForKey:@"model"]];
            }
        }else{
                return [NSString stringWithFormat:@"\n%@\nNO SMART INFO",item];
        }
    }
    if ([ident isEqualToString:@"icon"]) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            return [[[NSImage alloc ] initByReferencingFile:@"/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/Internal.icns"] autorelease];            
        }else{
            return [[[NSImage alloc ] initByReferencingFile:@"/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/External.icns"] autorelease];                        
        }    
    }    
    return nil;
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{      
    if ([theTable selectedRow] < 0) {
        [thePop performClose:self]; //no row selected has no actions or info      
    }
    
    NSDictionary *item = [theList objectAtIndex:[theTable selectedRow]];    
    if ([item isKindOfClass:[NSDictionary class]]) {
        [theController setTheDict:item];
        [thePop showRelativeToRect:[theTable rectOfRow:[theTable selectedRow]] ofView:theTable preferredEdge:NSMaxXEdge];    
    }else{
        [thePop performClose:self];    
    }        
    
}

@end

