//
//  AboutController.h
//  Files
//
//  Created by Vlad Alexa on 5/24/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AboutController : NSObject{
    NSUserDefaults *defaults;    
	IBOutlet NSButton *startToggle;
	IBOutlet NSButton *gestureToggle;
	IBOutlet NSButton *shortcutToggle;
    IBOutlet NSTextField *shortcutText;
	IBOutlet NSButton *tweetButton;
}

-(IBAction) openWebsite:(id)sender;

-(IBAction) startToggle:(id)sender;

-(IBAction)tweetPush:(id)sender;

-(IBAction) gestureToggle:(id)sender;

@end
