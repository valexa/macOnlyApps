//
//  LoadController.h
//  CSV Magic
//
//  Created by Vlad Alexa on 1/27/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MainController.h"

@interface LoadController : NSObject <NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet MainController *mainController;
    IBOutlet NSButton *exportButton;
    
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSProgressIndicator *spinner;
    
    IBOutlet NSWindow *selectWindow;
    IBOutlet NSTableView *selectTable;
    
    IBOutlet NSView *dragDropView;
    
    NSMutableArray *selectArray;
    NSMutableArray *csvCache;
}

-(IBAction)closeSheet:(id)sender;
-(IBAction)checkBox:(id)sender;
-(IBAction)checkAll:(id)sender;
-(IBAction)checkNone:(id)sender;

-(void)loadCSV:(NSString*)path;

@end
