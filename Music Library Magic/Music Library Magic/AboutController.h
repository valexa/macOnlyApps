//
//  AboutController.h
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/2/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AboutController : NSViewController{

    IBOutlet NSWindow *aboutWindow;
}

-(IBAction)openWebsite:(id)sender;
-(IBAction)showAbout:(id)sender;
-(IBAction)closeSheet:(id)sender;

@end
