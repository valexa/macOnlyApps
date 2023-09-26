//
//  MainController.m
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/2/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "MainController.h"

#import "MDBufferedInputStream.h"

@interface MainController ()

@end

@implementation MainController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MainControllerEvent" object:nil];
    
        libraryPath = [[NSMutableString alloc] init];
        diskPaths = [[NSMutableArray alloc] init];
        
        changedOnDisk = [[NSMutableArray alloc] init];
        
        dupesOnDisk = [[NSMutableArray alloc] init];
        dupesInLib = [[NSMutableArray alloc] init];
        
        inLibNotOnDisk = [[NSMutableArray alloc] init];
        onDiskNotInLib = [[NSMutableArray alloc] init];
    
    }
    
    return self;
}

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:@"MainControllerEvent"]) {
		return;
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {
        if ([[notif object] isEqualToString:@"refresh"]) {
            [self refresh:self];
        }
        if ([[notif object] isEqualToString:@"canQuitDragging"]) {
            [dragDropButton setHidden:NO];
        }
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *info = [notif userInfo];
        if ([[notif object] isEqualToString:@"statusUpdate"])
        {
            if ([[info objectForKey:@"type"] isEqualToString:@"append"])
            {
                [statusText.animator setStringValue:[NSString stringWithFormat:@"%@\n%@",[statusText stringValue],[info objectForKey:@"statusText"]]];
            }
            if ([[info objectForKey:@"type"] isEqualToString:@"replace"])
            {
                [statusText.animator setStringValue:[info objectForKey:@"statusText"]];
            }
        }
        if ([[notif object] isEqualToString:@"dragUpdate"])
        {
            [dragDropText.animator setStringValue:[info objectForKey:@"dragText"]];
        }
        if ([[notif object] isEqualToString:@"libraryPath"])
        {
            [libraryPath setString:[info objectForKey:@"path"]];            
        }
        if ([[notif object] isEqualToString:@"diskPath"])
        {
            if (![diskPaths containsObject:[info objectForKey:@"path"]]) {
                [diskPaths addObject:[info objectForKey:@"path"]];
            }
        }
    }
}

-(void)awakeFromNib
{
    [statusItem setView:statusView];    
    [segments setHidden:YES];
    [refreshButton setHidden:YES];
    [dragDropButton setHidden:YES];
    [statusText setStringValue:@""];     
}

-(IBAction)refresh:(id)sender
{
    [refreshButton setHidden:YES];
    [refreshSpinner startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self reloadUI];
    });
}

