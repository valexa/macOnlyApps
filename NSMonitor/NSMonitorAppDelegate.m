//
//  NSMonitorAppDelegate.m
//  NSMonitor
//
//  Created by Vlad Alexa on 1/7/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "NSMonitorAppDelegate.h"
#import "VAValidation.h"
#import "TableController.h"
//#import "CGEventsController.h"

#include <mach/mach.h>

@implementation NSMonitorAppDelegate

CGEventRef MyEventTapCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* refcon)
{
    
    /*  
    NSEvent *notif = [NSEvent eventWithCGEvent:event]; 
    if ([notif type] == NSEventTypeMagnify){
        NSLog(@"%lld %lld %lld %lld %lld",
              CGEventGetIntegerValueField(event,55),
              CGEventGetIntegerValueField(event,59),
              CGEventGetIntegerValueField(event,101),
              CGEventGetIntegerValueField(event,107),
              CGEventGetIntegerValueField(event,110)
              );
    }
  
    if (type == 29) {
		NSEvent *notif = [NSEvent eventWithCGEvent:event];

        for (uint32_t i = 1 ; i < 299; i++) {
            int64_t result = CGEventGetIntegerValueField(event,i);
            if (result > 0) {
                NSLog(@"%i contains %lld (%@)",i,result,[notif description]);
            }
        } 
 
        for (uint32_t i = 1 ; i < 299; i++) {
            double result = CGEventGetDoubleValueField(event,i);
            if (result < 0) {
                NSLog(@"%i contains %f (%@)",i,result,[notif description]);
            }
        }         
    }
    */
    
	//CFShow([NSEvent eventWithCGEvent:event]);
	[(__bridge NSMonitorAppDelegate*)refcon onCGevent:event];	
	return NULL;
}

void IORegPublishCallBack(void *refcon, io_iterator_t iterator)
{
	[(__bridge NSMonitorAppDelegate*)refcon onREGevent:iterator action:@"Publish"];    
}

void IORegTerminateCallBack(void *refcon, io_iterator_t iterator)
{
	[(__bridge NSMonitorAppDelegate*)refcon onREGevent:iterator action:@"Terminate"];    
}

void MyFSEventStreamCallback(ConstFSEventStreamRef streamRef,void *refcon,size_t numEvents,void *eventPaths,const FSEventStreamEventFlags eventFlags[],const FSEventStreamEventId eventIds[])
{
	char **paths = eventPaths;
	NSMutableArray *ret = [NSMutableArray array];
	for (unsigned int i = 0; i < numEvents; i++) {	
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:eventIds[i]],@"id",[NSNumber numberWithInt:eventFlags[i]],@"flags",[NSString stringWithUTF8String:paths[i]],@"path", nil];
		[ret addObject:dict];
	}
	
	[(__bridge NSMonitorAppDelegate*)refcon onFSevent:ret];	
	
}

