//
//  ApplicationsAppDelegate.m
//  Applications
//
//  Created by Vlad Alexa on 9/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ApplicationsAppDelegate.h"
#import "VAValidation.h"

#include <Security/SecCode.h>

@implementation ApplicationsAppDelegate

@synthesize window,appsList,appsListSearch,searchString;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    int v = [VAValidation v];		
    int a = [VAValidation a];
    if (v+a != 0)  {		
        exit(v+a);
    }else {	
        //ok to run
    }       
    
    appsList = [[NSMutableArray alloc] initWithCapacity:1];
    appsListSearch = [[NSMutableArray alloc] initWithCapacity:1];    
        
    defaults = [NSUserDefaults standardUserDefaults];
    
    otoolPath = nil;
    //otoolPath = [NSString stringWithFormat:@"%@/otool",[[NSBundle mainBundle] resourcePath]];    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/otool"]) otoolPath = @"/usr/bin/otool";
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Xcode.app/Contents/Developer/usr/bin/otool"]) otoolPath = @"/Applications/Xcode.app/Contents/Developer/usr/bin/otool";
    lipoPath = nil;    
    //lipoPath = [NSString stringWithFormat:@"%@/lipo",[[NSBundle mainBundle] resourcePath]];            
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/lipo"]) lipoPath = @"/usr/bin/lipo";
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/lipo"]) lipoPath = @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/lipo";   
    
    if (otoolPath == nil || lipoPath == nil) {    
        NSString *alert = @"For best results Xcode or the Xcode Command Line Tools package should be installed";
        [[NSAlert alertWithMessageText:@"Limited information" defaultButton:NSLocalizedString(@"OK",nil) alternateButton:nil otherButton:nil informativeTextWithFormat:alert] runModal]; //localizable                                    
    }       
    
    [self setupQuery];
}

- (void)dealloc {
    [appsListSearch release];
    [appsList release];
    [query release];
    [super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}

#pragma mark query 

-(void)setupQuery{      
    query = [[NSMetadataQuery alloc] init];
    
    // To watch results send by the query, add an observer to the NSNotificationCenter
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNote:) name:nil object:query];  
    
    // We want the items in the query to automatically be sorted by the file system name; this way, we don't have to do any special sorting
    [query setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES] autorelease]]];
    
    // For the groups, we want the first grouping by the path, and the second by the name 
    //[query setGroupingAttributes:[NSArray arrayWithObjects:(id)kMDItemPath, (id)kMDItemFSName, nil]];
    
    // Set the query predicate. If the query already is alive, it will update immediately
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(kMDItemContentType == 'com.apple.application-bundle') || (kMDItemContentType == 'com.apple.application-file')"];    
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"kMDItemContentType == 'com.apple.application-file'"];  
    if ([defaults integerForKey:@"appTypes"] == 1) {
       predicate = [NSPredicate predicateWithFormat:@"kMDItemContentType == 'public.unix-executable'"]; 
    } 
    [query setPredicate:predicate];  
    
    //set the scope
    [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryLocalComputerScope]];
    
    [query setNotificationBatchingInterval:10.0];
    [query setDelegate:self];    
    
    // In case the query hasn't yet started, start it.
    [query startQuery];    
}

