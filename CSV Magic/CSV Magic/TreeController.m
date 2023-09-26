//
//  TreeController.m
//  CSV Magic
//
//  Created by Vlad Alexa on 1/22/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "TreeController.h"

@implementation TreeController

- (id)init
{
    self = [super init];
    if (self) {

        tree = [NSMutableArray arrayWithCapacity:1];
        uniques = [NSMutableArray arrayWithCapacity:1];
        
    }
    return self;
}

-(void)awakeFromNib
{
        [mainController addObserver:self forKeyPath:@"filteredArray" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [uniques removeAllObjects];
    
    NSInteger count = 0;
    for (NSDictionary *dict in mainController.filteredArray) count += [mainController.headersArray count];
    if (count > 100000)
    {
        [[selector cell] setPlaceholderString:@"Disabled on 100k+ sets"];
        [selector setEnabled:NO];
        return;
    }else{
        [[selector cell] setPlaceholderString:@"Select a root"];
        [selector setEnabled:YES];
    }
    
    for (NSString *header in mainController.headersArray)
    {
        [uniques addObject:[self uniquesforHeader:header]];
    }
    
    [selector reloadData];    
    if ([mainController.headersArray count] == 0) [selector deselectItemAtIndex:[selector indexOfSelectedItem]];
    
    [self selectorChange:self];
    
}

-(NSArray*)uniquesforHeader:(NSString*)header
{
//CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *dict in mainController.filteredArray)
    {
        NSString *unique = [dict objectForKey:header];
        if (unique) {
            if (![ret containsObject:unique]) [ret addObject:unique];
        }else{
            //NSLog(@"NIL %@ in %@",header,dict);
        }
    }
//NSLog(@"%lu  in %.1f sec for %@",(unsigned long)[ret count],CFAbsoluteTimeGetCurrent()-startTime,header);
    return [ret sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}


-(IBAction) selectorChange:(id)sender
{
    
    [tree removeAllObjects];
    
    if ([selector indexOfSelectedItem] >= [uniques count] || [selector indexOfSelectedItem] < 0) { [treeTable reloadData]; return; } //nothing selected

    for (NSString *parent in [uniques objectAtIndex:[selector indexOfSelectedItem]])
    {
        NSMutableArray *firstChildren = [NSMutableArray arrayWithCapacity:1];
        for (NSString *header in mainController.headersArray)
        {
            if ([mainController.headersArray indexOfObject:header] == [selector indexOfSelectedItem]) continue;
            NSMutableArray *secondChildren = [NSMutableArray arrayWithCapacity:1];
            for (NSDictionary *dict in mainController.filteredArray)
            {
                NSString *selectedHeader = [mainController.headersArray objectAtIndex:[selector indexOfSelectedItem]];
                if ([[dict objectForKey:selectedHeader] isEqualTo:parent])
                {
                    NSString *child = [dict objectForKey:header];
                    if (child && ![child isEqualToString:@""])
                    {
                        if (![secondChildren containsObject:child]) [secondChildren addObject:child];
                    }
                }
            }
            if ([secondChildren count] > 0) [firstChildren addObject:[NSDictionary dictionaryWithObjectsAndKeys:secondChildren,@"children",header,@"title", nil]];
        }
        [tree addObject:[NSDictionary dictionaryWithObjectsAndKeys:firstChildren,@"children",parent,@"title", nil]];
    }
    
    [treeTable reloadData];
    
}

#pragma mark NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [mainController.headersArray count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (index < [mainController.headersArray count])
    {
        return [mainController.headersArray objectAtIndex:index];
    }else{
        NSLog(@"Out of bounds %li",(long)index);
    }
    
    return nil;
}

#pragma  mark NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    
    if ([item isKindOfClass:[NSDictionary class]])
    {
        if ([[item objectForKey:@"children"] count] > 0)
        {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    
    if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        return [tree count];
    }
    
    if ([item isKindOfClass:[NSDictionary class]])
    {
        return [[item objectForKey:@"children"] count];
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{

	if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        return [tree objectAtIndex:index];
    }
    
    if ([item isKindOfClass:[NSDictionary class]])
    {
        return [[item objectForKey:@"children"] objectAtIndex:index];
    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item
{
   
    if ([[theColumn identifier] isEqualToString:@"count"])
    {
        if ([item isKindOfClass:[NSDictionary class]])
        {
            return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu",(unsigned long)[[item objectForKey:@"children"] count]] attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName]];
        }else{
            return nil;
        }
    }
    
    if ([item isKindOfClass:[NSDictionary class]])
    {
        return [item objectForKey:@"title"];
    }
    
    return item;
    
}

@end
