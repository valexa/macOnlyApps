//
//  MainController.h
//  CSV Magic
//
//  Created by Vlad Alexa on 1/17/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MainController : NSObject <NSTableViewDataSource,NSTableViewDelegate,NSToolbarDelegate> {

    IBOutlet NSWindow *mainWindow;
    IBOutlet NSTableView *filtersTable;
        
    IBOutlet NSView *headerView;
    IBOutlet NSView *dragDropView;
    IBOutlet NSSplitView *splitView;

    IBOutlet NSToolbar *toolbar;
    IBOutlet NSButton *resetButton;
    IBOutlet NSButton *exportButton;
    IBOutlet NSButton *splitButton;

    //filter
    IBOutlet NSScrollView *filtersView;
    IBOutlet NSTextField *filterCount;
    IBOutlet NSTextField *filterText;
    //tree
    IBOutlet NSScrollView *treeView;
    IBOutlet NSComboBox *treeSelector;
    //assoc
    IBOutlet NSScrollView *assocView;
    IBOutlet NSComboBox *rowSelector;
    IBOutlet NSComboBox *colSelector;

    IBOutlet NSPredicateEditor *predicateEditor;

    NSInteger filtersCount;
    NSInteger delay;
}

@property (retain)   NSMutableArray *headersArray;
@property (retain)   NSMutableArray *filteredArray;
@property (retain)   NSMutableArray *unfilteredArray;

-(IBAction)changeToList:(id)sender;
-(IBAction)changeToTree:(id)sender;
-(IBAction)changeToAssoc:(id)sender;
-(IBAction)reset:(id)sender;
-(IBAction)exportCSV:(id)sender;
-(IBAction)dividerPush:(id)sender;

-(void)delayedKVO:(NSNumber*)force;
-(void)load:(id)sender;

@end