-(void)reloadUI
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    [statusText setStringValue:@"Loading library ..."];
    

    
    [changedOnDisk removeAllObjects];
    NSDictionary *xml = [self parseXML:libraryPath];
    NSArray *lib = [xml objectForKey:@"list"];
    NSArray *dates = [xml objectForKey:@"dates"];
    [dupesInLib setArray:[xml objectForKey:@"dupes"]];
    NSLog(@"Found %li files in library",[lib count]);    
    NSLog(@"Found %li dupes in library",[dupesInLib count]);
    [segments setLabel:[NSString stringWithFormat:@"Duplicate files in library (%li)",[dupesInLib count]] forSegment:0];
    //NSLog(@"%@",dupesInLib);
    [dupesInLibTable reloadData];    
    [statusText setStringValue:[NSString stringWithFormat:@"Loaded %li library songs, matching ...",[lib count]]];
    
    [inLibNotOnDisk removeAllObjects];
    NSFileManager *fm = [[NSFileManager alloc] init];
    for (NSString *file in lib) {
        NSURL *url = [NSURL URLWithString:[self urlDecode:file]];
        if (![fm fileExistsAtPath:[url path]]) {
            [inLibNotOnDisk addObject:url];
        }else{
            if ([lib count] == [dates count]) {
                NSInteger index = [lib indexOfObject:file];
                if ([dates count] > index) {
                    NSDate *date = [dates objectAtIndex:index];
                    if ([self dateOf:url differsFrom:date]) [changedOnDisk addObject:url];
                }else{
                    NSLog(@"Dates index error");
                }
            }
        }
    }
    NSLog(@"Found %li files in library not on disk",[inLibNotOnDisk count]);
    [segments setLabel:[NSString stringWithFormat:@"In library not on disk (%li)",[inLibNotOnDisk count]] forSegment:1];
    [statusText setStringValue:[NSString stringWithFormat:@"Loaded %li library songs (%li not on disk) \nLoading disk ...",[lib count],[inLibNotOnDisk count]]];    
    //NSLog(@"%@",inLibNotOnDisk);
    [inLibNotOnDiskTable reloadData];
    
    
    NSLog(@"Found %li files changed on disk out of sync from library",[changedOnDisk count]);
    [segments setLabel:[NSString stringWithFormat:@"Changed files on disk out of sync (%li)",[changedOnDisk count]] forSegment:2];
    //NSLog(@"%@",changedOnDisk);
    [changedOnDiskTable reloadData];    
    
    
    [dupesOnDisk removeAllObjects];
    NSMutableArray *dir = [NSMutableArray arrayWithCapacity:1];
    for (NSString *disk in diskPaths) {
        NSDictionary *d = [self enumDir:disk];
        [dir addObjectsFromArray:[d objectForKey:@"list"]];
        [dupesOnDisk addObjectsFromArray:[d objectForKey:@"dupes"]];
    }
    NSLog(@"Found %li files on disk",[dir count]);
    NSLog(@"Found %li dupes on disk",[dupesOnDisk count]);
    [segments setLabel:[NSString stringWithFormat:@"Duplicate files on disk (%li)",[dupesOnDisk count]] forSegment:4];
    //NSLog(@"%@",dupesOnDisk)
    [dupesOnDiskTable reloadData];    
    [statusText setStringValue:[NSString stringWithFormat:@"Loaded %li library songs (%li not on disk) \nLoaded %li disk songs, matching ...",[lib count],[inLibNotOnDisk count],[dir count]]];
    
    [onDiskNotInLib removeAllObjects];
    for (NSString *file in dir) {
        if (![lib containsObject:file]) {
            NSURL *url = [NSURL URLWithString:[self urlDecode:file]];
            [onDiskNotInLib addObject:url];
        }
    }
    NSLog(@"Found %li files on disk not in library",[onDiskNotInLib count]);
    [segments setLabel:[NSString stringWithFormat:@"On disk not in library (%li)",[onDiskNotInLib count]] forSegment:3];
    [statusText setStringValue:[NSString stringWithFormat:@"Loaded %li library songs (%li not on disk) \nLoaded %li disk songs (%li not in library)",[lib count],[inLibNotOnDisk count],[dir count],[onDiskNotInLib count]]];    
    //NSLog(@"%@",onDiskNotInLib);
    [onDiskNotInLibTable reloadData];    

    
    
    [refreshButton setHidden:NO];
    [refreshSpinner performSelectorOnMainThread:@selector(stopAnimation:) withObject:self waitUntilDone:NO];
    
	double interval = CFAbsoluteTimeGetCurrent() - startTime;
    [statusText setStringValue:[NSString stringWithFormat:@"%@\nFinished, took %@.",[statusText stringValue],[self humanizeTimeInterval:interval]]];
    NSLog(@"Done in %f sec",interval);
}


-(NSString*)humanizeTimeInterval:(double)time
{
	int d = 0;
	int h = 0;
	int m = 0;
	int s = 0;
	NSString *ret = @"";
	
	if (time < 1) {
		return @"less than a second";
	}
	if (time >= 3600 ) {
		h = floor((time-(d*86400)) / 60 / 60);
		ret = [ret stringByAppendingFormat:@"%d hour",h];
		if (h >= 2) ret = [ret stringByAppendingString:@"s"];
		ret = [ret stringByAppendingString:@", "];
	}
	if (time >= 60) {
		m = floor((time-(d*86400)-(h*3600)) / 60);
		ret = [ret stringByAppendingFormat:@"%d minute",m];
		if (m >= 2) ret = [ret stringByAppendingString:@"s"];
	}
	if (time > 1) {
		s = floor((time-(d*86400)-(h*3600)-(m*60)));
		ret = [ret stringByAppendingFormat:@"%d second",s];
		if (s >= 2) ret = [ret stringByAppendingString:@"s"];
	}
	return ret;
}