@synthesize window;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
    
    //prevent crash with deny file-write-data /private/var/db/mds/system/mds.lock
    if (![NSUserName() isEqualToString:@"root"]){
        int v = [VAValidation v];		
        int a = [VAValidation a];
        if (v+a != 0)  {		
            exit(v+a);
        }else {	
            //ok to run
        }             
    }    
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"CGEventsON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"CGEventsON"];
    if ([defaults objectForKey:@"FSEventsON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"FSEventsON"];
    if ([defaults objectForKey:@"NSDistributedON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"NSDistributedON"];
    if ([defaults objectForKey:@"NSWorkspaceON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"NSWorkspaceON"];
    if ([defaults objectForKey:@"NetworkON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"NetworkON"];    
    if ([defaults objectForKey:@"SocketsON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"SocketsON"]; 
    if ([defaults objectForKey:@"FilesON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"FilesON"];
    if ([defaults objectForKey:@"IORegistryON"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"IORegistryON"];
    
    [defaults synchronize];
    
    breatheSound = [NSSound soundNamed:@"breathe"];
    [breatheSound setVolume:0.1];   
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(distrib:) name:nil object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];	
		
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspace:) name:nil object:nil];	
       
	
	//cgevents tap
	CFMachPortRef eventTap = CGEventTapCreate(kCGAnnotatedSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, kCGEventMaskForAllEvents, MyEventTapCallBack, (__bridge void *)(self));
	CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
	CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop],runLoopSource, kCFRunLoopCommonModes);		
	CGEventTapEnable(eventTap, true);
	CFRelease(eventTap);		
	CFRelease(runLoopSource);		
	
	//fsevents tap
    CFStringRef mypath = CFSTR("/");
    CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&mypath, 1, NULL);
    CFAbsoluteTime latency = 1.0;	
	//crazy shit just to get a pointer
	FSEventStreamContext *mContext = malloc(sizeof(FSEventStreamContext));
	mContext->info = (__bridge void *)self;	mContext->version = 0;	mContext->retain = NULL;	mContext->release = NULL; mContext->copyDescription = NULL;	
    FSEventStreamRef stream = FSEventStreamCreate(NULL,MyFSEventStreamCallback,mContext,pathsToWatch, kFSEventStreamEventIdSinceNow,latency,kFSEventStreamCreateFlagFileEvents);
	CFRelease(pathsToWatch);
    FSEventStreamScheduleWithRunLoop(stream,[[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);	
	Boolean startedOK = FSEventStreamStart(stream);
	if (!startedOK) NSLog(@"ERROR tapping fsevents"); 
	    
    //lsof monitor
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(lsofLoop) userInfo:nil repeats:YES];    
    lastLsof = [NSMutableArray arrayWithCapacity:1];
    [self lsofLoop]; //run it once immediately at start
    
    //ioreg monitor
    mach_port_t 	masterPort;
    kern_return_t	kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (kr != KERN_SUCCESS || !masterPort) {
        NSLog(@"ERROR: Couldn't create a master IOKit Port(%08x)", kr);
    }else{
        gNotifyPort = IONotificationPortCreate(masterPort);
        CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
        CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], runLoopSource, kCFRunLoopDefaultMode);       
        kr = IOServiceAddMatchingNotification(gNotifyPort,kIOPublishNotification,IOServiceMatching(kIOServiceClass),IORegPublishCallBack,(__bridge void *)(self),&publishIter);
        if (kr != KERN_SUCCESS) {
            NSLog(@"ERROR: Couldn't set up publish notification (%08x)", kr);        
        }else{     
            IORegPublishCallBack((__bridge void *)(self), publishIter);// Iterate once to get already-present devices and arm the notification            
        }  
        kr = IOServiceAddMatchingNotification(gNotifyPort,kIOTerminatedNotification,IOServiceMatching(kIOServiceClass),IORegTerminateCallBack,(__bridge void *)(self),&terminateIter);
        if (kr != KERN_SUCCESS) {
            NSLog(@"ERROR: Couldn't set up terminate notification (%08x)", kr);        
        }else{     
            IORegTerminateCallBack((__bridge void *)(self), terminateIter);// Iterate once to get already-present devices and arm the notification            
        }         
        mach_port_deallocate(mach_task_self(), masterPort);
        masterPort = 0;        
    }    

	
    //
    //others
    //
    
	//bonjour monitor
	//NSNetServiceBrowser *serviceBrowser = [[NSNetServiceBrowser alloc] init];
	//[serviceBrowser setDelegate:self];
	//[serviceBrowser searchForBrowsableDomains];	
    
	//taps check
	//[self tapcheck];
	
}

-(void)dealloc
{
    IONotificationPortDestroy(gNotifyPort);    
    if (publishIter){
        IOObjectRelease(publishIter);
        publishIter = 0;
    }
    if (terminateIter){
        IOObjectRelease(terminateIter);
        terminateIter = 0;
    }    
}

-(void)awakeFromNib
{
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[statusLed frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:nil];	    
    [statusLed addTrackingArea:area];
    
    if ([NSUserName() isEqualToString:@"root"]) [window setTitle:@"NSMonitor (root)"];
}

-(void)mouseEntered:(NSEvent *)event {     
    doBreath = YES;
}

-(void)mouseExited:(NSEvent *)event
{    
    doBreath = NO;
    [statusPopover performClose:self];
}

#pragma mark lsof


-(void)lsofLoop
{   
    //CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();  
    
    BOOL networkPaused = [self tabPaused:4 name:@"Network" setting:@"NetworkON"];
    BOOL socketsPaused = [self tabPaused:5 name:@"Sockets" setting:@"SocketsON"];
    BOOL filesPaused = [self tabPaused:6 name:@"Files" setting:@"FilesON"];    
    
    if (networkPaused == YES && socketsPaused == YES && filesPaused == YES) return;    
    
    NSMutableArray *newLastLsof = [NSMutableArray arrayWithCapacity:1];  
    
    NSString *inf = [self execTask:@"/usr/sbin/lsof" args:[NSArray arrayWithObjects:@"-nP",nil]]; 
    [inf enumerateLinesUsingBlock: ^(NSString *line, BOOL *stop) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\S+?)\\s+?(\\d+?)\\s+?(\\S+?)\\s+?(\\S+?)\\s+?(\\S+?)\\s+?(\\S+?)\\s+?(\\S+?)\\s+?(\\S+?)\\s+?(.+)$" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:line options:NSAnchoredSearch range:NSMakeRange(0,[line length])];
        if ([matches count] == 1) {
            if ([[matches objectAtIndex:0] numberOfRanges] == 10) {
                NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]] forKey:@"name"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:2]] forKey:@"pid"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:3]] forKey:@"user"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:4]] forKey:@"fd"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:5]] forKey:@"type"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:6]] forKey:@"device"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:7]] forKey:@"size"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:8]] forKey:@"node"];
                [ret setObject:[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:9]] forKey:@"path"];
                [newLastLsof addObject:[ret description]];                
                if (![lastLsof containsObject:[ret description]] && ![[ret objectForKey:@"name"] isEqualToString:@"lsof"]) { 
                    [ret setObject:[NSDate date] forKey:@"time"];   
                    NSString *type = [ret objectForKey:@"type"];
                    if ([type isEqualToString:@"CHR"] || [type isEqualToString:@"PIPE"] || [type isEqualToString:@"unix"]) {
                        if (socketsPaused == NO) [socketsController newItem:ret];                                                
                    }else if ([type isEqualToString:@"IPv4"] || [type isEqualToString:@"IPv6"]) {
                        if (networkPaused == NO) [networkController newItem:ret];
                    }else{
                        if (filesPaused == NO) [filesController newItem:ret];
                    }                     
                }
            }else{
                NSLog(@"Only %lu matches parsing %@",[[matches objectAtIndex:0] numberOfRanges],line);                
                *stop = YES;                                
            }
        }else{
           //NSLog(@"No matches parsing %@",line);
        }
    }];
    
    if ([lastLsof count] != [newLastLsof count]) [self blinkStatus:@"yellow"];         
    
    [lastLsof removeAllObjects];
    [lastLsof setArray:newLastLsof];
    
    //NSLog(@"Lsof parse took %f seconds",CFAbsoluteTimeGetCurrent()-startTime);     
}

