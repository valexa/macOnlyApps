//
//  PreferencesController.h
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DiskFailurePreferences;
@class  CloudController;

@interface MainController : NSWindowController {
@private
    NSUserDefaults    *defaults;
    DiskFailurePreferences *preferences;    
    IBOutlet CloudController *cloudController;        
	IBOutlet NSView *prefView;
    IBOutlet NSWindow *aboutWindow;      
	IBOutlet NSSegmentedControl *startToggle;
	IBOutlet NSProgressIndicator *timerProgress;    
    IBOutlet NSTextField *refreshLabel;
    IBOutlet NSTextField *adminLabel;
	IBOutlet NSButton *tweetButton;      
}

-(IBAction)tweetPush:(id)sender;
-(IBAction) openWebsite:(id)sender;
-(IBAction) showAbout:(id)sender;
-(IBAction) startToggle:(id)sender;
-(IBAction)changeMachines:(id)sender;

- (void)setAutostart:(BOOL)set;

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;
-(NSString*)refreshTimeInterval:(double)time;

@end
