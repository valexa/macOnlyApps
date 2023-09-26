//
//  NotifCreateController.h
//  NSMonitor
//
//  Created by Vlad Alexa on 12/19/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NotifCreateController : NSWindowController <NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate>{
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *objField;
    IBOutlet NSTextField *keyField;
    IBOutlet NSTextField *valueField; 
    IBOutlet NSTableView *theTable;
    IBOutlet NSButton *plusButton;
    IBOutlet NSButton *sendButton;    
    NSMutableArray *items;
}

-(IBAction)addToDict:(id)sender;
-(IBAction)delFromDict:(id)sender;

- (IBAction)createNotificationSend:(id)sender;

@end