- (NSArray*)filteredQueryResults{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    for (NSMetadataItem *item in query.results) {
        NSString    *name = [item valueForAttribute:(NSString*)kMDItemFSName];
        NSString    *path = [item valueForAttribute:(NSString*)kMDItemPath];
        NSString    *access = [item valueForAttribute:(NSString*)kMDItemLastUsedDate];
        NSString    *version = [item valueForAttribute:(NSString*)kMDItemVersion];        
        NSString    *uses = [item valueForAttribute:@"kMDItemUseCount"];            
        NSString    *comment =[item valueForAttribute:(NSString*)kMDItemFinderComment];
        NSArray     *archi =[item valueForAttribute:(NSString*)kMDItemExecutableArchitectures];
        NSArray     *sources =[item valueForAttribute:@"kMDItemWhereFroms"];         
        NSArray     *locales =[item valueForAttribute:(NSString*)kMDItemLanguages];         
        NSNumber    *ppc = [NSNumber numberWithBool:NO];
        NSNumber    *i386 = [NSNumber numberWithBool:NO];
        NSNumber    *x86_64 = [NSNumber numberWithBool:NO];
        if (archi) {
            if ([archi containsObject:@"ppc"]) ppc = [NSNumber numberWithBool:YES];
            if ([archi containsObject:@"i386"]) i386 = [NSNumber numberWithBool:YES];
            if ([archi containsObject:@"x86_64"]) x86_64 = [NSNumber numberWithBool:YES];        
        }
        if (name && path) {
            //skip system files
            if ([path rangeOfString:@"/System/"].location != NSNotFound) {
                if ([defaults boolForKey:@"systemApps"] != YES) continue;
            }            
            //reuse data for those already analized            
            NSMutableDictionary *dict = nil;
            NSDictionary *old_dict = nil;
            for (old_dict in appsList) {
                if ([[old_dict objectForKey:@"path"] isEqualToString:path]) {
                    if ([[old_dict objectForKey:@"analyzed"] isEqualToString:@"1"]) {
                        dict = [NSMutableDictionary dictionaryWithDictionary:old_dict];
                    }
                }
            }
            if (dict == nil) dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0",@"analyzed",name,@"name",path,@"path",nil];
            if (access) [dict setObject:access forKey:@"access"];
            if (comment) [dict setObject:comment forKey:@"comment"];            
            if (archi) [dict setObject:archi forKey:@"architectures"]; 
            if (ppc) [dict setObject:ppc forKey:@"ppc"];
            if (i386) [dict setObject:i386 forKey:@"i386"];
            if (x86_64) [dict setObject:x86_64 forKey:@"x86_64"];
            if (uses) [dict setObject:uses forKey:@"uses"];
            if (sources) [dict setObject:sources forKey:@"sources"];
            if (version) [dict setObject:version forKey:@"version"];
            if (locales) [dict setObject:locales forKey:@"locales"];  
            if (locales) [dict setObject:[NSNumber numberWithInteger:[locales count]] forKey:@"locales_count"];         
            [ret addObject:dict];	                            
        }else {
            NSLog(@"Skipped (path) %@ (name) %@",path,name);
        }        
    }
       
    return ret;
}

- (void)queryNote:(NSNotification *)note {
    // The NSMetadataQuery will send back a note when updates are happening. By looking at the [note name], we can tell what is happening
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
        // The gathering phase has just started!
        //NSLog(@"query Started gathering");
        [self showMsg:@"Finding applications "];
		queryTimeout = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(queryTimeout) userInfo:nil repeats:NO];         
    } else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        // At this point, the gathering phase will be done. You may recieve an update later on.
        //NSLog(@"query Finished gathering");
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateApps) userInfo:nil repeats:NO];        
        [queryTimeout invalidate];     
        [progMsg setDoubleValue:[progMsg maxValue]];         
        [textMsg setStringValue:@"Finding applications ..... done."];        
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(closeMsg) userInfo:nil repeats:NO];        
    } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
        // The query is still gatherint results...
        //NSLog(@"query Progressing...");
        [textMsg setStringValue:@"Finding applications ..... "];  
        [progMsg setDoubleValue:[progMsg doubleValue]+0.90];  
    } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        // An update will happen when Spotlight notices that a file as added, removed, or modified that affected the search results.
        NSLog(@"An query update happened.");
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateApps) userInfo:nil repeats:NO];
    }
}

- (void)queryTimeout{
    if ([query isGathering]) {
        [query stopQuery];
        NSLog(@"Query timed out after 60 seconds, stoped.");
        [self updateApps];        
    }
}


#pragma mark message methods

- (void)showMsg:(NSString *)msg{
	[textMsg setStringValue:msg];
	[NSApp beginSheet:windowMsg modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)closeMsg{
	[NSApp endSheet:windowMsg];
	[windowMsg close];
}

- (IBAction)showPrefs:(id)sender{
	[NSApp beginSheet:windowPrefs modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)closePrefs:(id)sender{
	[NSApp endSheet:windowPrefs];
	[windowPrefs close];
}

-(void)updateApps
{     
    if (updating == YES) return;  
    updating = YES;    
    if ([bottomProgress doubleValue] != 0 && [bottomProgress doubleValue] != [bottomProgress maxValue]) {
		[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(updateApps) userInfo:nil repeats:NO];
        return;
    }       
    [appsList setArray:[self filteredQueryResults]];
    [appsTable reloadData];       
    [bottomProgress setHidden:NO];   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self analyzeApps]; 
    });    
}