#pragma mark ioregevents
-(void)onREGevent:(io_iterator_t)iterator action:(NSString*)action
{
    if ([self tabPaused:7 name:@"IORegistry" setting:@"IORegistryON"] == YES) return;    
    
    [self blinkStatus:@"red"];	
    
    io_service_t	service;    
    while ( (service = IOIteratorNext(iterator)) )    {        
        io_string_t   servicePath;
        if (IORegistryEntryGetPath(service, kIOServicePlane, servicePath) == KERN_SUCCESS)    {
            NSString *path = [NSString stringWithFormat:@"%s",&servicePath];
            CFStringRef class = IOObjectCopyClass(service);
            CFStringRef bid = IOObjectCopyBundleIdentifierForClass(class);             
            NSArray *parts = [path componentsSeparatedByString:@":"];
            uint64_t rid;
            IORegistryEntryGetRegistryEntryID(service, &rid);
            uint32_t kcount = IOObjectGetKernelRetainCount(service);
            uint32_t ucount = IOObjectGetUserRetainCount(service);            
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];   
            [dict setObject:[path lastPathComponent] forKey:@"name"];
            [dict setObject:[parts lastObject] forKey:@"path"];
            [dict setObject:[parts objectAtIndex:0] forKey:@"root"];            
            [dict setObject:(__bridge NSString*)bid forKey:@"type"];
            [dict setObject:action forKey:@"action"];
            [dict setObject:[NSString stringWithFormat:@"%i",rid] forKey:@"id"];
            [dict setObject:[NSString stringWithFormat:@"%i",kcount] forKey:@"kernel_retain_count"];  
            [dict setObject:[NSString stringWithFormat:@"%i",ucount] forKey:@"user_retain_count"];              
            [dict setObject:[NSDate date] forKey:@"time"];    
            
            [ioregistryController newItem:dict];             
            
            CFRelease(class);
            CFRelease(bid);              
        }           
    }    
}

#pragma mark cgfsevents

