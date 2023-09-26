//
//  TableController.m
//  NSMonitor
//
//  Created by Vlad Alexa on 10/18/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import "TableController.h"

@implementation TableController

@synthesize theTable;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        if (![NSBundle loadNibNamed:@"PopOver" owner:self]) {
            NSLog(@"Error loading PopOver.xib");
        }           
        [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(perMinute:) userInfo:nil repeats:YES];           
        list = [NSMutableArray arrayWithCapacity:1];
        listSearch = [NSMutableArray arrayWithCapacity:1];    
        searchTimer = nil;  
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:nil]; 
        stickScrollToBottom = YES;
    }
    
    return self;
}

-(void)awakeFromNib
{
    //gets called twice because we are PopOver.xib file's owner
    [theTable setTarget:self];
    [theTable setDoubleAction:@selector(doubleClick:)];
    //[theTable setRowSizeStyle:NSTableViewRowSizeStyleMedium]; 
    NSClipView *clipView = (NSClipView*)[theTable superview];
    if (clipView) {
        [clipView setPostsBoundsChangedNotifications:YES];           
    }    
}

-(void)newItem:(NSDictionary*)item
{
    //[list insertObject:item atIndex:0];
    //if ([list count] > 10000) [list removeLastObject];  
    
    [list addObject:item];
    if ([list count] > 10000) [list removeObjectAtIndex:0];      

    if (![reloadTimer isValid]) {      
        reloadTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timedReload:) userInfo:nil repeats:NO];  
    }      
}

-(IBAction)clearList:(id)sender
{
    [list removeAllObjects];
    [listSearch removeAllObjects];    
    [theTable reloadData];
    [theTab setLabel:[theTable identifier]]; 
    [theTab setIdentifier:@"0"];
    [bottomLabel setStringValue:@"0 items"];   
    [statsLabel setTag:0];
}

-(void)timedReload:(NSTimer*)timer
{    
    [self factorStatistics];
    
    [theTab setLabel:[NSString stringWithFormat:@"%@ (%i)",[theTable identifier],[list count]]];    
    [theTab setIdentifier:[NSString stringWithFormat:@"%i",[list count]]];  
    
    if ([searchString length] > 0) { 
        [listSearch setArray:[self filterList:list forString:searchString]];
        [bottomLabel setStringValue:[NSString stringWithFormat:@"%ld matches",[listSearch count]]];           
    }else{
        [bottomLabel setStringValue:[NSString stringWithFormat:@"%i items",[list count]]];         
    }      
       
    //applies the sort order
    [self tableView:theTable sortDescriptorsDidChange:[theTable sortDescriptors]];     
    
    //reloads
    [theTable reloadData];
    
    //scrolls to bottom
    if (stickScrollToBottom == YES) [self scrollToBottom];
     
}

-(void)perMinute:(NSTimer*)timer
{
    itemsPerMinute = [list count] - [statsLabel tag]; 
    [statsLabel setTag:[list count]];
}

-(void)factorStatistics
{
    float total = 0.0;
    NSMutableDictionary *stats = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSDictionary *item in list) {
        NSString *field = [item objectForKey:@"type"];    
        if (!field || [item objectForKey:@"node"]) field = [item objectForKey:@"name"]; //prio is type for all tabs with no node col in table
        if (field) {
            NSNumber *count = [stats objectForKey:field];
            [stats setObject:[NSNumber numberWithInt:[count intValue]+1] forKey:field];
            total++;
        }
    }
    
    NSMutableString *percentages = [NSMutableString stringWithCapacity:1];    
    
    NSArray *sortedStats = [[[stats keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects]; //sort and reverse   
    
    for (NSString *item in sortedStats) {
        NSNumber *count = [stats objectForKey:item];
        [percentages appendFormat:@"%.f%% %@ ",([count intValue]/total)*100,item];
    }
    
    int perminute = 0;
    if (itemsPerMinute > 0) {
        perminute = itemsPerMinute;    
    }else{
        perminute = [list count];            
    }   
    
    [statsLabel setStringValue:[NSString stringWithFormat:@"%ld/minute (%@)",perminute,percentages]];    
}

#pragma mark tableview

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView { 
    if ([searchString length] > 0) {
        return [listSearch count];	        
    }else{
        return [list count];	        
    }    
    return 0;
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
    }
    /*
    //also set sorting if none exists
    if ([[theTableView sortDescriptors] count] == 0) {
        NSTableColumn *col = [theTableView tableColumnWithIdentifier:@"time"];
        NSSortDescriptor *sorter = [col sortDescriptorPrototype];
        if (sorter) {
            [theTableView setSortDescriptors:[NSArray arrayWithObject:sorter]];            
        } 
    }
    */
    
    NSDictionary *item;
    if ([searchString length] > 0) {
        if ([listSearch count] <= rowIndex) return nil;
        item = [listSearch objectAtIndex:rowIndex];
    }else{
        if ([list count] <= rowIndex) return nil;
        item = [list objectAtIndex:rowIndex];
    }    
    if (item) {
        NSString *ident = [theColumn identifier];   
        id ret = [item objectForKey:ident];
        if ([ident isEqualToString:@"icon"]) {
            return [NSImage imageNamed:[item objectForKey:@"icon_type"]];        
        } else if ([ret isKindOfClass:[NSString class]]) {
            return ret;            
        }else if ([ret isKindOfClass:[NSDictionary class]]){
            NSMutableString *str = [NSMutableString stringWithString:@" "];
            for (NSString *key in ret) {
                [str appendFormat:@" %@,",key];
            }
            return [str substringToIndex:[str length]-1];
        }else if ([ret isKindOfClass:[NSDate class]]){
            return [NSDateFormatter localizedStringFromDate:ret dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];             
        } else {    
            return [ret description];                        
        }
    }    
    return nil;
}