-(void)analyzeApps
{       
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();    
    [bottomProgress setMaxValue:[appsList count]];    
    int count = 0;
    NSMutableArray *analyzedList = [NSMutableArray arrayWithCapacity:1];
    NSArray *enumerated = [appsList copy];
    for (NSDictionary *dict in enumerated) {
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];        
        [analyzedList addObject:[self analyzeApp:dict]];
        [pool drain];
        count++;
        if (CFAbsoluteTimeGetCurrent()-startTime > 1) [bottomRightLabel setStringValue:[NSString stringWithFormat:@"Analyzing %i of %i applications",count,[appsList count]]];
        [bottomLeftLabel setStringValue:[dict objectForKey:@"path"]];        
        [bottomProgress setDoubleValue:count];       
    }   
    [enumerated release];
    [appsList setArray:analyzedList]; 
     
    [bottomProgress setHidden:YES];  
    CFTimeInterval seconds = CFAbsoluteTimeGetCurrent()-startTime;
    NSString *message = [NSString stringWithFormat:@"Analyzed %lu applications in %1.f seconds",[appsList count],seconds];
    NSLog(@"%@",message);    
    if (seconds > 1) {
        [bottomRightLabel setStringValue:message];
        [self setSearchString:nil];
        [appsListSearch removeAllObjects]; 
        [appsTable reloadData];
    }
    updating = NO;    
}

