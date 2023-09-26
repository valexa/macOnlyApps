//
//  MainController.m
//  CSV Magic
//
//  Created by Vlad Alexa on 1/17/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "MainController.h"


@implementation MainController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.filteredArray = [NSMutableArray arrayWithCapacity:1];
        self.unfilteredArray = [NSMutableArray arrayWithCapacity:1];
        self.headersArray = [NSMutableArray arrayWithCapacity:1];
        
        filtersCount = 1;
        
    }
    return self;
}

-(void)awakeFromNib
{
    [resetButton setEnabled:NO];
    [exportButton setEnabled:NO];
    [headerView setHidden:YES];
    [splitView setHidden:YES];
    [toolbar setSelectedItemIdentifier:@"List"];
    [filterCount setStringValue:@"Filters: 1"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterChanged:) name:@"NSRuleEditorRowsDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:@"NSControlTextDidChangeNotification" object:nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar;
{
    return [NSArray arrayWithObjects:@"List",@"Tree",@"Assoc", nil];
}


#pragma mark filter

-(void)textChanged:(NSNotification*)notif
{
    //NSTextView *view = [[notif userInfo] objectForKey:@"NSFieldEditor"];
    
    if ([notif.object isKindOfClass:[NSTextField class]])
    {
        //NSTextField *field = (NSTextField *)notif.object;
        //NSLog(@"%@",[field stringValue]);
    }
    if ([notif.object isKindOfClass:[NSPredicateEditor class]])
    {
        [self filter];
    }

}

-(NSArray*)predicates
{
    NSArray *or = [[predicateEditor.predicate predicateFormat] componentsSeparatedByString:@" OR "];
    NSArray *and = [[predicateEditor.predicate predicateFormat] componentsSeparatedByString:@" AND "];
    NSArray *predicates = nil;
    
    if ([or count] > [and count]) {
        predicates = or;
    }else{
        predicates = and;
    }
    
    return predicates;
}

-(NSString*)anyString
{
    for (NSString *str in [self predicates])
    {
        if ([str rangeOfString:@"\"⧼ANY⧽\" "].location != NSNotFound)
        {
            NSArray *split = [str componentsSeparatedByString:@"\""];
            if ([split count] == 5)
            {
                return [split objectAtIndex:3];
            }
        }
    }
    return @"";
}

-(BOOL)areAllFilterStringsEmpty
{
    for (NSString *str in [self predicates])
    {
        if ([str rangeOfString:@"\"⧼ANY⧽\" "].location != NSNotFound)
        {
            NSArray *split = [str componentsSeparatedByString:@"\""];
            if ([split count] == 5)
            {
                if ([[split objectAtIndex:3] length] > 0)
                {
                    return NO;
                }
            }
        }else{
            NSArray *split = [str componentsSeparatedByString:@"\""];
            if ([split count] == 3)
            {
                if ([[split objectAtIndex:1] length] > 0)
                {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

-(void)filterChanged:(NSNotification*)notif
{
    NSArray *predicates = [self predicates];
    [filterCount setStringValue:[NSString stringWithFormat:@"Filters: %lu",(unsigned long)[predicates count]]];
    filtersCount = [predicates count];
    
    [self fitFilters];
    
    [self filter];
}

-(void)filter
{
    if ([self areAllFilterStringsEmpty])
    {
        [_filteredArray setArray:_unfilteredArray];
    }
    else if ( [[predicateEditor.predicate predicateFormat] rangeOfString:@"\"⧼ANY⧽\" "].location != NSNotFound)
    {
        [_filteredArray setArray:_unfilteredArray];
        //substitite our ALL predicate for an actual one that contains all headers
        if (![[self anyString] isEqualToString:@""]) [_filteredArray filterUsingPredicate:[self allPredicate:[self anyString]]];
    }
    else if (![[predicateEditor.predicate predicateFormat] isEqualToString:@"FALSEPREDICATE"])
    {
        [_filteredArray setArray:_unfilteredArray];
        [_filteredArray filterUsingPredicate:predicateEditor.predicate];
    }
    
    [filterText setStringValue:[NSString stringWithFormat:@"(%lu of %lu total entries visible)",(unsigned long)[_filteredArray count],(unsigned long)[_unfilteredArray count]]];
    
    [_filteredArray sortUsingDescriptors:[filtersTable sortDescriptors]];
    
    [filtersTable reloadData];
    [filtersTable deselectAll:self];
    
    [self performSelector:@selector(delayedKVO:) withObject:[NSNumber numberWithBool:NO] afterDelay:1];
    delay++;
    
}

-(void)delayedKVO:(NSNumber*)force
{
    if (delay < 2 || [force boolValue] == YES)
    {
        [self willChangeValueForKey:@"filteredArray"];
        [self didChangeValueForKey:@"filteredArray"];
        delay = 0;
    }else{
        delay--;
    }
}

-(NSPredicate*)allPredicate:(NSString*)searchText
{
    NSMutableArray *subpredicates = [NSMutableArray array];
    for (NSString *key in _headersArray)
    {
        NSPredicate *subpredicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", key, searchText];
        [subpredicates addObject:subpredicate];
    }
    NSPredicate *all = [NSCompoundPredicate orPredicateWithSubpredicates:subpredicates];
    return all;
}

-(void)rebuildPredicates
{
    NSMutableArray *templates = [NSMutableArray arrayWithArray:predicateEditor.rowTemplates];
    NSPredicateEditorRowTemplate *temp = [templates lastObject];
    NSMutableArray *left = [NSMutableArray arrayWithCapacity:1];
    [left addObject:[NSExpression expressionForConstantValue:@"⧼ANY⧽"]];
    for (NSString *header in _headersArray) {
        [left addObject:[NSExpression expressionForKeyPath:header]];
    }
    NSPredicateEditorRowTemplate *template = [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:left rightExpressionAttributeType:temp.rightExpressionAttributeType modifier:temp.modifier operators:temp.operators options:temp.options];
    [templates removeLastObject];
    [templates addObject:template];
    predicateEditor.rowTemplates = templates;
}

-(void)fitFilters
{
    if ((filtersCount+1)*25 < [splitView maxPossiblePositionOfDividerAtIndex:0])
    {
        [splitView setPosition:(filtersCount+1)*25 ofDividerAtIndex:0];
    }else{
        [splitView setPosition:[splitView maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
    }
}

#pragma mark reset


-(IBAction)changeToList:(id)sender
{
    if (![dragDropView isHidden]) return;

    [filtersView setHidden:NO];
    [filterCount setHidden:NO];
    [filterText setHidden:NO];
    //tree
    [treeView setHidden:YES];
    [treeSelector setHidden:YES];
    //assoc
    [assocView setHidden:YES];
    [rowSelector setHidden:YES];
    [colSelector setHidden:YES];
    
    [toolbar setSelectedItemIdentifier:@"List"];
}

-(IBAction)changeToTree:(id)sender
{
    if (![dragDropView isHidden]) return;

    [filtersView setHidden:YES];
    [filterCount setHidden:YES];
    [filterText setHidden:YES];
    //tree
    [treeView setHidden:NO];
    [treeSelector setHidden:NO];
    //assoc
    [assocView setHidden:YES];
    [rowSelector setHidden:YES];
    [colSelector setHidden:YES];
    
    [toolbar setSelectedItemIdentifier:@"Tree"];
}

-(IBAction)changeToAssoc:(id)sender
{
    if (![dragDropView isHidden]) return;

    [filtersView setHidden:YES];
    [filterCount setHidden:YES];
    [filterText setHidden:YES];
    //tree
    [treeView setHidden:YES];
    [treeSelector setHidden:YES];
    //assoc
    [assocView setHidden:NO];
    [rowSelector setHidden:NO];
    [colSelector setHidden:NO];
    
    [toolbar setSelectedItemIdentifier:@"Assoc"];
}

-(void)load:(id)sender
{    
    //add table columns
    for (NSString *header in _headersArray) {
        NSTableColumn *tc= [[NSTableColumn alloc] init];
        [[tc headerCell] setStringValue:header];
        tc.identifier = header;
        [filtersTable addTableColumn:tc];
    }
    
    [filtersTable reloadData];
    
    [self changeToList:self];
    
    [self rebuildPredicates];
    [predicateEditor addRow:self];
    [filterCount setStringValue:@"Filters: 1"];
    [filterText setStringValue:[NSString stringWithFormat:@"(%lu of %lu total entries visible)",(unsigned long)[_filteredArray count],(unsigned long)[_unfilteredArray count]]];
    
    [self performSelector:@selector(animateDivider:) withObject:[NSNumber numberWithInt:26] afterDelay:1];
    [self performSelector:@selector(animateDivider:) withObject:[NSNumber numberWithInt:0] afterDelay:3];
    [splitButton performSelector:@selector(setTitle:) withObject:@"⬇︎" afterDelay:4.1];
    [splitButton setTag:1];
    
    [resetButton setEnabled:YES];
    [exportButton setEnabled:YES];
    
    [headerView setHidden:NO];
    [splitView setHidden:NO];
}

-(IBAction)reset:(id)sender
{
    
    //remove table columns
    for (NSInteger i = [filtersTable numberOfColumns]-1; i > -1; i-- ) {
        [filtersTable removeTableColumn:[[filtersTable tableColumns] objectAtIndex:i]];
    }
    
    //remove filters
    for (NSInteger i = [predicateEditor numberOfRows]-1; i > -1; i-- ) {
        [predicateEditor removeRowAtIndex:i];
    }

    [self filterChanged:nil];
    
    [splitButton setTag:0];
    [splitButton setTitle:@"⬆︎"];
    
    [dragDropView setHidden:NO];
    [headerView setHidden:YES];
    [splitView setHidden:YES];
    
    [resetButton setEnabled:NO];
    [exportButton setEnabled:NO];
    
    [_headersArray removeAllObjects];
    [_filteredArray removeAllObjects];
    [_unfilteredArray removeAllObjects];
    
    [filtersTable reloadData];
    
    [self willChangeValueForKey:@"filteredArray"];
    [self didChangeValueForKey:@"filteredArray"];
}

-(IBAction)dividerPush:(id)sender
{
    if ([splitButton tag] == 0) {
        [splitButton setTag:1];
        [splitButton setTitle:@"⬇︎"];
        [splitView setPosition:[splitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
    }else{
        [splitButton setTag:0];
        [splitButton setTitle:@"⬆︎"];
        [self fitFilters];
    }
}

-(void)animateDivider:(NSNumber*)num
{
     [splitView setPosition:[num floatValue] ofDividerAtIndex:0];
}

#pragma mark export

-(IBAction)exportCSV:(id)sender
{    
    NSSavePanel *save = [NSSavePanel savePanel];
    [save setShowsHiddenFiles:YES];
    [save setTreatsFilePackagesAsDirectories:YES];
    [save setNameFieldStringValue:[exportButton identifier]];
    [save setTitle:@"Export CSV"];
    [save beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger result) {
        if(result==NSOKButton)
        {
            NSString *csv = [self createCSV:_filteredArray withColumns:_headersArray];
            NSError *err;
            [csv writeToURL:[save URL] atomically:YES encoding:NSUTF8StringEncoding error:&err];
            if (err) {
                NSLog(@"%@",[err localizedFailureReason]);
                [[NSAlert alertWithError:err] runModal];
            }
        }
    }];
}

-(NSString*)createCSV:(NSArray*)content withColumns:(NSArray*)cols
{
    NSMutableString *ret = [NSMutableString stringWithCapacity:1];
    
    //add headers
    NSMutableString *headers = [NSMutableString stringWithCapacity:1];
    for (NSString *col in cols)
    {
        [headers appendFormat:@"\"%@\",",col];
    }
    if ([headers length] > 0) [ret appendFormat:@"%@\n",[headers substringToIndex:[headers length]-1]];
    
    for (NSDictionary *row in content)
    {
        NSMutableString *line = [NSMutableString stringWithCapacity:1];
        for (NSString *col in cols)
        {
            if ([row objectForKey:col])
            {
                [line appendFormat:@"\"%@\",",[row objectForKey:col]];
            }else{
                [line appendString:@","];
            }
        }
        if ([line length] > 0) [ret appendFormat:@"%@\n",[line substringToIndex:[line length]-1]];
    }
    return ret;
}

#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
    return [_filteredArray count];
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
    
    NSDictionary *dict = [_filteredArray objectAtIndex:rowIndex];
    
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
        [_filteredArray sortUsingDescriptors:tableSort];
        [theTableView reloadData];
        [theTableView deselectAll:self];
        //NSLog(@"Sorted by %@",[tableSort description]);
    }
}

@end
