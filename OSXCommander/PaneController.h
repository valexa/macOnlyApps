//
//  PaneController.h
//  OSXCommander
//
//  Created by Vlad Alexa on 11/6/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PaneController : NSObject {

	NSString *paneName;		
    IBOutlet NSView *fileView;
    IBOutlet NSView *listView;
	IBOutlet NSTextField *bottomInf;
	IBOutlet NSComboBox *topPath;	
	IBOutlet NSPopUpButton *topVol;
}

@property (nonatomic, assign) NSString *paneName;

- (id)theName:(NSString *)name theType:(NSString *)type theSender:(id)sender;
-(void)makePane:(NSString*)name sender:(id)sender type:(id)type;

@end
