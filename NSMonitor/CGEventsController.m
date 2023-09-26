//
//  CGEventsController.m
//  NSMonitor
//
//  Created by Vlad Alexa on 10/18/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import "CGEventsController.h"

@implementation CGEventsController

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        list = [NSMutableArray arrayWithCapacity:1];
        listSearch = [NSMutableArray arrayWithCapacity:1];    
        searchTimer = nil;        
    }
    
    return self;
}

-(void)awakeFromNib
{
    [theTable setTarget:self];   
    [theTable setDoubleAction:@selector(doubleClick:)];     
    //[theTable setRowSizeStyle:NSTableViewRowSizeStyleMedium];    
}

-(void)newItem:(NSDictionary*)item
{        
    [list insertObject:item atIndex:0];    
    if ([list count] > 10000) [list removeLastObject];
            
    if (![reloadTimer isValid]) {      
        reloadTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timedReload:) userInfo:nil repeats:NO];  
    }  
}

-(IBAction)clearList:(id)sender
{
    [list removeAllObjects];
    [listSearch removeAllObjects];    
    [theTable reloadData];
    [theTab setLabel:@"CGEvents"]; 
    [theTab setIdentifier:@"0"];
    [bottomLabel setStringValue:@"0 items"];   
}

-(void)timedReload:(NSTimer*)timer
{    
    [theTab setLabel:[NSString stringWithFormat:@"CGEvents (%i)",[list count]]];    
    [theTab setIdentifier:[NSString stringWithFormat:@"%i",[list count]]];    
    
    if ([searchString length] > 0) { 
        [listSearch setArray:[self filterList:list forString:searchString]];
        [bottomLabel setStringValue:[NSString stringWithFormat:@"%ld matches",[listSearch count]]];           
    }else{
        [bottomLabel setStringValue:[NSString stringWithFormat:@"%i items",[list count]]];         
    }
    
    [self outlineView:theTable sortDescriptorsDidChange:[theTable sortDescriptors]]; //also reloads    
}

#pragma  mark NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{             
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{    

    if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        if ([searchString length] > 0) {         
            return [listSearch count];              
        }else{
            return [list count];              
        }    
    }        
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    
	if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        if ([searchString length] > 0) {         
            return [listSearch objectAtIndex:index];             
        }else{
            return [list objectAtIndex:index];             
        }        
    }
       
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item
{    
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
    if ([[outlineView sortDescriptors] count] == 0) {
        NSTableColumn *col = [outlineView tableColumnWithIdentifier:@"time"];
        NSSortDescriptor *sorter = [col sortDescriptorPrototype];
        if (sorter) {
            [outlineView setSortDescriptors:[NSArray arrayWithObject:sorter]];            
        } 
    } 
    */ 
    
    NSString *ident = [theColumn identifier];     
        
    if ([ident isEqualToString:@"icon"]) {
        return [NSImage imageNamed:[item objectForKey:@"icon_type"]];        
    } 
    
    return [item objectForKey:ident];     
}

#pragma mark table sort

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray *tableSort = [outlineView sortDescriptors]; 
    if (tableSort) {
        if ([searchString length] > 0) {
            [listSearch setArray:[listSearch sortedArrayUsingDescriptors:tableSort]];         
        }else{
            [list setArray:[list sortedArrayUsingDescriptors:tableSort]];          
        }    
        [outlineView reloadData];                
    }
    //NSLog(@"Sorting by %@",[tableSort description]);  
    [outlineView deselectAll:self];    
    [popover performClose:self];
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


@end
