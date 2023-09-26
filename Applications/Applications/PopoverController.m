//
//  PopoverController.m
//  Applications
//
//  Created by Vlad Alexa on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PopoverController.h"

#import "DetailsDataSource.h"

@implementation PopoverController

@synthesize item;

-(void)awakeFromNib
{
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self.view frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:nil];	    
    [self.view addTrackingArea:area]; 
    [area release];
    detailsDataSource = [[DetailsDataSource alloc] init]; 
    [detailsOutline setDataSource:detailsDataSource];
    [detailsOutline setDelegate:detailsDataSource];     
}

-(void)dealloc
{
    [detailsDataSource release];
    [super dealloc];
}

- (void)popoverWillShow:(NSNotification *)notification
{    
    if (item) [self refreshWith:item];    
}

-(void)mouseExited:(NSEvent *)event
{    
    //[popover performClose:self];
}

- (void)showRelativeToRect:(NSRect)positioningRect ofView:(NSView *)positioningView preferredEdge:(NSRectEdge)preferredEdge
{
    [popover showRelativeToRect:positioningRect ofView:positioningView preferredEdge:preferredEdge]; 
}

- (void)performClose:(id)sender
{
    [popover performClose:sender];
}

- (void)refreshWith:(NSDictionary*)i
{
    item = i;
    
    NSString *path = [item objectForKey:@"path"];
    if (path) {
        NSImage *img = [[NSWorkspace sharedWorkspace] iconForFile:path];
        [img setSize:NSMakeSize(157, 157)];
        if ([img isValid]) [icon setImage:img];
    }    
    
    detailsDataSource.rootItems = item;  
    [detailsOutline reloadData];
    [detailsOutline expandItem:nil expandChildren:YES];     
}

- (BOOL)isShown
{
    return [popover isShown];
}

@end
