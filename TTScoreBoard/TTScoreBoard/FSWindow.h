//
//  FSWindow.h
//  TTScoreBoard
//
//  Created by Vlad Alexa on 8/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface FSWindow : NSWindow <NSWindowDelegate,NSComboBoxDelegate,NSTextFieldDelegate> {
    NSUserDefaults *defaults;    
    IBOutlet NSTextField *firstPoints;
    IBOutlet NSTextField *secondPoints;
    IBOutlet NSTextField *firstSets;
    IBOutlet NSTextField *secondSets;
    IBOutlet NSTextField *firstName;
    IBOutlet NSTextField *secondName;
    IBOutlet NSTextField *helpText;    
    IBOutlet NSPopUpButton *matchType; 
    IBOutlet NSPopUpButton *setType;     
    IBOutlet NSComboBox *firstBox;
    IBOutlet NSComboBox *secondBox;
    BOOL advantageFirst;
    BOOL advantageSecond;
    BOOL newMatch;
    NSSpeechSynthesizer *synth;
    NSColor *redColor;
    NSColor *greenColor;
    int first_overcame_p;
    int second_overcame_p;
    int first_overcame_s;
    int second_overcame_s; 
    BOOL manualFullScreen;
    BOOL flipped;
    NSButton *fsButton;
    BOOL changedSides;
    int goal_score;
    int change_serve;
}

-(void)reset;

-(void)placeFullScreenButton;

-(void)fullScreenSizesZero:(BOOL)zero;
-(void)normalSizesZero:(BOOL)zero;

- (NSFont *)fontForText:(NSString *)text inRect:(NSRect)rect;

- (void)firstScored;
- (void)secondScored;

-(void)firstWonSet;
-(void)secondWonSet;
-(void)firstWonMatch;
-(void)secondWonMatch;

-(void)savePlayerSetStatistics;
-(void)savePlayerMatchStatistics;

-(IBAction)changeMatchType:(id)sender;
-(IBAction)changeSetType:(id)sender;
-(IBAction)help:(id)sender;

-(void)flipView:(NSView*)first withView:(NSView*)second animate:(BOOL)animate;

-(void)changeName:(NSString*)name box:(NSComboBox*)control;
- (void)populateNames:(NSComboBox*)box;

@end
