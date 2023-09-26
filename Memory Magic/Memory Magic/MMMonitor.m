//
//  MMMonitor.m
//  Memory Magic
//
//  Created by Vlad Alexa on 11/10/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "MMMonitor.h"

#import "VASandboxFileAccess.h"

#include <asl.h>

#include <mach/mach_host.h>

#import "BSDProcessList.c"

@implementation MMMonitor

- (id)init
{
    self = [super init];
    if (self) {
        /*
         
         There are are a couple ways:
         
         1 - pipe vmmap for pid
         2 - use task_for_pid on pid and vm_region_recurse, mach_vm_region, vm_region
         3 - listen for the private kqueue/kevent DISPATCH_VM_PRESSURE from kernel
         4 - listen for syslog entries from kernel
         5 - save timestamped memory totals every second and pool syslog every minute
         
         */
        
        //NSLog(@"%li",[[self getBSDProcessList] count]);
        
        //[NSRunningApplication terminateAutomaticallyTerminableApplications];
        
        //processor_set_tasks
        
        NSLog(@"Memory recovery monitoring started (using significant CPU)");
        
        memDb = [NSMutableArray arrayWithCapacity:1];
        
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(memMonitor) userInfo:nil repeats:YES];
        
        [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(logMonitor) userInfo:nil repeats:YES];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    }
    return self;
}



- (void)memMonitor
{
	vm_statistics_data_t vm_stat;
	int count = HOST_VM_INFO_COUNT;
	kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (integer_t*)&vm_stat, (mach_msg_type_number_t*)&count);
	
	if(kernReturn != KERN_SUCCESS) return;
    
    if ([memDb count] > 60) [memDb removeLastObject];
    
    [memDb addObject:[NSArray arrayWithObjects:[NSNumber numberWithInteger:vm_stat.free_count * vm_page_size],[NSNumber numberWithInteger:vm_stat.inactive_count * vm_page_size],[NSNumber numberWithInteger:CFAbsoluteTimeGetCurrent()+kCFAbsoluteTimeIntervalSince1970], nil]];
    
}

-(void)logMonitor
{
    NSString *notice = @"The log will not be available without permissions to it.";
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:@"/private/var/log/asl" forced:NO denyNotice:notice];
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];
    [self parseSyslog:@"memorystatus_thread" sender:@"kernel"];
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];
}

-(void)parseSyslog:(NSString*)query sender:(NSString*)sender
{
    aslmsg q, m;
    int i;
    const char *key, *val;
    q = asl_new(ASL_TYPE_QUERY);
    asl_set_query(q, ASL_KEY_SENDER, [sender UTF8String], ASL_QUERY_OP_EQUAL);
    asl_set_query(q, ASL_KEY_MSG, [query UTF8String], ASL_QUERY_OP_EQUAL | ASL_QUERY_OP_SUBSTRING);
    asl_set_query(q, ASL_KEY_TIME, [[NSString stringWithFormat:@"%lu", lastSyslogPollTime] UTF8String], ASL_QUERY_OP_GREATER_EQUAL | ASL_QUERY_OP_NUMERIC);
    asl_set_query(q, ASL_KEY_TIME, [[NSString stringWithFormat:@"%lu", [self oldestTS]] UTF8String], ASL_QUERY_OP_GREATER_EQUAL | ASL_QUERY_OP_NUMERIC);
    aslresponse r = asl_search(NULL, q);
    asl_free(q);
    while (NULL != (m = aslresponse_next(r)))
    {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            val = asl_get(m, key);
            NSString *value = [NSString stringWithUTF8String:val];
            [tmpDict setObject:value forKey:keyString];
        }
        NSString *message = [tmpDict objectForKey:@"Message"];
        if (message)
        {
            NSUInteger logTS = [[tmpDict objectForKey:@"Time"] integerValue];
            
            NSArray *old = [self memForTS:logTS];
            if (!old) old = [self memForTS:[self closestTSbeforeTS:logTS]];
            NSArray *new = [self memForTS:[self closestTSafterTS:logTS]];
            
            if (!old && !new) {
                NSLog(@"No data for memory %@",message);
            }else{
                [self factorMemoryChange:@"Kernel" name:message old:old new:new];
            }
            
        }
    }
    aslresponse_free(r);
    lastSyslogPollTime = CFAbsoluteTimeGetCurrent()+kCFAbsoluteTimeIntervalSince1970;
}

-(void)didTerminate:(NSNotification*)notification
{
    NSArray *old = [memDb lastObject];
    [self memMonitor];
    
    NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    
    [self factorMemoryChange:@"User" name:[app bundleIdentifier] old:old new:[memDb lastObject]];
    
}

