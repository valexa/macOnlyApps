//
//  CGEventsController.h
//  NSMonitor
//
//  Created by Vlad Alexa on 10/18/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CGEventsController : NSObject <NSOutlineViewDataSource,NSOutlineViewDelegate>{
 
    IBOutlet NSOutlineView *theTable;
    IBOutlet NSTextField *bottomLabel;    
    IBOutlet NSPopover *popover;
    IBOutlet NSTabViewItem *theTab;    
    NSTimer *searchTimer;
    NSMutableArray *list;    
    NSMutableArray *listSearch;
    NSString *searchString;
    NSTimer *reloadTimer;
}

-(void)newItem:(NSDictionary*)item;
-(NSArray*)filterList:(NSArray*)source forString:(NSString*)query;

-(IBAction)clearList:(id)sender;

@end
