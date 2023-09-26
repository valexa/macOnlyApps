//
//  TableController.m
//  Applications
//
//  Created by Vlad Alexa on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TableController.h"

#import "ApplicationsAppDelegate.h"
#import "PopoverController.h"

@implementation TableController

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib
{
        searchTimer = nil;
        [appsTable setTarget:self];
        [appsTable setDoubleAction:@selector(doubleClick:)];    
        [appsTable setRowSizeStyle:NSTableViewRowSizeStyleMedium];       
}

-(void)dealloc
{
    [super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView { 
    if ([app.searchString length] > 0) {
        return [app.appsListSearch count];	        
    }else{
        return [app.appsList count];	        
    }    
    return 0;
}

- (void)tableView:(NSTableView *)theTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
    NSArray *tableSort = [theTableView sortDescriptors]; 
    if (tableSort) {
        if ([app.searchString length] > 0) {
            [app.appsListSearch setArray:[app.appsListSearch sortedArrayUsingDescriptors:tableSort]];         
        }else{
            [app.appsList setArray:[app.appsList sortedArrayUsingDescriptors:tableSort]];          
        }    
        [theTableView reloadData];                
    }
    //NSLog(@"Sorting by %@",[tableSort description]);  
    [theTableView deselectAll:self];    
    [popoverController performClose:self];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
    //if we have no sort descriptor for this column create one based on it's identifier (instead of setting it for each in IB,saves time and prevents errors)
    NSSortDescriptor *desc = [theColumn sortDescriptorPrototype];
    if ([desc key] == nil) {
        NSSortDescriptor *sorter;
        if ([[theColumn.headerCell title] isEqualToString:@"name"]) {
            sorter = [[NSSortDescriptor alloc] initWithKey:[theColumn identifier] ascending:YES selector:@selector(caseInsensitiveCompare:)];
        }else{
            sorter = [[NSSortDescriptor alloc] initWithKey:[theColumn identifier] ascending:YES selector:@selector(compare:)];             
        } 
        [theColumn setSortDescriptorPrototype:sorter];
        [sorter release];
    }
    //also set sorting if none exists
    if ([[theTableView sortDescriptors] count] == 0) {
        NSTableColumn *col = [theTableView tableColumnWithIdentifier:@"path"];
        NSSortDescriptor *sorter = [col sortDescriptorPrototype];
        if (sorter) {
            [theTableView setSortDescriptors:[NSArray arrayWithObject:sorter]];            
        } 
    }
    
    NSDictionary *item;
    if ([app.searchString length] > 0) {
        item = [app.appsListSearch objectAtIndex:rowIndex];
    }else{
        item = [app.appsList objectAtIndex:rowIndex];
    }    
    if (item) {
        NSString *ident = [theColumn identifier];   
        if ([ident isEqualToString:@"icon"]) {
            return [[NSWorkspace sharedWorkspace] iconForFile:[item objectForKey:@"path"]];        
        }
        return [item objectForKey:ident];
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{ 
    NSTableView *theTableView = [aNotification object];
    
    NSInteger row = [theTableView selectedRow];
    if (row < 0) return;
    
    NSDictionary *item;
    if ([app.searchString length] > 0) {
        item = [app.appsListSearch objectAtIndex:row];
    }else{
        item = [app.appsList objectAtIndex:row];
    }   
    
    if ([[item objectForKey:@"analyzed"] isEqualToString:@"0"]) [app updateApps];
         
    if ([popoverController isShown] == YES) {
        [popoverController refreshWith:item]; 
    }
}

-(void)doubleClick:(NSTableView*)theTableView
{
    NSInteger row = [theTableView selectedRow];
    if (row < 0) return;
    
    NSDictionary *item;
    if ([app.searchString length] > 0) {
        item = [app.appsListSearch objectAtIndex:row];
    }else{
        item = [app.appsList objectAtIndex:row];
    }   
    
    if ([[item objectForKey:@"analyzed"] isEqualToString:@"1"]) {
        [popoverController setItem:item];
        [popoverController showRelativeToRect:[theTableView bounds] ofView:theTableView preferredEdge:NSMaxXEdge];        
    }
}

- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView
{
    
    NSMenu *ret = nil;  
    
    NSDictionary *item;
    if ([app.searchString length] > 0) {
        item = [app.appsListSearch objectAtIndex:row];
    }else{
        item = [app.appsList objectAtIndex:row];
    } 
    
    NSString *name = [item objectForKey:@"name"];
    NSString *path = [item objectForKey:@"path"];    
    if (name && path) {
        ret = [[NSMenu alloc] initWithTitle:name];
  
        NSMenuItem *menuItem = [ret addItemWithTitle:@"Reveal in Finder" action:@selector(revealInFinder:) keyEquivalent:@""];
        [menuItem setTarget:self];	   
        [menuItem setToolTip:path];                     
        
    }
    
    //NSLog(@"Right clicked %ld",row);    
    return [ret autorelease];
}

-(void)revealInFinder:(NSMenuItem*)sender{
    NSString *path = [sender toolTip];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
}

#pragma mark find

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    NSString *searchString = [[aNotification object] stringValue];
    if ([searchTimer isValid]) {
        [searchTimer invalidate];
        searchTimer = nil;
    }    
    searchTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(searchStart:) userInfo:searchString repeats:NO]; 
} 

-(void)searchStart:(NSTimer*)timer
{
    NSString *searchString = [timer userInfo];
    if ([searchString length] > 0) {
        [app.appsListSearch setArray:[self filterList:app.appsList forString:searchString]];
        [bottomLeftLabel setStringValue:[NSString stringWithFormat:@"Matched %ld applications",[app.appsListSearch count]]];          
    }else{
        [bottomLeftLabel setStringValue:@""];     
    }      
    [app setSearchString:searchString];    
    [appsTable reloadData];    
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

@implementation NSColor (StringOverrides)

+(NSArray *)controlAlternatingRowBackgroundColors{
	return [NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0],[NSColor whiteColor],nil];
}

@end
