//
//  AppDelegate.h
//  CSV Magic
//
//  Created by Vlad Alexa on 1/12/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LoadController.h"
#import "MainController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>{

    IBOutlet NSWindow *mainWindow;
    IBOutlet NSWindow *aboutWindow;
    
    IBOutlet LoadController *loadController;
    IBOutlet MainController *mainController;    
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) showAbout:(id)sender;
- (IBAction) openWebsite:(id)sender;
- (IBAction)openDocument:(id)sender;

@end

@interface NSColor (StringOverrides)
+(NSArray *)controlAlternatingRowBackgroundColors;
@end
