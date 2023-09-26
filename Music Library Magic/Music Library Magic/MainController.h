//
//  MainController.h
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/2/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainController : NSViewController <NSTableViewDataSource,NSTableViewDelegate>{
    
    NSMutableString *libraryPath;
    NSMutableArray *diskPaths;
    
    NSMutableArray *onDiskNotInLib;
    NSMutableArray *inLibNotOnDisk;
    NSMutableArray *dupesInLib;
    NSMutableArray *dupesOnDisk;
    NSMutableArray *changedOnDisk;
    
    IBOutlet NSTableView *onDiskNotInLibTable;
    IBOutlet NSTableView *inLibNotOnDiskTable;
    IBOutlet NSTableView *dupesInLibTable;
    IBOutlet NSTableView *dupesOnDiskTable;
    IBOutlet NSTableView *changedOnDiskTable;
    
    IBOutlet NSView *statusView;
    IBOutlet NSToolbarItem *statusItem;
    IBOutlet NSButton *refreshButton;
    IBOutlet NSProgressIndicator *refreshSpinner;
    IBOutlet NSTextField *statusText;
    
    IBOutlet NSSegmentedControl *segments;
    IBOutlet NSTextField *dragDropText;
    IBOutlet NSButton *dragDropButton;
    IBOutlet NSView *dragDropView;
}

-(IBAction)refresh:(id)sender;
-(IBAction)segmentChange:(id)sender;
-(IBAction)doneDragDrop:(id)sender;

@end