-(void)onCGevent:(CGEventRef)event{
    
	if (CGEventGetType(event) == kCGEventMouseMoved) return;  //ignore cursor moves  
    
    if ([self tabPaused:0 name:@"CGEvents" setting:@"CGEventsON"] == YES) return;     
        
    NSEvent *nsevent = [NSEvent eventWithCGEvent:event];     
    NSEventType type = [nsevent type];
    CGEventType old_type = CGEventGetType(event);
    NSString *icon_type = @"N/A";
    if(old_type == kCGEventNull){	
        return;
    }else if (old_type == kCGEventTapDisabledByTimeout || old_type == kCGEventTapDisabledByUserInput) {		
		NSLog(@"timeout");//TODO
  	}else if (old_type == kCGEventTabletPointer || old_type == kCGEventTabletProximity) {
		icon_type = @"tablet";
    }else if (old_type == kCGEventKeyDown || old_type == kCGEventKeyUp || old_type == kCGEventFlagsChanged ){	
		icon_type = @"key";
	}else if (old_type == kCGEventLeftMouseDown || old_type == kCGEventLeftMouseUp || old_type == kCGEventRightMouseDown || old_type == kCGEventRightMouseUp || old_type == kCGEventMouseMoved || old_type == kCGEventLeftMouseDragged || old_type == kCGEventRightMouseDragged || old_type == kCGEventScrollWheel || old_type == kCGEventOtherMouseDown || old_type == kCGEventOtherMouseUp || old_type == kCGEventOtherMouseDragged) {   
		icon_type = @"pointer";
	}else if (old_type == 29){        
        if (type == NSEventTypeGesture || type == NSEventTypeBeginGesture || type == NSEventTypeEndGesture || type == NSEventTypeSwipe || type == NSEventTypeMagnify || type == NSEventTypeRotate) {
            icon_type = @"gesture";            
        }else{
            NSLog(@"unknown gesture %lu",type);
        }        
    }else if (type == NSAppKitDefined || type == NSSystemDefined || type == NSApplicationDefined ) {         
		icon_type = @"defined";        
    }else if (type == NSMouseEntered || type == NSMouseExited || type == NSCursorUpdate ) {         
		icon_type = @"pointer";      
    }    
    
    [self blinkStatus:@"green"];   
    
    NSEvent *notif = [NSEvent eventWithCGEvent:event];
    //NSLog(@"%@",[notif description]);
    
    NSString *raw = [notif description];
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithObject:icon_type forKey:@"icon_type"];   
    NSMutableString *extra = [NSMutableString stringWithCapacity:1];
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:1];
    for (NSTableColumn *column in [cGEventsController.theTable tableColumns]) {
        NSString *ident = [column identifier];
        if (ident) [identifiers addObject:ident];
    }    
    
    for (NSString *str in [raw componentsSeparatedByString:@" "]) {
        NSArray *comp = [str componentsSeparatedByString:@"="];
        if ([comp count] == 2) {
            NSString *key = [comp objectAtIndex:0];
            NSString *value = [comp objectAtIndex:1];            
            if ([identifiers containsObject:key]) {
                [ret setObject:value forKey:key];                
            }else{
                if (![value isEqualToString:@"0x0"]) [extra appendFormat:@"%@:%@ ",key,value];
            }
        }
    }  
    
    [ret setObject:extra forKey:@"extra"];  
    
    if (old_type != type) {
        [ret setObject:[NSString stringWithFormat:@"%i (%i old)",type,old_type] forKey:@"type_extra"];
    }else{
        [ret setObject:[NSString stringWithFormat:@"%i",type] forKey:@"type_extra"];        
    }        
    
    [cGEventsController newItem:ret];    

}

-(void)onFSevent:(NSArray *)events{
    
    if ([self tabPaused:1 name:@"FSEvents" setting:@"FSEventsON"] == YES) return;    
    
    [self blinkStatus:@"yellow"];
    
	for (NSDictionary *event in events){
        NSMutableDictionary *dict = [event mutableCopy];
        NSString *type = @"N/A";
        UInt32 flags = [[event objectForKey:@"flags"] intValue];
        if (flags & kFSEventStreamEventFlagItemCreated) type = @"Created";
        if (flags & kFSEventStreamEventFlagItemRemoved) type = @"Removed";
        if (flags & kFSEventStreamEventFlagItemInodeMetaMod) type = @"InodeMeta Changed";
        if (flags & kFSEventStreamEventFlagItemRenamed) type = @"Renamed";
        if (flags & kFSEventStreamEventFlagItemModified) type = @"Modified";
        if (flags & kFSEventStreamEventFlagItemFinderInfoMod) type = @"FinderInfo Changed";
        if (flags & kFSEventStreamEventFlagItemChangeOwner) type = @"Owner Changed";
        if (flags & kFSEventStreamEventFlagItemXattrMod) type = @"Xattr Changed";
        [dict setObject:type forKey:@"type"];
        NSString *fstype = @"N/A";        
        if (flags & kFSEventStreamEventFlagItemIsFile ) fstype = @"File";
        if (flags & kFSEventStreamEventFlagItemIsDir ) fstype = @"Directory";          
        [dict setObject:fstype forKey:@"fstype"];        
        
        [dict setObject:[[dict objectForKey:@"path"] lastPathComponent] forKey:@"name"];
        [dict setObject:[NSDate date] forKey:@"time"];        

        [fseventsController newItem:dict];                 
	}
}

