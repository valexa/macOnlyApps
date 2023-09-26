//
//  LoadController.m
//  CSV Magic
//
//  Created by Vlad Alexa on 1/27/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "LoadController.h"

@implementation LoadController

- (id)init
{
    self = [super init];
    if (self) {
        
        csvCache = [NSMutableArray arrayWithCapacity:1];
        selectArray = [NSMutableArray arrayWithCapacity:1];
        
    }
    return self;
}

-(void)awakeFromNib
{

}

-(void)mainThreadAlert:(NSDictionary*)dict
{
    NSError *error = [dict objectForKey:@"error"];
    NSString *text = [dict objectForKey:@"text"];
    NSString *info = [dict objectForKey:@"info"];
    
    if (error)
    {
           [[NSAlert alertWithError:error] beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }else{
           [[NSAlert alertWithMessageText:text defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",info] beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
}

-(void)loadCSV:(NSString*)path
{
    [dragDropView setHidden:YES];
    
    [spinner setHidden:NO];
    
    [exportButton setIdentifier:[path lastPathComponent]];
    
    NSLog(@"Loading %@",path);
    
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    [controller noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
    
    NSError *error = nil;
    NSStringEncoding *enc = NULL;
    NSString *file = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] usedEncoding:enc error:&error];
    
    if (file == nil || &enc == NULL)
    {
        NSLog(@"Error reading file at %@ %@", path, error);
        [self performSelectorOnMainThread:@selector(mainThreadAlert:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"The file couldn’t be opened because the text encoding of its contents can’t be determined",@"text",@"Encode file to UTF8 then try again",@"info", nil] waitUntilDone:NO];
        [mainController reset:self];
        [spinner setHidden:YES];
    }else{
        NSInteger count = [self countNewlinesIn:file];
        [spinner setMaxValue:count];
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        NSArray *lines = [self csvRows:file];
        NSLog(@"Loaded %.0f lines in %.1f sec",[spinner maxValue],CFAbsoluteTimeGetCurrent()-startTime);
        [csvCache setArray:lines];
        if ([lines count] >= 2)
        {
            NSArray *headers = [lines objectAtIndex:0];
            NSArray *sample = [lines objectAtIndex:1];
            if ([headers count] == [sample count])
            {
                int row = 0;
                for (NSString *name in headers)
                {
                    NSNumber *check = [NSNumber numberWithBool:YES];
                    if ([[sample objectAtIndex:row]isEqualToString:@""]) check = [NSNumber numberWithBool:NO];
                    [selectArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"name",[sample objectAtIndex:row],@"sample",check,@"check", nil]];
                    row++;
                }
                [selectTable reloadData];
                [NSApp beginSheet:selectWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
            }else{
                NSLog(@"Corrupted csv file (headers:%lu content:%lu)",(unsigned long)[headers count],(unsigned long)[sample count]);
                NSString *info = [NSString stringWithFormat:@"headers:%lu content:%lu",(unsigned long)[headers count],(unsigned long)[sample count]];
                [self performSelectorOnMainThread:@selector(mainThreadAlert:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Corrupted csv file",@"text",info,@"info", nil] waitUntilDone:NO];
                [mainController reset:self];
                [spinner setHidden:YES];
            }
        }else{
            NSLog(@"Too few lines in csv file");
            [self performSelectorOnMainThread:@selector(mainThreadAlert:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Too few lines in csv file",@"text", nil] waitUntilDone:NO];
            [mainController reset:self];
            [spinner setHidden:YES];
        }
    }
    
}

- (NSInteger) countNewlinesIn:(NSString *)string
{
    NSInteger ret = 0;
    NSInteger myLength = [string length];
    NSRange uncheckedRange = NSMakeRange(0, myLength);
    for(;;) {
        NSRange foundAtRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:uncheckedRange];
        NSInteger newLocation = NSMaxRange(foundAtRange);
        if (foundAtRange.location == NSNotFound || newLocation >= myLength) return ret;
        uncheckedRange = NSMakeRange(newLocation+1, myLength-newLocation-1);
        ret++;
    }
}

-(NSArray *)csvRows:(NSString*)string //Drew McCormack
{
    NSMutableArray *rows = [NSMutableArray array];
    
    // Get newline character set
    NSMutableCharacterSet *newlineCharacterSet = (id)[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [newlineCharacterSet formIntersectionWithCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
    
    // Characters that are important to the parser
    NSMutableCharacterSet *importantCharactersSet = (id)[NSMutableCharacterSet characterSetWithCharactersInString:@",\""];
    [importantCharactersSet formUnionWithCharacterSet:newlineCharacterSet];
    
    // Create scanner, and scan string
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    while ( ![scanner isAtEnd] ) {
        BOOL insideQuotes = NO;
        BOOL finishedRow = NO;
        NSMutableArray *columns = [NSMutableArray arrayWithCapacity:10];
        NSMutableString *currentColumn = [NSMutableString string];
        @autoreleasepool{
            while ( !finishedRow ) {
                NSString *tempString;
                if ( [scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString] ) {
                    [currentColumn appendString:tempString];
                }
                
                if ( [scanner isAtEnd] ) {
                    if ( (![currentColumn isEqualToString:@""]) || ([columns count] > 0) ) [columns addObject:currentColumn];
                    finishedRow = YES;
                }
                else if ( [scanner scanCharactersFromSet:newlineCharacterSet intoString:&tempString] ) {
                    if ( insideQuotes ) {
                        // Add line break to column text
                        [currentColumn appendString:tempString];
                    }
                    else {
                        // End of row
                        [columns addObject:currentColumn];
                        finishedRow = YES;
                        [spinner incrementBy:1];
                    }
                }
                else if ( [scanner scanString:@"\"" intoString:NULL] ) {
                    if ( insideQuotes && [scanner scanString:@"\"" intoString:NULL] ) {
                        // Replace double quotes with a single quote in the column string.
                        [currentColumn appendString:@"\""];
                    }
                    else {
                        // Start or end of a quoted string.
                        insideQuotes = !insideQuotes;
                    }
                }
                else if ( [scanner scanString:@"," intoString:NULL] ) {
                    if ( insideQuotes ) {
                        [currentColumn appendString:@","];
                    }
                    else {
                        // This is a column separating comma
                        [columns addObject:currentColumn];
                        currentColumn = [NSMutableString string];
                        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
                    }
                }
            }
        }
        if ( [columns count] > 0 ) [rows addObject:columns];
    }
    
    return rows;
}

-(IBAction)checkAll:(id)sender
{
    for (int i=0; i < [selectArray count]; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[selectArray objectAtIndex:i]];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"check"];
        [selectArray setObject:dict atIndexedSubscript:i];
    }
    [selectTable reloadData];
}

-(IBAction)checkNone:(id)sender
{
    for (int i=0; i < [selectArray count]; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[selectArray objectAtIndex:i]];
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"check"];
        [selectArray setObject:dict atIndexedSubscript:i];
    }
    [selectTable reloadData];
}

-(IBAction)checkBox:(id)sender
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[selectArray objectAtIndex:[selectTable selectedRow]]];
    NSNumber *check = [dict objectForKey:@"check"];
    if ([check boolValue]) {
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"check"];
    }else{
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"check"];
    }
    [selectArray setObject:dict atIndexedSubscript:[selectTable selectedRow]];
}

