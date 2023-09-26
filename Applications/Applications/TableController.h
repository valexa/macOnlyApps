//
//  TableController.h
//  Applications
//
//  Created by Vlad Alexa on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VATableView.h"

@class ApplicationsAppDelegate;
@class PopoverController;

@interface TableController : NSObject <NSTableViewDataSource,NSTableViewDelegate,VATableViewDelegate>{

    IBOutlet ApplicationsAppDelegate *app; 
    IBOutlet NSTableView *appsTable;
    IBOutlet NSTextField *bottomLeftLabel;    
    IBOutlet PopoverController *popoverController;
    NSTimer *searchTimer;
}

-(NSArray*)filterList:(NSArray*)source forString:(NSString*)query;
- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView;

@end

@interface NSColor (StringOverrides)
+(NSArray *)controlAlternatingRowBackgroundColors;
@end