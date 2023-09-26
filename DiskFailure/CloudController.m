//
//  CloudController.m
//  DiskFailure
//
//  Created by Vlad Alexa on 3/1/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "CloudController.h"

@implementation CloudController

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowOpened:) name:NSWindowDidBecomeMainNotification object:nil];        
        
        //find the file
        NSURL *url = [self getiCloudURLFor:@"sharedData.plist" containerID:nil]; //leaving nil so it is auto filled from entitlements
        if (url && [self isiCloudAvailable]) { //only do this if we have icloud
            NSError *error;
            if (![[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error]) {
                NSLog(@"Error downloading/syncing %@ (%@)",[url path],[error description]);                
            }else{
                NSLog(@"Started downloading/syncing %@",[url path]); 
                [self mergeWithiCloudCheck:url];
            }         
        }        
        
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)mainWindowOpened:(NSNotification *)notification
{
    if ([self isiCloudAvailable]) { //only do this if we have icloud
        [self resolveConflicts:[self getiCloudURLFor:@"sharedData.plist" containerID:nil]];              
    }    
}

#pragma mark icloud

-(BOOL)isiCloudAvailable
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm respondsToSelector:@selector(URLForUbiquityContainerIdentifier:)]) {
        if ([fm URLForUbiquityContainerIdentifier:nil]) return YES;        
    }
    return NO;
}