-(IBAction)segmentChange:(id)sender
{
    NSInteger index = [segments selectedSegment];
    if (index == 0) {
        [[[onDiskNotInLibTable superview] superview] setHidden:YES];
        [[[inLibNotOnDiskTable superview] superview] setHidden:YES];
        [[[dupesInLibTable superview] superview] setHidden:NO];
        [[[dupesOnDiskTable superview] superview] setHidden:YES];
        [[[changedOnDiskTable superview] superview] setHidden:YES];
    }
    if (index == 1) {
        [[[onDiskNotInLibTable superview] superview] setHidden:YES];
        [[[inLibNotOnDiskTable superview] superview] setHidden:NO];
        [[[dupesInLibTable superview] superview] setHidden:YES];
        [[[dupesOnDiskTable superview] superview] setHidden:YES];
        [[[changedOnDiskTable superview] superview] setHidden:YES];
    }
    if (index == 2) {
        [[[onDiskNotInLibTable superview] superview] setHidden:YES];
        [[[inLibNotOnDiskTable superview] superview] setHidden:YES];
        [[[dupesInLibTable superview] superview] setHidden:YES];
        [[[dupesOnDiskTable superview] superview] setHidden:YES];
        [[[changedOnDiskTable superview] superview] setHidden:NO];
    }
    if (index == 3) {
        [[[onDiskNotInLibTable superview] superview] setHidden:NO];
        [[[inLibNotOnDiskTable superview] superview] setHidden:YES];
        [[[dupesInLibTable superview] superview] setHidden:YES];
        [[[dupesOnDiskTable superview] superview] setHidden:YES];
        [[[changedOnDiskTable superview] superview] setHidden:YES];
    }
    if (index == 4) {
        [[[onDiskNotInLibTable superview] superview] setHidden:YES];
        [[[inLibNotOnDiskTable superview] superview] setHidden:YES];
        [[[dupesInLibTable superview] superview] setHidden:YES];
        [[[dupesOnDiskTable superview] superview] setHidden:NO];
        [[[changedOnDiskTable superview] superview] setHidden:YES];
    }
}

-(IBAction)doneDragDrop:(id)sender
{
    [[[dupesInLibTable superview] superview] setHidden:NO];
    [segments setHidden:NO];
    [dragDropView setHidden:YES];
    [self refresh:self];
}

#pragma mark loading

-(NSString*)urlEncode:(NSString*)str
{
    
    if (![str isKindOfClass:[NSString class]]) {
        NSLog(@"%@ not a string",str);
        return @"";
    }
    
    NSString *ret = [str stringByReplacingOccurrencesOfString:@"&" withString:@"&#38;"];
    return ret;
}

-(NSString*)urlDecode:(NSString*)str
{
    
    if (![str isKindOfClass:[NSString class]]) {
        NSLog(@"%@ not a string",str);
        return @"";
    }
    
    NSString *ret = [str stringByReplacingOccurrencesOfString:@"&#38;" withString:@"&"];
    return ret;
}

-(BOOL)isMusicFile:(NSString*)file
{
    if ([file length] < 8) return NO;
    
    if (![[file substringToIndex:7] isEqualToString:@"file://"]) return NO;
    
    if ([self isMP3:[file pathExtension]]) return YES;
    
    if ([self isAAC:[file pathExtension]]) return YES;
    
    return NO;
}

-(BOOL)isMP3:(NSString*)ext
{
    NSComparisonResult result = [ext caseInsensitiveCompare:@"MP3"];
    if (result == NSOrderedSame) return YES;
    
    result = [ext caseInsensitiveCompare:@"MP1"];
    if (result == NSOrderedSame) return YES;
    
    result = [ext caseInsensitiveCompare:@"MP2"];
    if (result == NSOrderedSame) return YES;
    
    return NO;
}

