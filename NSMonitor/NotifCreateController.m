//
//  NotifCreateController.m
//  NSMonitor
//
//  Created by Vlad Alexa on 12/19/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import "NotifCreateController.h"

@implementation NotifCreateController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        items = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    if ([[valueField stringValue] length] > 0 && [[keyField stringValue] length] > 0) {
        [plusButton setEnabled:YES];
    }else{
        [plusButton setEnabled:NO];        
    }
    
    if ([[nameField stringValue] length] > 0) {
        [sendButton setEnabled:YES];
    }else{
        [sendButton setEnabled:NO];        
    }    
}

#pragma mark tableview

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{ 
    return [items count];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex 
{
    NSString *ident = [theColumn identifier];
    NSDictionary *item = [items objectAtIndex:rowIndex];
    if ([ident isEqualToString:@"key"] || [ident isEqualToString:@"value"]) {
        return [item objectForKey:[theColumn identifier]];
    }
  
    return nil;
}

-(IBAction)addToDict:(id)sender
{
    for (NSDictionary *item in items) {
        NSString *key = [item objectForKey:@"key"];
        if ([key isEqualToString:[keyField stringValue]]) {
            [[NSAlert alertWithMessageText:@"Keys must be unique" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The key you tried to add already exists."] runModal];            
            [keyField setStringValue:@""];
            [plusButton setEnabled:NO];            
            return;
        }
    }
    
    NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:[valueField stringValue],@"value",[keyField stringValue],@"key", nil];
    [items addObject:item];
    [keyField setStringValue:@""];
    [valueField setStringValue:@""];
    [plusButton setEnabled:NO];    
    [theTable reloadData];
}

-(IBAction)delFromDict:(id)sender
{
    NSInteger row = [theTable selectedRow];
    if ([items count] > row) {
        [items removeObjectAtIndex:row];        
        [theTable reloadData];        
    }
}

- (IBAction)createNotificationSend:(id)sender
{
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSDictionary *item in items) {
        [info setObject:[item objectForKey:@"value"] forKey:[item objectForKey:@"key"]];
    }
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:[nameField stringValue] object:[objField stringValue] userInfo:info];	 
}


@end