#pragma mark table sort

- (void)tableView:(NSTableView *)theTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
    NSArray *tableSort = [theTableView sortDescriptors]; 
    if (tableSort) {
        if ([searchString length] > 0) {
            [listSearch setArray:[listSearch sortedArrayUsingDescriptors:tableSort]];         
        }else{
            [list setArray:[list sortedArrayUsingDescriptors:tableSort]];          
        }                   
    }
    //NSLog(@"Sorting by %@",[tableSort description]);     
}

#pragma mark table popover

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSTableView *theTableView = [aNotification object];
    
    NSInteger row = [theTableView selectedRow];
    if (row < 0) return;
    
    NSDictionary *item;
    if ([searchString length] > 0) {
        if ([listSearch count] <= row) return;        
        item = [listSearch objectAtIndex:row];
    }else{
        if ([list count] <= row) return;
        item = [list objectAtIndex:row];
    }   
    
    if ([popoverController isShown] == YES) {
        [popoverController refreshWith:item]; 
    }
}

-(void)doubleClick:(NSTableView*)theTableView
{
    NSInteger row = [theTableView selectedRow];
    if (row < 0) return;
    
    NSDictionary *item;
    if ([searchString length] > 0) {
        if ([listSearch count] <= row) return;        
        item = [listSearch objectAtIndex:row];
    }else{
        if ([list count] <= row) return;        
        item = [list objectAtIndex:row];
    }   
    
    [popoverController setItem:item];
    [popoverController showRelativeToRect:[theTableView bounds] ofView:theTableView preferredEdge:NSMaxXEdge];       
}

#pragma mark table rightclick

- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView
{
    
    NSMenu *ret = nil;  
    
    NSDictionary *item;
    if ([searchString length] > 0) {
        if ([listSearch count] <= row) return nil;        
        item = [listSearch objectAtIndex:row];
    }else{
        if ([list count] <= row) return nil;        
        item = [list objectAtIndex:row];
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
    return ret;
}

-(void)revealInFinder:(NSMenuItem*)sender{
    NSString *path = [sender toolTip];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
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
    if ([string length] > 0) {
        [listSearch setArray:[self filterList:list forString:string]];
        [bottomLabel setStringValue:[NSString stringWithFormat:@"%ld matches",[listSearch count]]];          
    }else{
        [bottomLabel setStringValue:[NSString stringWithFormat:@"%i items",[list count]]];   
    }      
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

#pragma mark scrolling

- (void)scrollToBottom
{
    NSClipView *clipView = (NSClipView*)[theTable superview]; 
    NSScrollView *scrollview = (NSScrollView*)[clipView superview];
    NSPoint newScrollOrigin;
    
    if ([[scrollview documentView] isFlipped]) {
        newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scrollview documentView] frame])-NSHeight([[scrollview contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0,0.0);
    }
    
    [[scrollview documentView] scrollPoint:newScrollOrigin];    
}

-(void)boundsDidChange:(NSNotification*)notif
{
    NSClipView *clipView = (NSClipView*)[theTable superview]; 
    if ([notif object] == clipView) {
        NSScrollView *scrollview = (NSScrollView*)[clipView superview]; 
        NSView *doc = [scrollview documentView];        
        float toBottom = doc.bounds.size.height-clipView.bounds.origin.y;      
        if (toBottom < 707) {
            //NSLog(@"Scrolled to %f of bottom",toBottom);              
            stickScrollToBottom = YES;
        }else {
            stickScrollToBottom = NO;            
        }
    }
}

@end
