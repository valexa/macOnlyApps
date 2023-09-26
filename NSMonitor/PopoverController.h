//
//  PopoverController.h
//  Applications
//
//  Created by Vlad Alexa on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DetailsDataSource;

@interface PopoverController : NSViewController <NSPopoverDelegate>{
    DetailsDataSource *detailsDataSource;
    IBOutlet NSOutlineView *detailsOutline;       
    IBOutlet NSImageView *icon;
    IBOutlet NSPopover *popover;
    NSDictionary *item;
}

@property (strong) NSDictionary *item;

- (void)showRelativeToRect:(NSRect)positioningRect ofView:(NSView *)positioningView preferredEdge:(NSRectEdge)preferredEdge;
- (void)performClose:(id)sender;
- (void)refreshWith:(NSDictionary*)item;
- (BOOL)isShown;

@end