-(NSDictionary*)analyzeApp:(NSDictionary*)dict
{
    if ([[dict objectForKey:@"analyzed"] isEqualToString:@"1"]) return dict;
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithDictionary:dict];
    NSString *path = [[[dict objectForKey:@"path"] stringByExpandingTildeInPath] stringByStandardizingPath];
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil]; 
    [ret addEntriesFromDictionary:fileAttributes];
    NSString *owner = [fileAttributes objectForKey:NSFileOwnerAccountName];
    if (owner) [ret setObject:owner forKey:@"owner"];
    NSString *modified = [fileAttributes objectForKey:NSFileModificationDate];
    if (modified) [ret setObject:modified forKey:@"modified"];   
    int perms = [[fileAttributes objectForKey:NSFilePosixPermissions] shortValue];
    if (perms > 999) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"suid"];
    
    NSString *executable;        
    NSArray *locales = nil;
    NSDictionary *appPlist = nil;    
    
    BOOL directory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&directory]) {
        if (directory == YES) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents",path]]) {	
                //osx bundle
                [ret setObject:@"OS X bundle" forKey:@"type"];                
                appPlist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist",path]];        
                if ([appPlist objectForKey:@"CFBundleExecutable"]) {
                    executable = [NSString stringWithFormat:@"%@/Contents/MacOS/%@",path,[appPlist objectForKey:@"CFBundleExecutable"]];
                }else{
                    executable = [NSString stringWithFormat:@"%@/Contents/MacOS/%@",path,[[path lastPathComponent] stringByDeletingPathExtension]];            
                } 
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents/_CodeSignature/CodeResources",path]]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"signed"];  
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents/_MASReceipt/receipt",path]]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"receipt"];                  
                locales = [self getLocalizations:[NSString stringWithFormat:@"%@/Contents/Resources/",path]];               
            }else{
                //ios bundle
                [ret setObject:@"iOS bundle" forKey:@"type"];
                appPlist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist",path]]; 
                executable = [NSString stringWithFormat:@"%@/%@",path,[[path lastPathComponent] stringByDeletingPathExtension]]; 
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/_CodeSignature/CodeResources",path]]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"signed"];
                [ret setObject:[NSNumber numberWithBool:YES] forKey:@"sandbox"]; 
                locales = [self getLocalizations:path];
            }              
        }else{
            //osx binary
            [ret setObject:@"OS X binary" forKey:@"type"];            
            appPlist = nil;             
            executable = path; 
            appPlist = [self getPackagedInfoPlist:executable];
        }
    }else{
        NSLog(@"ERROR %@ not found",path);
        return dict;
    }	    
    
    //save locales
    if ([locales count] > 0) {
        [ret setObject:locales forKey:@"locales"];                  
        [ret setObject:[NSNumber numberWithInteger:[locales count]] forKey:@"locales_count"];                                     
    }    

    //get the info.plist stuff
    NSString *identifier = [appPlist objectForKey:@"CFBundleIdentifier"];
    if (identifier) [ret setObject:identifier forKey:@"identifier"];       
    NSString *copyright = [appPlist objectForKey:@"NSHumanReadableCopyright"];
    if (copyright) [ret setObject:copyright forKey:@"copyright"];   
    NSString *version = [appPlist objectForKey:@"CFBundleShortVersionString"];
    //NSString *build = [appPlist objectForKey:@"CFBundleVersion"];    
    if (version) [ret setObject:version forKey:@"version"];   
    
    if ([appPlist objectForKey:@"LSRequiresCarbon"] || [appPlist objectForKey:@"LSPrefersCarbon"] || [appPlist objectForKey:@"LSRequiresClassic"] || [appPlist objectForKey:@"LSPrefersClassic"]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"carbon"];     

    if ([appPlist objectForKey:@"LSBackgroundOnly"] || [appPlist objectForKey:@"LSUIElement"]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"background"];         
       
    //get the architecture if don't already have it from spotlight
    if (![dict objectForKey:@"ppc"] && ![dict objectForKey:@"i386"] && ![dict objectForKey:@"x86_64"]) {
        NSArray *archi = [self getArchitectures:executable];
        if ([archi count] > 0) {
            [ret setObject:archi forKey:@"architectures"];
            if ([archi containsObject:@"ppc"]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"ppc"];
            if ([archi containsObject:@"i386"]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"i386"];
            if ([archi containsObject:@"x86_64"]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"x86_64"]; 
            if ([archi containsObject:@"armv7"]) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"x86_64"];             
        }  
    }
        
    if ([[ret objectForKey:@"signed"] boolValue] == YES) {       
        //get the certs
        NSDictionary *signInfo = [self signInfoForFile:path];
        if (signInfo) [ret addEntriesFromDictionary:signInfo];                 
        //get the entitlements        
        NSDictionary *entitlements = [self entitlementsForFile:path];
        if (entitlements) [ret setObject:entitlements forKey:@"entitlements"];        
        if ([[entitlements objectForKey:@"com.apple.security.app-sandbox"] boolValue] == YES) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"sandbox"]; 
        if ([[entitlements objectForKey:@"com.apple.developer.ubiquity-container-identifiers"] count] > 0) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"iCloud"];     
    }
    
    //get the frameworks
    NSArray *frameworks = [self getFrameworks:executable];
    NSMutableArray *privfworks = [NSMutableArray arrayWithCapacity:1];   
    NSMutableArray *pubfworks = [NSMutableArray arrayWithCapacity:1];
    for (NSString *framework in frameworks) {
        if ([framework rangeOfString:@"/PrivateFrameworks/"].location != NSNotFound) {
            [privfworks addObject:framework];
        }else{
            [pubfworks addObject:framework];
        }       
    }        
    if ([privfworks count] > 0) {
        [ret setObject:privfworks forKey:@"privfworks"];    
        [ret setObject:[NSNumber numberWithInteger:[privfworks count]] forKey:@"privfworks_count"];            
    }
    if ([pubfworks count] > 0) {
        [ret setObject:pubfworks forKey:@"pubfworks"];               
    }    
    
    NSString *gc = [self execTask:otoolPath args:[NSArray arrayWithObjects:@"-oVl",executable,nil]];    
    if (gc) {         
        //get the gc status        
        if ([gc rangeOfString:@"OBJC_IMAGE_SUPPORTS_GC"].location != NSNotFound || [gc rangeOfString:@"OBJC_IMAGE_GC_ONLY"].location != NSNotFound) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"gc"];
        //get the ARC status
        if ([gc rangeOfString:@"autorelease"].location == NSNotFound && ([gc rangeOfString:@"RO_HAS_CXX_STRUCTORS"].location != NSNotFound || [gc rangeOfString:@"__ARCLite__"].location != NSNotFound)) [ret setObject:[NSNumber numberWithBool:YES] forKey:@"arc"];  
        //get the uuid DAC20F40-AE58-FAF5-AAE7-FF36A8681B5F
        NSRange uuid = [gc rangeOfString:@"uuid "];
        if (uuid.location != NSNotFound) [ret setObject:[gc substringWithRange:NSMakeRange(uuid.location+uuid.length,36)] forKey:@"uuid"];    
        //find non native, TODO many false positives
        if ( ([gc rangeOfString:@"__DATA,__objc_msgrefs"].location == NSNotFound && [gc rangeOfString:@" application:openFile"].location != NSNotFound) ||
            ([gc rangeOfString:@"__DATA,__objc_msgrefs"].location == NSNotFound && [gc rangeOfString:@"Objective-C segment"].location == NSNotFound)            
            ){
            [ret setObject:[NSNumber numberWithBool:NO] forKey:@"native"];                     
        }else {
             [ret setObject:[NSNumber numberWithBool:YES] forKey:@"native"];            
        }
        //TODO parse LC_VERSION_MIN_MACOSX related data too maybe        
    }    
    
    [ret setObject:@"1" forKey:@"analyzed"];

    return ret;
}

