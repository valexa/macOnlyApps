//
//  PreferencesController.h
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DiskFailurePreferences;

@interface PreferencesController : NSWindowController {
@private
    NSUserDefaults    *defaults;
    DiskFailurePreferences *preferences;    
    
	IBOutlet NSView *prefView;
	IBOutlet NSSegmentedControl *startToggle;
	IBOutlet NSSegmentedControl *dockToggle; 
	IBOutlet NSLevelIndicator *timerLevel;
    IBOutlet NSTextField *refreshLabel;       
}

-(IBAction) startToggle:(id)sender;
-(IBAction) dockToggle:(id)sender;

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;
-(NSString*)refreshTimeInterval:(double)time;

@end