#pragma mark notifications

-(void)distrib:(NSNotification *)notif{
      
    if ([self tabPaused:2 name:@"NSDistributed" setting:@"NSDistributedON"] == YES) return;    
    
    [self blinkStatus:@"blue"];	
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];   
    [dict setObject:[notif name] forKey:@"name"];
    [dict setObject:[NSDate date] forKey:@"time"];    
    if ([notif object]) [dict setObject:[notif object] forKey:@"object"];    
    if ([notif userInfo]) [dict setObject:[notif userInfo] forKey:@"userinfo"];  
    
    [distributedController newItem:dict];  
    
}

- (void)workspace:(NSNotification *)notif{
    
    if ([self tabPaused:3 name:@"NSWorkspace" setting:@"NSWorkspaceON"] == YES) return; 
    
    [self blinkStatus:@"blue"];

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];   
    [dict setObject:[notif name] forKey:@"name"];
    [dict setObject:[NSDate date] forKey:@"time"];        
    if ([notif object]) [dict setObject:[notif object] forKey:@"object"];    
    if ([notif userInfo]) [dict setObject:[notif userInfo] forKey:@"userinfo"]; 
    
    [workspaceController newItem:dict]; 	

}



#pragma mark bonjour

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreComing{
	NSNetServiceBrowser *serviceBrowser = [[NSNetServiceBrowser alloc] init];	
	[serviceBrowser setDelegate:self];	
    [serviceBrowser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:domainName];	
	//if(!moreComing) NSLog(@"done domains");
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing {
	if ([[netService domain] isEqualToString:@"."]) {
		//enumeration service		
		NSArray *parts = [[netService type] componentsSeparatedByString:@"."];
		if ([parts count] == 3){
			NSNetServiceBrowser *serviceBrowser = [[NSNetServiceBrowser alloc] init];	
			[serviceBrowser setDelegate:self];	
			[serviceBrowser searchForServicesOfType:[NSString stringWithFormat:@"%@.%@",[netService name],[parts objectAtIndex:0]] inDomain:[parts objectAtIndex:1]];			
		}else{
			//weird
            NSLog(@"%@",netService);
		}
	}else {
		//plain service		
		NSLog(@"%@%@%@",[netService domain],[netService type],[netService name]);					
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing{
    NSLog(@"%@",netService);	
	if(!moreComing) NSLog(@"done delete services");
}

#pragma mark tapcheck

- (void)tapcheck {
	
	NSMutableArray *detailedTaps = [NSMutableArray arrayWithCapacity:1];	
	NSDictionary *taps = [self getTaps];
	for (id pid in taps){
		NSMutableDictionary *dict = [[self infoForPID:[pid intValue]] mutableCopy];
		[dict setObject:[taps objectForKey:pid] forKey:@"TYPE"];		
		[detailedTaps addObject:dict];
	}	
	
	int count = 0;
	for (id dict in detailedTaps){
		NSString *bid = [dict objectForKey:@"CFBundleIdentifier"];
		if ([bid length] > 0) {
			count += 1;
		}else{
			NSLog(@"Can't get info on pid %@ (different session or orphan)",[dict objectForKey:@"PID"]);			
		}
        NSLog(@"%@",dict);			
	}	
	
}

- (NSDictionary *)getTaps{
	NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
	uint32_t preCount;
    CGError err;
	err = CGGetEventTapList(0, NULL, &preCount);
    if (err == kCGErrorSuccess){		
		CGEventTapInformation *list = (CGEventTapInformation *)calloc(preCount,sizeof(CGEventTapInformation));
		uint32_t postCount;
		err = CGGetEventTapList(preCount, list, &postCount);
		if (err == kCGErrorSuccess) {		
			int i;
			int count = 0;
			for (i = 0; i < postCount; i++) {	
				NSString *pid = [NSString stringWithFormat:@"%i",list[i].tappingProcess];
				count = [[ret objectForKey:pid] intValue]+1;
				if (list[i].options == 0x00000000){
					[ret setObject:@"active" forKey:pid];					
				}else {
					[ret setObject:@"passive" forKey:pid];					
				}
				
			}	
			free(list);				
		}				
	}	
	return ret;
}

- (NSDictionary *)infoForPID:(pid_t)pid {
    NSDictionary *ret = nil;
	ProcessSerialNumber psn;
	if (GetProcessForPID(pid, &psn) == noErr) {
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,kProcessDictionaryIncludeAllInformationMask); 
        ret = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)cfDict];
        CFRelease(cfDict);
	}
	return ret;
}

