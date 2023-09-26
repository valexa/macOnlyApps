//
//  LogsController.h
//  DiskFailure
//
//  Created by Vlad Alexa on 2/21/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CloudController;

@interface LogsController : NSObject <NSOutlineViewDelegate,NSOutlineViewDataSource> {
    IBOutlet CloudController *cloudController;
    IBOutlet NSOutlineView *theTable;
    NSMutableArray *list; 
    NSMutableArray *listSearch;
    NSString *searchString; 
    NSTimer *searchTimer; 
    BOOL allMachines;
    NSString *hostName;
    NSString *serial;    
}

- (NSString *) volumeNameWithBSDPath:(NSString *)bsdPath;
-(NSString*)bsdPathFromLog:(NSString*)line;
-(NSString*)machineFromLog:(NSArray*)log;

-(NSArray*)filterList:(NSArray*)source forString:(NSString*)query;
-(IBAction)performFindPanelAction:(id)sender;
-(void)getData;
-(NSString *)hostName;

@end