-(NSArray*)getArchitectures:(NSString*)executable
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    NSString *info = [self execTask:lipoPath args:[NSArray arrayWithObjects:@"-info",executable,nil]]; 
    if ([info rangeOfString:@"can't figure out the architecture type of:"].location != NSNotFound || info == nil) {        
        NSData *data = [[NSFileHandle fileHandleForReadingAtPath:executable] readDataOfLength:12];
        NSString *header = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];    
        if (header) {
            if ([header isEqualToString:@"Joy!peffpwpc"]) {
                [ret addObject:@"ppc"];
            }else{
                NSLog(@"Can't determine architecture of %@",executable);
            }
            [header release];
        } 
    }else if ([info rangeOfString:@"Non-fat file:"].location != NSNotFound){
        NSArray *arr = [info componentsSeparatedByString:@"is architecture: "];
        if ([arr count] > 1) [ret addObject:[[arr lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];    
    }else if ([info rangeOfString:@"Architectures in the fat file:"].location != NSNotFound){
        NSArray *arr = [info componentsSeparatedByString:@"are: "];
        if ([arr count] > 1) {
            NSArray *a = [[arr lastObject] componentsSeparatedByString:@" "];
            for (NSString *str in a) {
                [ret addObject:[str stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
            }
        }
    }else{
        NSLog(@"ERROR (%@)",info);
    }
    
    return ret;    
}

-(NSArray*)getFrameworks:(NSString*)executable
{   
    NSMutableArray *ret =[NSMutableArray arrayWithCapacity:1];
    
    NSString *info = [self execTask:otoolPath args:[NSArray arrayWithObjects:@"-L",executable,nil]];
    NSArray *lines = [info componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *line in lines) {
        if ([line length] > 5 && [lines indexOfObject:line] != 0) { //skip blanks and first line
            NSString *str = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            if (![ret containsObject:str] && [str rangeOfString:@" (architecture "].location == NSNotFound) {
                [ret addObject:str];
            }
        }
    }
    return ret;    
}

-(NSArray*)getLocalizations:(NSString*)path
{
    NSMutableArray *ret =[NSMutableArray arrayWithCapacity:1];
    NSArray *dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];    
    for (NSString *name in dirs) {
        if ([[name pathExtension] isEqualToString:@"lproj"]) {
            [ret addObject:[[name stringByDeletingPathExtension] lastPathComponent]];
        }
    } 
    return ret;
}

-(NSDictionary*)getPackagedInfoPlist:(NSString*)executable
{
    NSString *inf = [self execTask:otoolPath args:[NSArray arrayWithObjects:@"-s",@"__TEXT",@"__info_plist",executable,nil]];      
    NSArray *lines = [inf componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:1];
    for (NSString *line in lines) {
        NSArray *arr = [line componentsSeparatedByString:@"\t"];
        if ([arr count] == 2) {
            NSString *hex = [[arr objectAtIndex:1] stringByReplacingOccurrencesOfString:@" " withString:@""]; 
            hex = [hex stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            [hexString appendString:hex];
        }
    }
    
    NSMutableData *asciiData= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [hexString length]/2; i++) {
        byte_chars[0] = [hexString characterAtIndex:i*2];
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [asciiData appendBytes:&whole_byte length:1]; 
    }
    
    NSPropertyListFormat format;
    NSDictionary *ret = [NSPropertyListSerialization propertyListWithData:asciiData options:0 format:&format error:nil]; 
    [asciiData release];
    return ret;
}

#pragma mark tools


-(NSString*)execTask:(NSString*)launch args:(NSArray*)args
{   
    
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:launch] != YES){
        [bottomLeftLabel setStringValue:[NSString stringWithFormat:@"%@ not found",launch]];
        return nil;
    }    
    
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
        NSString *str = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
        if (str) {
            [output appendString:str];
            [str release];      
            if ([output length] > 8000000) {
                NSLog(@"%@ data exceeds maximum, terminating, remaining output skipped",launch);            
                [output appendString:@"\n**Data exceeds maximum, remaining output skipped"];
                [task terminate];
                break;            
            }            
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
    [stdout_pipe release]; //the object is actually overretained and never released
    [task release];         
    return output;    
}


- (NSDictionary*)entitlementsForFile:(NSString*)path
{
    NSDictionary *ret = nil;
    
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    if (url) {
        SecStaticCodeRef codeRef;
        if (SecStaticCodeCreateWithPath(url, 0, &codeRef) == noErr) {
            if (SecStaticCodeCheckValidityWithErrors(codeRef, 0,  NULL, NULL) == noErr) {
                CFDictionaryRef api;
                if (SecCodeCopySigningInformation(codeRef, kSecCSRequirementInformation, &api) == noErr) {  
                    NSData *data = [(NSDictionary*)api objectForKey:(NSString*)kSecCodeInfoEntitlements];
                    if (data ) {
                        static const unsigned headerSize = 8;                   
                        NSPropertyListFormat format;
                       ret = [NSPropertyListSerialization propertyListWithData:[data subdataWithRange:NSMakeRange(headerSize,[data length] - headerSize)] options:0 format:&format error:nil];
                    }             
                }
                CFRelease(api);
            }
            CFRelease(codeRef);
        }
    }
    return ret;    
}

- (NSDictionary*)signInfoForFile:(NSString*)path
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    if (url) {
        SecStaticCodeRef codeRef;
        if (SecStaticCodeCreateWithPath(url, 0, &codeRef) == noErr) {
            if (SecStaticCodeCheckValidity(codeRef, 0,  NULL) == noErr) {
                CFDictionaryRef api;
                if (SecCodeCopySigningInformation(codeRef, kSecCSSigningInformation, &api) == noErr) {  
                    //get id
                    NSString *indentifier = [(NSDictionary*)api objectForKey:(NSString*)kSecCodeInfoIdentifier];                  
                    if (indentifier)[ret setObject:indentifier forKey:@"signature_bid"]; 
                    //get signature
                    NSArray *certs = [(NSDictionary*)api objectForKey:(NSString*)kSecCodeInfoCertificates];
                    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
                    for (id cert in certs) {
                        CFStringRef commonName;
                        SecCertificateCopyCommonName((SecCertificateRef)cert, &commonName);
                        if (commonName) {
                            [arr addObject:[NSString stringWithString:(NSString*)commonName]];
                            CFRelease(commonName);                            
                        }
                    } 
                    if ([arr count] > 0) [ret setObject:[arr lastObject] forKey:@"signature_root"];                    
                    if ([arr count] > 1) [ret setObject:[arr objectAtIndex:0] forKey:@"signature_signee"];                    
                    if ([arr count] == 3) [ret setObject:[arr objectAtIndex:1] forKey:@"signature_intermed"];                                              
                }
                CFRelease(api);
            }
            CFRelease(codeRef);
        }
    }
    return ret;    
}

@end

