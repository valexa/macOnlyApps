//
//  MenuBar.h
//  Files
//
//  Created by Vlad Alexa on 5/23/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MenuBarIcon.h"

@interface MenuBar : NSObject <NSMenuDelegate> {
@private
	NSStatusItem *_statusItem;

    MenuBarIcon *menuBarIcon;
        
    IBOutlet NSPopover *popOver;
    IBOutlet NSPopover *popOverBack;
    IBOutlet NSPopover *popOverAdvanced;
    
    IBOutlet NSView *slideView;
    
    IBOutlet NSTextField *memLabel;
    IBOutlet NSTextField *pieLabel;
    IBOutlet NSTextField *swapLabel;
    
    IBOutlet NSButton *advButton;
    
}

-(IBAction)flipToBack:(id)sender;
-(IBAction)flipToFront:(id)sender;
-(IBAction)flipToAdvanced:(id)sender;

-(IBAction)quit:(id)sender;

-(IBAction)togleOnTop:(id)sender;

@end