- (NSURL*)getiCloudURLFor:(NSString*)fileName containerID:(NSString*)containerID
{   
    NSFileManager *fm = [NSFileManager defaultManager];  
    
    NSURL *localURL = [[[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:fileName]; //no cloud     
    
    if (![fm respondsToSelector:@selector(URLForUbiquityContainerIdentifier:)]) return localURL; //not Lion
    
    NSURL *rootURL = [fm URLForUbiquityContainerIdentifier:containerID];
    if (rootURL) {
        NSURL *directoryURL = [rootURL URLByAppendingPathComponent:@"Documents"];
        [fm createDirectoryAtURL:directoryURL withIntermediateDirectories:NO attributes:nil error:NULL];
        NSURL *cloudURL = [directoryURL URLByAppendingPathComponent:fileName];
        if (![fm isUbiquitousItemAtURL:cloudURL]) [self makeUbiquitousItemAtURL:cloudURL];//this only runs once per filename when it is first added to iCloud
        return cloudURL;
    }
      
    return  localURL;
}

- (void)makeUbiquitousItemAtURL:(NSURL*)cloudURL
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL *localURL = [[[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:[cloudURL lastPathComponent]];            
    if (![fm fileExistsAtPath:[localURL path]]) [fm createFileAtPath:[localURL path] contents:nil attributes:nil];//create local file it if it does not exist
    NSError *error;            
    if(![fm setUbiquitous:YES itemAtURL:localURL destinationURL:cloudURL error:&error])  {
        NSLog(@"Error making %@ ubiquituous at %@ (%@)",[localURL path],[cloudURL path],[error description]);
    }else{
        NSLog(@"Made %@ ubiquituous at %@",[localURL lastPathComponent],[cloudURL path]);
        NSAlert *alert = [NSAlert alertWithMessageText:@"Your DiskFailure data is now stored in iCloud." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];         
    }      
}

- (void)makeNonUbiquitousItemAtURL:(NSURL*)cloudURL
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL *localURL = [[[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:[cloudURL lastPathComponent]];            
    NSError *error;            
    if(![fm setUbiquitous:NO itemAtURL:cloudURL destinationURL:localURL error:&error])  {
        NSLog(@"Error making %@ non-ubiquituous at %@ (%@)",[cloudURL path],[localURL path],[error description]);
    }else{
        NSLog(@"Made %@ non-ubiquituous at %@",[cloudURL lastPathComponent],[localURL path]);
    }      
}

-(NSURL*)getSnapshotLink:(NSURL*)cloudURL
{
    NSDate *date = nil;
    NSError *err = nil;
    NSURL *link = [[NSFileManager defaultManager] URLForPublishingUbiquitousItemAtURL:cloudURL expirationDate:&date error:&err];
    if (!err) {
        NSLog(@"%@ is available until %@",link,date);
    }else {
        NSLog(@"%@",err);
    }
    return link;
}

#pragma mark extra

- (void)mergeWithiCloudCheck:(NSURL*)cloudURL
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL *localURL = [[[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:[cloudURL lastPathComponent]];            
    NSError *error;     
    
    if ([fm fileExistsAtPath:[localURL path]]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:localURL];
        NSDictionary *logs = [dict objectForKey:@"logs"];
        if (logs) [self addLogs:logs toCloud:cloudURL];        
        NSDictionary *disks = [dict objectForKey:@"disks"];        
        if (disks) [self addDisks:disks toCloud:cloudURL];
        if (logs || disks) {
            NSString *message = [NSString stringWithFormat:@"New data on this Mac was merged with iCloud"];
            NSLog(@"%@",message);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"VADiskFailureEvent" object:nil userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",@"iCloud event",@"title",message,@"message",nil]
             ];             
        }
        if (![fm removeItemAtURL:localURL error:&error]) NSLog(@"Error deleting %@ (%@)",[localURL path],[error description]);  //also delete it
    }
}

- (void)resolveConflicts:(NSURL*)cloudURL
{    
    NSArray *conflicts = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:cloudURL];
    for (NSFileVersion *conflict in conflicts) {
        NSLog(@"Conflicting %@ at %@ by %@ from %@",[cloudURL path],[conflict URL],[conflict localizedNameOfSavingComputer],[conflict modificationDate]);   
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:[conflict URL]];
        NSDictionary *logs = [dict objectForKey:@"logs"];
        if (logs) [self addLogs:logs toCloud:cloudURL];        
        NSDictionary *disks = [dict objectForKey:@"disks"];        
        if (disks) [self addDisks:disks toCloud:cloudURL];
        [conflict setResolved:YES];
        NSString *message = [NSString stringWithFormat:@"Resolved iCloud conflict with %@",[conflict localizedNameOfSavingComputer]];
        NSLog(@"%@",message);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VADiskFailureEvent" object:nil userInfo:
         [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",@"iCloud event",@"title",message,@"message",nil]
         ];          
    }
}

-(void)addLogs:(NSDictionary*)newOnes toCloud:(NSURL*)cloudURL
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfURL:cloudURL]];
    NSMutableDictionary *oldOnes = [NSMutableDictionary dictionaryWithDictionary:[plist objectForKey:@"logs"]];    
    for (NSString *machine in newOnes) {
        NSArray *new = [newOnes objectForKey:machine];
        NSMutableArray *old = [NSMutableArray arrayWithArray:[oldOnes objectForKey:machine]];
        for (NSString *item in new) {
            if (![old containsObject:item]) {
                [old addObject:item];
            }
        }
        [oldOnes setObject:old forKey:machine];
    }    
    [plist setObject:oldOnes forKey:@"logs"];
    [plist writeToURL:cloudURL atomically:YES]; 
}

-(void)addDisks:(NSDictionary*)newOnes toCloud:(NSURL*)cloudURL
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfURL:cloudURL]];
    NSMutableDictionary *oldOnes = [NSMutableDictionary dictionaryWithDictionary:[plist objectForKey:@"disks"]];    
    for (NSString *disk in newOnes) {
        NSDictionary *new = [newOnes objectForKey:disk];
        NSDictionary *old = [oldOnes objectForKey:disk];
        //add disks that do not exists at all
        if (old == nil) {
            [oldOnes setObject:new forKey:disk];
            NSLog(@"added new %@",disk); 
            continue;
        }        
        //add newer checked disks
        NSDate *newDate = [new objectForKey:@"lastCheck"];
        NSDate *oldDate = [old objectForKey:@"lastCheck"];        
        if ([oldDate compare:newDate] == NSOrderedAscending) {
            [oldOnes setObject:new forKey:disk];
            NSLog(@"added newer %@",disk);
        }
    }    
    [plist setObject:oldOnes forKey:@"disks"];
    [plist writeToURL:cloudURL atomically:YES]; 
}

@end