-(BOOL)isAAC:(NSString*)ext
{
    NSComparisonResult result = [ext caseInsensitiveCompare:@"AAC"];
    if (result == NSOrderedSame) return YES;
    
    result = [ext caseInsensitiveCompare:@"M4A"];
    if (result == NSOrderedSame) return YES;
    
    return NO;
}

-(NSDate*)dateFromZulu:(NSString*)str
{
	if (str == nil) return nil;
    
	NSDateFormatter *f = [[NSDateFormatter alloc] init];
	[f setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [f setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	NSDate *ret = [f dateFromString:str];
	
	return ret;
}

-(BOOL)dateOf:(NSURL*)url differsFrom:(NSDate*)date
{
    
    NSDate *diskDate = nil;
    [url getResourceValue:&diskDate forKey:NSURLContentModificationDateKey error:nil];
    if (diskDate)
    {
        if ([date compare:diskDate] != NSOrderedSame ) {
            NSTimeInterval diff = [date timeIntervalSinceDate:diskDate];
            if (diff == 3600) return NO; //something fishy with DST
            return YES;
        }
    }
    
    return NO;
}

-(BOOL)fileSizesAndDatesMatch:(NSURL*)first withFile:(NSURL*)second
{
    NSNumber *sizeFirst = nil;
    NSNumber *sizeSecond = nil;
    NSError *err = nil;
    [first getResourceValue:&sizeFirst forKey:NSURLFileSizeKey error:&err];
    [second getResourceValue:&sizeSecond forKey:NSURLFileSizeKey error:&err];
    if (sizeFirst && sizeSecond)
    {
        if ([sizeFirst integerValue] != [sizeSecond integerValue]) {
            return NO;
        }
    }else{
        NSLog(@"Can't get size for %@ %@ %@",[first path],[second path],err);
        return YES;
    }
    
    NSDate *dateFirst = nil;
    NSDate *dateSecond = nil;   
    [first getResourceValue:&dateFirst forKey:NSURLContentModificationDateKey error:&err];
    [second getResourceValue:&dateSecond forKey:NSURLContentModificationDateKey error:&err];
    if (dateFirst && dateSecond)
    {
        if ([dateFirst compare:dateSecond] != NSOrderedSame ) {
            return NO;
        }
    }else{
        NSLog(@"Can't get dates for %@ %@ %@",[first path],[second path],err);
        return YES;        
    }
    
    return YES;
}

-(NSDictionary*)enumDir:(NSString*)rootPath
{
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableArray *dupes = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableDictionary *filenamePaths = [NSMutableDictionary dictionaryWithCapacity:1];
    
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:rootPath];
    
    NSString *file;
    while (file = [dirEnum nextObject])
    {
        NSString *fullPath = [rootPath stringByAppendingPathComponent:file];
        NSURL *url = [NSURL fileURLWithPath:fullPath];
        if ([self isMusicFile:[url absoluteString]])
        {
            NSString *str = [[self urlEncode:[url absoluteString]] lowercaseString];
            [list addObject:str];
            //dupe check
            NSString *filename = [url lastPathComponent];
            NSString *path = [fullPath stringByReplacingOccurrencesOfString:filename withString:@""];
            if ([filenames containsObject:filename])
            {
                NSString *matchPath = [filenamePaths objectForKey:filename];
                NSURL *match = [NSURL fileURLWithPath:[matchPath stringByAppendingPathComponent:filename]];
                if ([self fileSizesAndDatesMatch:url withFile:match])
                {
                    [dupes addObject:url];
                }
            }else{
                [filenames addObject:filename];
            }
            [filenamePaths setObject:path forKey:filename];
        }
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:list,@"list",dupes,@"dupes", nil]; //list are strings, dupes are NSURLS
}

-(NSDictionary*)parseXML:(NSString*)xml
{
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableArray *casePreserved = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableArray *dupes = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableArray *dates = [NSMutableArray arrayWithCapacity:1];
    
    NSDate *lastFoundDate = nil;
    
    NSInputStream *input = [NSInputStream inputStreamWithFileAtPath:xml];
    if (!input)
    {
        NSLog(@"Failed to read %@",xml);
        return nil;
    }
    MDBufferedInputStream *bufstream = [[MDBufferedInputStream alloc] initWithInputStream:input bufferSize:4096 encoding:NSUTF8StringEncoding];
    if (!bufstream)
    {
        NSLog(@"Failed to buffer %@",xml);
        return nil;
    }
    [bufstream open];    
    NSString *line = nil;
    while ( (line = [bufstream readLine]) ) {
        if ([line rangeOfString:@"<key>Date Modified</key><date>"].location != NSNotFound ) {
            lastFoundDate = [self dateFromZulu:[self getStringCutting:@"<key>Date Modified</key><date>" and:@"</date>" fromString:line]];
        }
        if ([line rangeOfString:@"<key>Location</key><string>"].location != NSNotFound ) {
            NSString *file = [self getStringCutting:@"<key>Location</key><string>" and:@"</string>" fromString:line];
            if ([self isMusicFile:file]) {
                if ([casePreserved containsObject:file]) {
                    NSURL *url = [NSURL URLWithString:[self urlDecode:file]];
                    [dupes addObject:url];
                }else{
                    [casePreserved addObject:file];
                    [list addObject:[file lowercaseString]];
                    if (lastFoundDate){
                        [dates addObject:lastFoundDate];
                        lastFoundDate = nil;
                    }
                }
            }
        }
    }
    [bufstream close];
    
    
    if ([list count] != [dates count]) NSLog(@"Dates inconsistency %li should be %li",[dates count],[list count]);

    
    return [NSDictionary dictionaryWithObjectsAndKeys:list,@"list",dupes,@"dupes",dates,@"dates", nil]; //list are strings, dupes are NSURLS
}


-(NSString*)getStringCutting:(NSString *)prefix and:(NSString *)suffix fromString:(NSString *)string
{
    NSString *trim = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [[trim stringByReplacingOccurrencesOfString:prefix withString:@""]  stringByReplacingOccurrencesOfString:suffix withString:@""];
}


#pragma mark NSTableView datasource

-(NSArray*)arrForSelectedRowInTable:(NSTableView *)theTableView
{
    if (theTableView == inLibNotOnDiskTable) return inLibNotOnDisk;
    if (theTableView == onDiskNotInLibTable) return onDiskNotInLib;
    if (theTableView == dupesInLibTable) return dupesInLib;
    if (theTableView == dupesOnDiskTable) return dupesOnDisk;
    if (theTableView == changedOnDiskTable) return changedOnDisk;
    
    return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
    
    return [[self arrForSelectedRowInTable:theTableView] count];
    
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex
{
    NSArray *arr = [self arrForSelectedRowInTable:theTableView];
    
	NSString *ident = [theColumn identifier];
    NSURL *url = [arr objectAtIndex:rowIndex];
    
    if ([url isKindOfClass:[NSURL class]])
    {
        if ([ident isEqualToString:@"path"]) {
            return [url path];
        }else{
            if ([self isMP3:[url pathExtension]]) {
                return @"3";
            }else if ([self isAAC:[url pathExtension]]) {
                return @"A";
            }
        }
    }
    
    return nil;
}

#pragma mark NSTableView delegate

- (NSMenu *)menuForClickedRow:(NSInteger)rowIndex inTable:(NSTableView *)theTableView{
    
    NSMenu *ret = nil;
    
    NSArray *arr = [self arrForSelectedRowInTable:theTableView];
    NSURL *url = [arr objectAtIndex:rowIndex];
    
    NSString *path = [url path];

    if (path) {
        ret = [[NSMenu alloc] initWithTitle:[url lastPathComponent]];        
        [ret addItemWithTitle:[url lastPathComponent] action:nil keyEquivalent:@""];
        NSMenuItem *menuItem = [ret addItemWithTitle:@"Reveal in Finder" action:@selector(revealInFinder:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setToolTip:path];
    }

    return ret;
}

-(void)revealInFinder:(NSMenuItem*)sender
{
    NSString *path = [sender toolTip];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
}

@end
