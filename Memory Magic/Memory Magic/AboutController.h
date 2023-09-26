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
	IBOutlet NSButton *tweetButton;    
}

-(IBAction) openWebsite:(id)sender;

-(IBAction) startToggle:(id)sender;

-(IBAction)force:(id)sender;

-(IBAction)tweetPush:(id)sender;

@end