-(IBAction)closeSheet:(id)sender
{
    NSMutableArray *rawArray = [NSMutableArray arrayWithCapacity:1];
    
    for (NSArray *line in csvCache) {
        int col = 0;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
        for (NSString *str in line)
        {
            if (col < [selectArray count])
            {
                if ([[[selectArray objectAtIndex:col] objectForKey:@"check"] boolValue]) {
                    [arr addObject:str];
                }
            }else{
                NSLog(@"error on %@",line);
            }
            col++;
        }
        //make sure we have at least one non empty item
        BOOL nonempty = NO;
        for (NSString *line in arr)
        {
            if ([line length] > 0)
            {
                nonempty = YES;
            }
        }
        if (nonempty) [rawArray addObject:arr];
    }
    
    if ([rawArray count] > 0)
    {
        [mainController.headersArray addObjectsFromArray:[rawArray objectAtIndex:0]];
        [rawArray removeObjectAtIndex:0];
    }
    
    for (NSArray *row in rawArray)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
        for (NSString *item in row)
        {
            NSInteger index = [row indexOfObject:item];
            [dict setObject:item forKey:[mainController.headersArray objectAtIndex:index]];
        }
        [mainController.filteredArray addObject:dict];
    }
    
    [mainController.unfilteredArray addObjectsFromArray:mainController.filteredArray];
    
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
    
    [csvCache removeAllObjects];
    
    [selectArray removeAllObjects];    
    [selectTable reloadData];
    
    [mainController load:self];
    //[mainController delayedKVO:[NSNumber numberWithBool:YES]];
    
    [spinner setHidden:YES];
}

#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
    return [selectArray count];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex
{
    
    //if we have no sort descriptor for this column create one based on it's identifier (instead of setting it for each in IB,saves time and prevents errors)
    NSSortDescriptor *desc = [theColumn sortDescriptorPrototype];
    if ([desc key] == nil) {
        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:[theColumn identifier] ascending:YES selector:@selector(caseInsensitiveCompare:)];
        [theColumn setSortDescriptorPrototype:sorter];
    }
    
	NSString *ident = [theColumn identifier];
    
    NSDictionary *dict = [selectArray objectAtIndex:rowIndex];
    
    return [dict objectForKey:ident];
}

- (void)tableView:(NSTableView *)theTableView didClickTableColumn:(NSTableColumn *)theColumn
{
    //NSLog(@"Sorting by %@",[theColumn identifier]);
}

- (void)tableView:(NSTableView *)theTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray *tableSort = [theTableView sortDescriptors];
    if (tableSort) {
        [selectArray sortUsingDescriptors:tableSort];
        [theTableView reloadData];
        [theTableView deselectAll:self];
        //NSLog(@"Sorted by %@",[tableSort description]);
    }
}


@end
