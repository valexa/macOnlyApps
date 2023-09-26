//
//  TableController.h
//  NSMonitor
//
//  Created by Vlad Alexa on 10/18/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VATableView.h"
#import "PopoverController.h"

@interface TableController : NSObject <NSTableViewDataSource,NSTableViewDelegate,VATableViewDelegate>{
 
    IBOutlet NSTableView *theTable;
    IBOutlet NSTextField *bottomLabel; 
    IBOutlet NSTextField *statsLabel;     
    IBOutlet PopoverController *popoverController;
    IBOutlet NSTabViewItem *theTab;
    NSTimer *searchTimer;
    NSMutableArray *list;    
    NSMutableArray *listSearch;
    NSString *searchString;
    NSTimer *reloadTimer;
    NSInteger itemsPerMinute;
    BOOL stickScrollToBottom;
}

@property (readonly) NSTableView *theTable;

-(void)newItem:(NSDictionary*)item;
-(void)factorStatistics;

-(NSArray*)filterList:(NSArray*)source forString:(NSString*)query;
- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView;

-(IBAction)clearList:(id)sender;

- (void)scrollToBottom;

@end