-(void)factorMemoryChange:(NSString*)type name:(NSString*)name old:(NSArray*)old new:(NSArray*)new
{
    NSInteger oldFree = [[old objectAtIndex:0] integerValue];
    NSInteger oldInact =  [[old objectAtIndex:1] integerValue];
    [NSThread sleepForTimeInterval:0.1];
    [self memMonitor];
    NSInteger newFree = [[new objectAtIndex:0] integerValue];
    NSInteger newInact = [[new objectAtIndex:1] integerValue];
    
    if (oldFree == newFree && oldInact == newInact) {
        NSLog(@"No change in memory after %@ quit",name);
        return;
    }
    
    if (oldFree > newFree && oldInact > newInact) {
        NSLog(@"No gain in memory after %@ quit",name);
        return;
    }
    
    if (oldFree + newFree == oldInact + newInact) {
        NSLog(@"No change in total unused memory after %@ quit",name);
    }
    
    NSLog(@"%@ freed %.2f MiB, added %.2f MiB inactive from %@",type,(newFree-oldFree)/1024.0/1024.0,(oldInact-newInact)/1024.0/1024.0,name);
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:type,@"type",[NSNumber numberWithLong:newFree-oldFree],@"free",[NSNumber numberWithLong:oldInact-newInact],@"inact", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AdvancedPopoverEvent" object:@"memoryChange" userInfo:dict];
}

-(NSInteger)oldestTS
{
    if ([memDb count] > 0) {
        return  [[[memDb objectAtIndex:0] objectAtIndex:2] integerValue];
    }
    return CFAbsoluteTimeGetCurrent()+kCFAbsoluteTimeIntervalSince1970;
}


-(NSInteger)closestTSbeforeTS:(NSInteger)ts
{
    NSInteger ret = 0;
    for (NSArray *arr in memDb) {
        NSInteger candidate = [[arr objectAtIndex:2] integerValue];
        if (candidate < ts) {
            if (candidate > ret) {
                ret = candidate;
            }
        }
    }
    return ret;
}

-(NSInteger)closestTSafterTS:(NSInteger)ts
{
    NSInteger ret = ts;
    for (NSArray *arr in memDb) {
        NSInteger candidate = [[arr objectAtIndex:2] integerValue];
        if (candidate > ts) {
            if (candidate < ret) {
                ret = candidate;
            }
        }
    }
    return ret;
}

-(NSArray*)memForTS:(NSInteger)ts
{
    for (NSArray *arr in memDb) {
        NSInteger candidate = [[arr objectAtIndex:2] integerValue];
        if (candidate == ts) {
            return [NSArray arrayWithObjects:[arr objectAtIndex:0],[arr objectAtIndex:1], nil];
        }
    }
    return nil;
}


-(void)taskForPid
{
    kern_return_t krc = KERN_SUCCESS;
    mach_port_name_t target_tport = 0;
    mach_port_name_t t;
    pid_t pid = 4126;
    krc = task_for_pid(target_tport,pid,&t);
    if (krc == KERN_SUCCESS) {
        [self vmmap:t];
    }else{
        NSLog(@"k err");
    }
    
    [self vmmap:mach_task_self()];
}

-(void)vmmap:(vm_map_t)task{
    
    int total = 0;
    kern_return_t krc = KERN_SUCCESS;
    vm_address_t address = 0;
    vm_size_t size = 0;
    uint32_t depth = 1;
    while (1) {
        struct vm_region_submap_info_64 info;
        mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
        krc = vm_region_recurse_64(mach_task_self(), &address, &size, &depth, (vm_region_info_64_t)&info, &count);
        if (krc == KERN_INVALID_ADDRESS){
            break;
        }
        if (info.is_submap){
            depth++;
        }
        else {
            //do stuff
            //printf ("Found region: %08x to %08lx\n", (uint32_t)address, (uint32_t)address+size);
            address += size;
            total += size;
        }
    }
    NSLog(@"%i",total);
}

- (NSArray*)getBSDProcessList
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    kinfo_proc *mylist;
    size_t mycount = 0;
    mylist = (kinfo_proc *)malloc(sizeof(kinfo_proc));
    GetBSDProcessList(&mylist, &mycount);
    int k;
    for(k = 0; k < mycount; k++) {
        kinfo_proc *proc = NULL;
        proc = &mylist[k];
        [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm],@"pname",
                        [NSString stringWithFormat:@"%d",proc->kp_proc.p_pid],@"pid",
                        [NSString stringWithFormat:@"%d",proc->kp_eproc.e_ucred.cr_uid],@"uid",
                        nil]];
    }
    free(mylist);
    
    return ret;
}



@end