#pragma mark status

-(IBAction)statusPopover:(id)sender
{
    [statusPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];       
}

-(void)blinkStatus:(NSString*)color{
    if (color != nil) {
        [statusLed setImage:[NSImage imageNamed:color]];                        
    }else{
        [statusLed setImage:[NSImage imageNamed:@"green"]];                        
    }    
	if ([statusLed tag] == 0) {       
		[statusLed setTag:1];	
		statusTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(grayStatus:) userInfo:nil repeats:NO];			        
    }else{
		[statusTimer invalidate];
        statusTimer = nil;
		statusTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(grayStatus:) userInfo:nil repeats:NO];		        
    }	
    if (doBreath == YES){
        if (![breatheSound isPlaying])[breatheSound stop];
        [breatheSound play];             
    }
}

-(void)grayStatus:(NSTimer*)timer
{
	if ([statusLed tag] == 1) {    
		[statusLed setImage:[NSImage imageNamed:@"gray"]];
		[statusLed setTag:0];	
        statusTimer = nil;        
	}	    
}


-(IBAction)ONOFFCheck:(id)sender
{
    [defaults synchronize]; //have to keep in sync
}

#pragma mark tools


-(NSString*)execTask:(NSString*)launch args:(NSArray*)args
{   
	NSPipe *stdout_pipe = [[NSPipe alloc] init];
    if (stdout_pipe == nil) {
        NSLog(@"ERROR ran out of file descriptors at %@ %@",launch,[args lastObject]);
        return nil;
    }        
    
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:launch];
	[task setArguments:args];
	[task setStandardOutput:stdout_pipe];
    [task setStandardError:[task standardOutput]];    
    
    NSFileHandle *stdout_file = [stdout_pipe fileHandleForReading];
    NSMutableString *output = [NSMutableString stringWithCapacity:1];     
	
    //set a timer to terminate the task if not done in a timely manner
    NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:task selector:@selector(terminate) userInfo:nil repeats:NO];    
	[task launch];
    
    //read all data chunks as they come in
    NSData *inData = nil;   
    while ( (inData = [stdout_file availableData]) && [inData length] ) {
        NSString *str = [[NSString alloc] initWithFormat:@"%.*s", [inData length], [inData bytes]];
        [output appendString:str];     
        if ([output length] > 8000000) {
            NSLog(@"%@ data exceeds maximum, terminating, remaining output skipped",launch);            
            [output appendString:@"\n**Data exceeds maximum, remaining output skipped"];
            [task terminate];
            break;            
        }
    }  
    
	[task waitUntilExit];
    [timeoutTimer invalidate];
    
    if ([task terminationStatus] == 0){
        //NSLog(@"Task %@ succeeded.",launch);
    }else{
        //NSLog(@"Task %@ failed.",launch);   
    } 
    
    [stdout_file closeFile]; //unless we do this pipes are never released even if documentation says different        
    return output;    
}

-(BOOL) tabPaused:(int)index name:(NSString*)name setting:(NSString*)setting
{
    if ([defaults boolForKey:setting] == NO) {
		NSTabViewItem *tab = [theTab tabViewItemAtIndex:index];		
        if ([[tab identifier] intValue] > 0 && [[tab label] rangeOfString:@"∙"].location == NSNotFound) {
            [tab setLabel:[NSString stringWithFormat:@"%@ ∙(%@)",name,[tab identifier]]];	                   
        }
        return YES;
    } 
    return NO;
}

#pragma mark create


-(IBAction)createNotification:(id)sender
{
	[NSApp beginSheet:windowCreateNotif modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];  
}

- (IBAction)createNotificationCancel:(id)sender
{
	[NSApp endSheet:windowCreateNotif];
	[windowCreateNotif close];
}

@end
