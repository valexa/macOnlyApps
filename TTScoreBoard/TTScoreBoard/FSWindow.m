//
//  FSWindow.m
//  TTScoreBoard
//
//  Created by Vlad Alexa on 8/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FSWindow.h"
#import <QuartzCore/CoreAnimation.h>

@implementation FSWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
    self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
    if (self) {
        // Initialization code here.
        self.delegate = self;
        defaults = [NSUserDefaults standardUserDefaults];        
        redColor = [NSColor redColor];
        greenColor = [NSColor greenColor];        
        [self setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"tile"]]];  
        synth = [[NSSpeechSynthesizer alloc] initWithVoice:@"com.apple.speech.synthesis.voice.Alex"]; 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"FSWindowEvent" object:nil];	   
        
        
        fsButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        [fsButton setBordered:NO];
        [fsButton setTarget:self]; 
        [fsButton setAction:@selector(fullScreenButtonClick:)];				
        [fsButton setToolTip:@"Full Screen"];
        [fsButton setButtonType:NSMomentaryChangeButton];    
        [fsButton setImage:[NSImage imageNamed:@"fullscreen"]];         
    }
    
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];  
    [fsButton release];
    [synth release];
    [super dealloc];
}

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:@"FSWindowEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){ 
        if ([[notif object] isEqualToString:@"revokeFirstPoint"] && newMatch != YES && [firstPoints intValue] < goal_score && [secondPoints intValue] < goal_score) {
            if ( (flipped == NO && changedSides == NO) || (flipped == YES && changedSides == YES) ){
                if ([firstPoints intValue] > 0) [firstPoints setStringValue:[NSString stringWithFormat:@"%i",[firstPoints intValue]-1]];    
            }else{
                if ([secondPoints intValue] > 0) [secondPoints setStringValue:[NSString stringWithFormat:@"%i",[secondPoints intValue]-1]];                
            } 
        }
        if ([[notif object] isEqualToString:@"revokeSecondPoint"] && newMatch != YES && [firstPoints intValue] < goal_score && [secondPoints intValue] < goal_score) {
            if ( (flipped == NO && changedSides == NO) || (flipped == YES && changedSides == YES) ){
                if ([secondPoints intValue] > 0) [secondPoints setStringValue:[NSString stringWithFormat:@"%i",[secondPoints intValue]-1]];                
            }else{
                if ([firstPoints intValue] > 0) [firstPoints setStringValue:[NSString stringWithFormat:@"%i",[firstPoints intValue]-1]];
            } 
        } 
        if ([[notif object] isEqualToString:@"middle"]) {
            [self otherMouseDown:nil];
        }        
        if ([[notif object] isEqualToString:@"reset"]) {
            [self reset];
        } 
        if ([[notif object] isEqualToString:@"flip"]) {
            if (newMatch == YES) {
                if (flipped == NO) {
                    flipped = YES;
                    [helpText setStringValue:@"*screen should be facing players"];
                }else{
                    flipped = NO;
                    [helpText setStringValue:@"*screen should be facing you"];
                }
                [defaults setObject:[NSNumber numberWithBool:flipped] forKey:@"flipped"];
                [defaults synchronize];
                [self flipView:firstPoints withView:secondPoints animate:YES];
                [self flipView:firstSets withView:secondSets animate:YES]; 
                [self flipView:firstName withView:secondName animate:YES];
                [self flipView:firstBox withView:secondBox animate:YES]; 
            }else{
                [[NSAlert alertWithMessageText:@"Can not flip display" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Function not available during a match."] beginSheetModalForWindow:self modalDelegate:nil didEndSelector:nil contextInfo:nil];
            }
        }         
	}			
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){      
	}	
}

-(void)reset
{
    newMatch = YES;
    [matchType setHidden:NO]; 
    [setType setHidden:NO];
    [firstBox setHidden:NO];
    [secondBox setHidden:NO];
    [firstName setHidden:YES];
    [secondName setHidden:YES];            
    [firstSets setStringValue:@"0"];
    [secondSets setStringValue:@"0"];           
    [firstPoints setStringValue:@"0"]; 
    [secondPoints setStringValue:@"0"];     
    advantageFirst = NO;            
    advantageSecond = NO;
    first_overcame_p = 0;
    second_overcame_p = 0;
    first_overcame_s = 0;
    second_overcame_s = 0; 
}

- (void)awakeFromNib
{
    [matchType selectItemAtIndex:[[defaults objectForKey:@"matchType"] intValue]]; 
    [setType selectItemAtIndex:[[defaults objectForKey:@"setType"] intValue]]; 
    if ([[defaults objectForKey:@"setType"] intValue] == 0) {
        goal_score = 11;
        change_serve = 2;
    }else{
        goal_score = 21;
        change_serve = 5;
    }      
    newMatch = YES;
    if ([defaults boolForKey:@"flipped"] == YES) {
        flipped = YES;
        [helpText setStringValue:@"*screen should be facing players"];        
        [self flipView:firstPoints withView:secondPoints animate:YES];
        [self flipView:firstSets withView:secondSets animate:YES]; 
        [self flipView:firstName withView:secondName animate:YES]; 
        [self flipView:firstBox withView:secondBox animate:YES];        
    }
}

-(void)becomeKeyWindow
{
    [self placeFullScreenButton];  
}


#pragma mark full screen

-(void)placeFullScreenButton
{
    
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) return; //not needed in lion
        
    double mySize = 16.0;
    
    NSButton *appleIcon = [self standardWindowButton:NSWindowToolbarButton];  
    
    if (appleIcon) {
        NSView *parentView = [[self contentView] superview];
        NSRect parentFrame = [parentView frame];    
        [fsButton setFrame:NSMakeRect( NSMinX([appleIcon frame]) , NSMaxY(parentFrame) - mySize - 3 , mySize, mySize)];
        
        if ([fsButton superview] == nil) {
            [parentView addSubview:fsButton]; 
        }else{
            NSLog(@"Error adding full screen button");       
        }
        [appleIcon setHidden:YES];
    }else{
        NSLog(@"Error adding full screen button");
    } 
                  
}


-(void)fullScreenButtonClick:(id)sender
{
    NSRect fullFrame = [[NSScreen mainScreen] frame];
    if (manualFullScreen == NO) {
        [self toggleToolbarShown:self];     
        
        manualFullScreen = YES;
        [self setLevel:NSDockWindowLevel];    
        [self setFrame:NSMakeRect(0 ,0 ,fullFrame.size.width ,fullFrame.size.height-22 ) display:YES];
              
        [self fullScreenSizesZero:NO];
        
        [self placeFullScreenButton];         
    }else{
        manualFullScreen = NO; 
        [self setLevel:NSNormalWindowLevel];
        [self setFrame:NSMakeRect((fullFrame.size.width/2)-(790/2),(fullFrame.size.height/2)-(329/2) ,790 ,329 ) display:YES];
        
        [self normalSizesZero:NO];        
        
        [self toggleToolbarShown:self];   
        
        [self placeFullScreenButton];                 
    }
    
    if (flipped == YES) {
        [self flipView:firstPoints withView:secondPoints animate:NO];
    }
    
    if (changedSides == YES) {
        [self flipView:firstPoints withView:secondPoints animate:NO];
    }    
    
    if (newMatch == YES) {
        [firstBox setHidden:NO];
        [secondBox setHidden:NO];
        [firstName setHidden:YES];
        [secondName setHidden:YES];   
    }else{
        [firstBox setHidden:YES];
        [secondBox setHidden:YES];
        [firstName setHidden:NO];
        [secondName setHidden:NO];         
    }
   
}

- (NSSize)window:(NSWindow *)window willUseFullScreenContentSize:(NSSize)proposedSize
{
    NSRect screen = [[NSScreen mainScreen] frame];     
    return NSMakeSize(screen.size.width,screen.size.height);
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
    return proposedOptions | NSApplicationPresentationAutoHideToolbar;
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
    [self fullScreenSizesZero:YES];
    
    if (newMatch == YES) {
        [firstBox setHidden:NO];
        [secondBox setHidden:NO];
        [firstName setHidden:YES];
        [secondName setHidden:YES];   
    }else{
        [firstBox setHidden:YES];
        [secondBox setHidden:YES];
        [firstName setHidden:NO];
        [secondName setHidden:NO];         
    }      
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
    [self fullScreenSizesZero:NO];
    if (flipped == YES) {
        [self flipView:firstPoints withView:secondPoints animate:NO];        
    }  
    if (changedSides == YES) {
        [self flipView:firstPoints withView:secondPoints animate:NO];
    }    
}

- (void)windowWillExitFullScreen:(NSNotification *)notification
{
    [self normalSizesZero:YES];
    
    if (newMatch == YES) {
        [firstBox setHidden:NO];
        [secondBox setHidden:NO];
        [firstName setHidden:YES];
        [secondName setHidden:YES];   
    }else{
        [firstBox setHidden:YES];
        [secondBox setHidden:YES];
        [firstName setHidden:NO];
        [secondName setHidden:NO];         
    }      
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
    [self normalSizesZero:NO];
    if (flipped == YES) {
        [self flipView:firstPoints withView:secondPoints animate:NO];
    } 
    if (changedSides == YES) {
        [self flipView:firstPoints withView:secondPoints animate:NO];
    }    
}

-(void)fullScreenSizesZero:(BOOL)zero
{
    NSRect screen = [[NSScreen mainScreen] frame];     
    
    float w = screen.size.width/2.2;
    float h = screen.size.height/1.2;
    if (zero == YES) {
        w = 0;
        h = 0;
    }
    
    double scale = (screen.size.width+screen.size.height)/(292.0+329.0); 
    [firstPoints setFont:[NSFont fontWithName:@"Digital-7" size:300*(scale/1.8)]];    
    [firstPoints setFrame:NSMakeRect(0 ,0 , w, h)];
    [secondPoints setFont:[NSFont fontWithName:@"Digital-7" size:300*(scale/1.8)]];    
    [secondPoints setFrame:NSMakeRect(screen.size.width-(screen.size.width/2.2) ,0, screen.size.width/2.2, screen.size.height/1.2)];    
    
}

-(void)normalSizesZero:(BOOL)zero
{
    float w = 292;
    float h = 329;
    if (zero == YES) {
        w = 0;
        h = 0;
    }
    
    [firstPoints setFont:[NSFont fontWithName:@"Digital-7" size:300]];    
    [firstPoints setFrame:NSMakeRect(19 ,0 , w ,h )];
    [secondPoints setFont:[NSFont fontWithName:@"Digital-7" size:300]];        
    [secondPoints setFrame:NSMakeRect(478, 0, w ,h )];    
    
}

- (NSFont *)fontForText:(NSString *)text inRect:(NSRect)rect
{
    CGFloat prevSize = 300.0, guessSize = 800.0, tempSize;
    NSFont *guessFont = nil;
    while (fabs(guessSize - prevSize) > 10) {
        guessFont = [NSFont fontWithName:@"Digital-7" size:guessSize];
        NSSize textSize = [text sizeWithAttributes:[NSDictionary dictionaryWithObject:guessFont forKey: NSFontAttributeName]];
        if (textSize.width > rect.size.width || textSize.height > rect.size.height) {
            tempSize = guessSize - (guessSize - prevSize) / 2.0;
        } else {
            tempSize = guessSize + (guessSize - prevSize) / 2.0;           
        }
        prevSize = guessSize;
        guessSize = tempSize;
    }
    return [[guessFont retain] autorelease];
}

#pragma mark actions

- (void)sendEvent:(NSEvent *)event
{
	
	if ([event type] == NSLeftMouseDown) {
        //NSLog(@"first");
	}
	if ([event type] == NSRightMouseDown) {
        //NSLog(@"second");
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) [self rightMouseDown:event]; //bug fix for rightMouseDown not firing on 10.6   
	} 
	if ([event type] == NSOtherMouseDown) {
        //NSLog(@"middle");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ToolBarEvent" object:@"middle" userInfo:nil];        
	}     
	
	[super sendEvent:event];    
}

-(void)firstScored
{ 
    int opponent_score = [secondPoints intValue];    
    int score = [firstPoints intValue];
    if (score == 0 && opponent_score == 0 && newMatch == YES) {
        [synth startSpeakingString:@"Middle click to start a new match."]; 
        return;
    }    
    if (score == goal_score-1 && opponent_score < goal_score-1) {
        [firstPoints setStringValue:[NSString stringWithFormat:@"%i",goal_score]]; 
        [self firstWonSet];        
    }else if (score == goal_score-1 && opponent_score == goal_score-1) {
        if (advantageSecond == YES && advantageFirst == YES) {
            NSLog(@"Advantage ERROR");            
            [synth startSpeakingString:@"Advantage Error !"];
            [firstPoints setTextColor:redColor];
            [secondPoints setTextColor:redColor];
            advantageFirst = NO;             
            advantageSecond = NO;
            return;
        }        
        if (advantageSecond == YES) {
            [synth startSpeakingString:@"Equal Advantage, change service."]; 
            advantageSecond = NO;
            [secondPoints setTextColor:redColor];
            return;
        }
        if (advantageFirst == YES) { 
            [firstPoints setStringValue:[NSString stringWithFormat:@"%i",goal_score]];
            [firstPoints setTextColor:redColor];
            [self firstWonSet];
        }else{
            [synth startSpeakingString:[NSString stringWithFormat:@"Advantage %@, change service.",[firstName stringValue]]];
            advantageFirst = YES;
            [firstPoints setTextColor:greenColor];            
        }
    }else if (score < goal_score && opponent_score < goal_score){ 
        [firstPoints setStringValue:[NSString stringWithFormat:@"%i",score+1]]; 
        int points_difference = [firstPoints intValue] - [secondPoints intValue];
        if (points_difference > second_overcame_p) second_overcame_p = points_difference;        
        [matchType setHidden:YES];
        [setType setHidden:YES];        
        [firstBox setHidden:YES];
        [secondBox setHidden:YES];
        [firstName setHidden:NO];
        [secondName setHidden:NO];        
        NSString *speakString = [NSString stringWithFormat:@"%@ : %@",[firstPoints stringValue],[secondPoints stringValue]];
        if ([defaults boolForKey:@"sayPointSide"] == YES) speakString = [NSString stringWithFormat:@"Point %@ !",[secondName stringValue]];
        if (score == goal_score-2 && opponent_score < goal_score-1) speakString = [NSString stringWithFormat:@"%@, Set ball",speakString];        
        if ((score+opponent_score+1) % change_serve == 0 && (score+opponent_score) != 0) speakString = [NSString stringWithFormat:@"%@, Change service.",speakString];         
         [synth startSpeakingString:speakString];        
    }else{
        if (newMatch == YES) {
            [synth startSpeakingString:@"Match ended, Middle click to start a new one."]; 
        }else{
            [synth startSpeakingString:@"Set ended, Middle click to start a new one."];             
        }        
    }
}

- (void)secondScored
{     
    int opponent_score = [firstPoints intValue];    
    int score = [secondPoints intValue];
    if (score == 0 && opponent_score == 0 && newMatch == YES) {
        [synth startSpeakingString:@"Middle click to start a new match."];  
        return;
    }
    if (score == goal_score-1 && opponent_score < goal_score-1) {
        [secondPoints setStringValue:[NSString stringWithFormat:@"%i",goal_score]];
        [self secondWonSet];        
    }else if (score == goal_score-1 && opponent_score == goal_score-1) {
        if (advantageSecond == YES && advantageFirst == YES) {
            NSLog(@"Advantage ERROR");            
            [synth startSpeakingString:@"Advantage Error !"];
            [firstPoints setTextColor:redColor];
            [secondPoints setTextColor:redColor];
            advantageFirst = NO;             
            advantageSecond = NO;
            return;
        }        
        if (advantageFirst == YES) {
            [synth startSpeakingString:@"Equal Advantage, change service."]; 
            advantageFirst = NO;
            [firstPoints setTextColor:redColor];
            return;            
        }
        if (advantageSecond == YES) {
            [secondPoints setStringValue:[NSString stringWithFormat:@"%i",goal_score]];
            [secondPoints setTextColor:redColor];
            [self secondWonSet];
        }else{
            [synth startSpeakingString:[NSString stringWithFormat:@"Advantage %@, change service.",[secondName stringValue]]];
            advantageSecond = YES;
            [secondPoints setTextColor:greenColor];            
        }
    }else if (score < goal_score && opponent_score < goal_score){
        [secondPoints setStringValue:[NSString stringWithFormat:@"%i",score+1]];
        int points_difference = [secondPoints intValue] - [firstPoints intValue];
        if (points_difference > first_overcame_p) first_overcame_p = points_difference;        
        [matchType setHidden:YES];
        [setType setHidden:YES];        
        [firstBox setHidden:YES];
        [secondBox setHidden:YES];
        [firstName setHidden:NO];
        [secondName setHidden:NO];        
        NSString *speakString = [NSString stringWithFormat:@"%@ : %@",[firstPoints stringValue],[secondPoints stringValue]];
        if ([defaults boolForKey:@"sayPointSide"] == YES) speakString = [NSString stringWithFormat:@"Point %@ !",[firstName stringValue]];  
        if (score == goal_score-2 && opponent_score < goal_score-1) speakString = [NSString stringWithFormat:@"%@, Set ball",speakString];      
        if ((score+opponent_score+1) % change_serve == 0 && (score+opponent_score) != 0) speakString = [NSString stringWithFormat:@"%@, Change service.",speakString];              
        [synth startSpeakingString:speakString];      
    } else {
        if (newMatch == YES) {
            [synth startSpeakingString:@"Match ended, Middle click to start a new one."]; 
        }else{
            [synth startSpeakingString:@"Set ended, Middle click to start a new one."];             
        }   
    } 
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (changedSides == NO) {
        [self firstScored];
    }else{
        [self secondScored];        
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if (changedSides == NO) {
        [self secondScored];
    }else{
        [self firstScored];        
    }    
}

- (void)otherMouseDown:(NSEvent *)theEvent
{    
    
    if ([[firstName stringValue] isEqualToString:@"---"] || [[secondName stringValue] isEqualToString:@"---"]) {
        [synth startSpeakingString:@"Set a player name"];
        return;
    }
    
    if (newMatch == YES) {
        newMatch = NO;
        [matchType setHidden:YES];
        [setType setHidden:YES];        
        [firstBox setHidden:YES];
        [secondBox setHidden:YES];
        [firstName setHidden:NO];
        [secondName setHidden:NO];      
        [synth startSpeakingString:[NSString stringWithFormat:@"New match, %@ versus %@ !",[firstName stringValue],[secondName stringValue]]];
        [firstSets setStringValue:@"0"];
        [secondSets setStringValue:@"0"];
        //new set
        advantageFirst = NO;            
        advantageSecond = NO;    
        [firstPoints setStringValue:@"0"]; 
        [secondPoints setStringValue:@"0"];
        return;
    }
    
    int first_score = [firstPoints intValue];    
    int second_score = [secondPoints intValue];
    int first_sets = [firstSets intValue];    
    int second_sets = [secondSets intValue];    
    if (second_score == goal_score || first_score == goal_score) {
        if ([matchType indexOfSelectedItem] == 0) { // 1 in 1
            if (first_sets == 1) {
                [self firstWonMatch];
                return;
            }   
            if (second_sets == 1) {
                [self secondWonMatch]; 
                return;                
            }               
        }else if ([matchType indexOfSelectedItem] == 1) { // 2 in 3
            if (first_sets == 2) {
                [self firstWonMatch];
                return;                
            }   
            if (second_sets == 2) {
                [self secondWonMatch];                
                return;                
            }   
        }else if ([matchType indexOfSelectedItem] == 2) { // 3 in 5
            if (first_sets == 3) {
                [self firstWonMatch];
                return;                
            }   
            if (second_sets == 3) {
                [self secondWonMatch];                
                return;                
            }  
        }else if ([matchType indexOfSelectedItem] == 3) { // 4 in 7
            if (first_sets == 4) {
                [self firstWonMatch];
                return;                
            }   
            if (second_sets == 4) {
                [self secondWonMatch];                
                return;                
            } 
        }else if ([matchType indexOfSelectedItem] == 4) { // 5 in 9
            if (first_sets == 5) {
                [self firstWonMatch];
                return;                
            }   
            if (second_sets == 5) {
                [self secondWonMatch];                
                return;                
            }             
        }
        [synth startSpeakingString:@"New set !"];
        advantageFirst = NO;            
        advantageSecond = NO;    
        [firstPoints setStringValue:@"0"]; 
        [secondPoints setStringValue:@"0"];    
        //players are changing sides
        if ([firstSets intValue] != 0 || [secondSets intValue] != 0) {
            [self flipView:firstPoints withView:secondPoints animate:YES];
            [self flipView:firstSets withView:secondSets animate:NO]; 
            [self flipView:firstName withView:secondName animate:NO];
            [self flipView:firstBox withView:secondBox animate:NO];     
            if (changedSides == NO) {
                changedSides = YES;
            }else{
                changedSides = NO;       
            }  
            NSLog(@"players switched sides");
        }     
    }else{
        [synth startSpeakingString:[NSString stringWithFormat:@"%i, %i",first_score,second_score]];        
    }        
}

-(void)firstWonSet
{     
    int difference = [firstPoints intValue] - [secondPoints intValue];    
    NSString *name = [firstName stringValue];
    if ([name isEqualToString:@"First"]) name = @"First player";
    NSString *speakString = [NSString stringWithFormat:@"Set, won by %@ !",name];
    [synth startSpeakingString:speakString];    
    NSLog(@"%@ won set by %i points overcoming a %i disadvantage",name,difference,first_overcame_p);  
    [firstSets setStringValue:[NSString stringWithFormat:@"%i",[firstSets intValue]+1]];   
    int sets_difference = [firstSets intValue] - [secondSets intValue];
    if (sets_difference > second_overcame_s) second_overcame_s = sets_difference;
    [self savePlayerSetStatistics];    
}

-(void)secondWonSet
{
    int difference = [secondPoints intValue] - [firstPoints intValue];    
    NSString *name = [secondName stringValue];
    if ([name isEqualToString:@"Second"]) name = @"Second player";
    NSString *speakString = [NSString stringWithFormat:@"Set, won by %@ !",name];
    [synth startSpeakingString:speakString];     
    NSLog(@"%@ won set by %i points overcoming a %i disadvantage",name,difference,second_overcame_p);  
    [secondSets setStringValue:[NSString stringWithFormat:@"%i",[secondSets intValue]+1]];
    int sets_difference = [secondSets intValue] - [firstSets intValue];
    if (sets_difference > first_overcame_s) first_overcame_s = sets_difference;    
    [self savePlayerSetStatistics];    
}

-(void)firstWonMatch
{
    int difference = [firstSets intValue] - [secondSets intValue]; 
    NSString *name = [firstName stringValue];
    if ([name isEqualToString:@"First"]) name = @"First player";
    NSString *speakString = [NSString stringWithFormat:@"Match, won by %@ !",name];
    [synth startSpeakingString:speakString];    
    NSLog(@"%@ won match by %i sets overcoming a %i disadvantage",name,difference,first_overcame_s);
    [self savePlayerMatchStatistics];
}

-(void)secondWonMatch
{
    int difference = [secondSets intValue] - [firstSets intValue];   
    NSString *name = [secondName stringValue];
    if ([name isEqualToString:@"Second"]) name = @"Second player";
    NSString *speakString = [NSString stringWithFormat:@"Match, won by %@ !",name];
    [synth startSpeakingString:speakString];    
    NSLog(@"%@ won match by %i sets overcoming a %i disadvantage",name,difference,second_overcame_s);
    [self savePlayerMatchStatistics];    
}

-(void)savePlayerSetStatistics
{
   
    int difference;
    int overcame;
    NSString *winner;
    NSString *loser; 
    
    if ([firstPoints intValue] - [secondPoints intValue] > 0) {
        //first won
        winner = [firstName stringValue];
        loser = [secondName stringValue];
        overcame = first_overcame_p;
        difference = [firstPoints intValue] - [secondPoints intValue];        
    }else{
        //second won
        winner = [secondName stringValue];
        loser = [firstName stringValue];        
        overcame = second_overcame_p;
        difference = [secondPoints intValue] - [firstPoints intValue];        
    }
    
    first_overcame_p = 0;
    second_overcame_p = 0;     
    
    if ([[firstName stringValue] isEqualToString:@"First"] || [[secondName stringValue] isEqualToString:@"Second"]) return;    
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:@"players"]];
   
    NSMutableDictionary *winner_stats = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:winner]];
    NSMutableDictionary *loser_stats = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:loser]];   
    
    int setsLost = [[loser_stats objectForKey:@"setsLost"] intValue];
    [loser_stats setObject:[NSNumber numberWithInt:setsLost+1] forKey:@"setsLost"];    
    int setEqualsLost = [[loser_stats objectForKey:@"setEqualsLost"] intValue];
    if (difference == 1)[loser_stats setObject:[NSNumber numberWithInt:setEqualsLost+1] forKey:@"setEqualsLost"];    
    int setsLostBy = [[loser_stats objectForKey:@"setsLostBy"] intValue];
    [loser_stats setObject:[NSNumber numberWithInt:setsLostBy+difference] forKey:@"setsLostBy"];  
    
    [dict setObject:loser_stats forKey:loser];    
    
    int setsWon = [[winner_stats objectForKey:@"setsWon"] intValue];
    [winner_stats setObject:[NSNumber numberWithInt:setsWon+1] forKey:@"setsWon"];
    int setEqualsWon = [[winner_stats objectForKey:@"setEqualsWon"] intValue];
    if (difference == 1)[winner_stats setObject:[NSNumber numberWithInt:setEqualsWon+1] forKey:@"setEqualsWon"];     
    int setsWonBy = [[winner_stats objectForKey:@"setsWonBy"] intValue];
    [winner_stats setObject:[NSNumber numberWithInt:setsWonBy+difference] forKey:@"setsWonBy"];    
    
    int maxPointsOvercame = [[winner_stats objectForKey:@"maxPointsOvercame"] intValue];
    if (overcame > maxPointsOvercame)[winner_stats setObject:[NSNumber numberWithInt:overcame] forKey:@"maxPointsOvercame"];
    int totalPointsOvercame = [[winner_stats objectForKey:@"totalPointsOvercame"] intValue];
    [winner_stats setObject:[NSNumber numberWithInt:totalPointsOvercame+overcame] forKey:@"totalPointsOvercame"];        
        
    [dict setObject:winner_stats forKey:winner];
    
    [defaults setObject:dict forKey:@"players"];
    [defaults synchronize];   
}

-(void)savePlayerMatchStatistics
{
    newMatch = YES;
    [matchType setHidden:NO];
    [setType setHidden:NO];
    [firstBox setHidden:NO];
    [secondBox setHidden:NO];
    [firstName setHidden:YES];
    [secondName setHidden:YES];
    
    int difference;
    int overcame;
    NSString *winner;
    NSString *loser; 
    
    if ([firstSets intValue] - [secondSets intValue] > 0) {
        //first won
        winner = [firstName stringValue];
        loser = [secondName stringValue];
        overcame = first_overcame_s;
        difference = [firstSets intValue] - [secondSets intValue];        
    }else{
        //second won
        winner = [secondName stringValue];
        loser = [firstName stringValue];        
        overcame = second_overcame_s;
        difference = [secondSets intValue] - [firstSets intValue];        
    }  
    
    first_overcame_s = 0;
    second_overcame_s = 0;       
    
    if ([[firstName stringValue] isEqualToString:@"First"] || [[secondName stringValue] isEqualToString:@"Second"]) return;    
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:@"players"]];
    
    NSMutableDictionary *winner_stats = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:winner]];
    NSMutableDictionary *loser_stats = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:loser]];    

    int matchesLost = [[loser_stats objectForKey:@"matchesLost"] intValue];
    [loser_stats setObject:[NSNumber numberWithInt:matchesLost+1] forKey:@"matchesLost"];
    int matchEqualsLost = [[loser_stats objectForKey:@"matchEqualsLost"] intValue];
    if (difference == 1 && [matchType indexOfSelectedItem] != 0) [loser_stats setObject:[NSNumber numberWithInt:matchEqualsLost+1] forKey:@"matchEqualsLost"]; 
    int matchesLostBy = [[loser_stats objectForKey:@"matchesLostBy"] intValue];
    [loser_stats setObject:[NSNumber numberWithInt:matchesLostBy+difference] forKey:@"matchesLostBy"];    
    
    [dict setObject:loser_stats forKey:loser];      

    int matchesWon = [[winner_stats objectForKey:@"matchesWon"] intValue]; 
    [winner_stats setObject:[NSNumber numberWithInt:matchesWon+1] forKey:@"matchesWon"];    
    int matchEqualsWon = [[winner_stats objectForKey:@"matchEqualsWon"] intValue];
    if (difference == 1 && [matchType indexOfSelectedItem] != 0)[winner_stats setObject:[NSNumber numberWithInt:matchEqualsWon+1] forKey:@"matchEqualsWon"];
    int matchesWonBy = [[winner_stats objectForKey:@"matchesWonBy"] intValue];
    [winner_stats setObject:[NSNumber numberWithInt:matchesWonBy+difference] forKey:@"matchesWonBy"];    
    int maxSetsOvercame = [[winner_stats objectForKey:@"maxSetsOvercame"] intValue];
    if (overcame > maxSetsOvercame)[winner_stats setObject:[NSNumber numberWithInt:overcame] forKey:@"maxSetsOvercame"];
    int totalSetsOvercame = [[winner_stats objectForKey:@"totalSetsOvercame"] intValue];  
    [winner_stats setObject:[NSNumber numberWithInt:totalSetsOvercame+overcame] forKey:@"totalSetsOvercame"];   
        
    [dict setObject:winner_stats forKey:winner];
    
    [defaults setObject:dict forKey:@"players"];
    [defaults synchronize];  
  
}

-(IBAction)changeMatchType:(id)sender
{
    [defaults setObject:[NSString stringWithFormat:@"%i",[sender indexOfSelectedItem]] forKey:@"matchType"];
    [defaults synchronize];
    [self reset];
}

-(IBAction)changeSetType:(id)sender
{
    [defaults setObject:[NSString stringWithFormat:@"%i",[sender indexOfSelectedItem]] forKey:@"setType"];
    [defaults synchronize];
    if ([sender indexOfSelectedItem] == 0) {
        goal_score = 11;
        change_serve = 2;
    }else{
        goal_score = 21;
        change_serve = 5;
    }    
    [self reset];    
}

-(IBAction)help:(id)sender
{
       [[NSAlert alertWithMessageText:@"How to keep score" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Left click if the player on your left wins a point, right click if the player on your right does, middle click to start/end sets and matches. \nDepending on which way the display is facing you can flip the players around."] beginSheetModalForWindow:self modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(void)flipView:(NSView*)first withView:(NSView*)second animate:(BOOL)animate
{
    if (animate == NO){
        NSRect firstFrame = first.frame;
        NSRect secondFrame = second.frame;
        [first setFrame:NSMakeRect(secondFrame.origin.x, secondFrame.origin.y, secondFrame.size.width, secondFrame.size.height)];
        [second setFrame:NSMakeRect(firstFrame.origin.x, firstFrame.origin.y, firstFrame.size.width, firstFrame.size.height)];        
    }else{
        NSViewAnimation *theAnim;
        NSMutableDictionary* firstViewDict;
        NSMutableDictionary* secondViewDict;
        
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [firstViewDict setObject:first forKey:NSViewAnimationTargetKey];
        [firstViewDict setObject:[NSValue valueWithRect:[first frame]] forKey:NSViewAnimationStartFrameKey];
        [firstViewDict setObject:[NSValue valueWithRect:[second frame]] forKey:NSViewAnimationEndFrameKey];	
        
        secondViewDict = [NSMutableDictionary dictionaryWithCapacity:3];		
        [secondViewDict setObject:second forKey:NSViewAnimationTargetKey];
        [secondViewDict setObject:[NSValue valueWithRect:[second frame]] forKey:NSViewAnimationStartFrameKey];		
        [secondViewDict setObject:[NSValue valueWithRect:[first frame]] forKey:NSViewAnimationEndFrameKey];         
        
        [firstViewDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];			
        [secondViewDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
        
        // Create the view animation object.
        theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict, secondViewDict, nil]];
        [theAnim setDuration:0.6];
        [theAnim setAnimationCurve:NSAnimationLinear];
        [theAnim startAnimation];
        [theAnim release];        
    }
    
}

#pragma mark combobox

-(void)changeName:(NSString*)name box:(NSComboBox*)control
{
    if ([name length] > 2) { 

        if ([[control toolTip] isEqualToString:@"Set First Name"])  {
            if ([[secondName stringValue] isEqualToString:name]) {
                [secondName setStringValue:@"---"];
                [secondBox selectItemAtIndex:0];    
                [firstName setStringValue:name];
            }else{
                [firstName setStringValue:name];
            }
        }
        if ([[control toolTip] isEqualToString:@"Set Second Name"]) {
            if ([[firstName stringValue] isEqualToString:name]) {
                [firstName setStringValue:@"---"];
                [firstBox selectItemAtIndex:0];
                [secondName setStringValue:name];
            }else{
                [secondName setStringValue:name];
            }            
        }                             
    }
}

- (void)comboBoxWillPopUp:(NSNotification *)aNotification
{
    NSComboBox *box = (NSComboBox*)[aNotification object];
    [box removeAllItems];
    [self populateNames:box];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)aNotification
{
    NSComboBox *box = (NSComboBox*)[aNotification object];  
    NSString *name = [box objectValueOfSelectedItem];
    [self changeName:name box:box];     
}

- (void)comboBoxWillDismiss:(NSNotification *)aNotification
{   
}

- (void)controlTextDidChange:(NSNotification *)aNotification{
    NSTextView *view = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
    NSComboBox *box = (NSComboBox*)[[view superview] superview]; 
    NSString *name = [box stringValue];
    [self changeName:name box:box];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    if ([[fieldEditor string] length] > 2) {      
        return YES;        
    }else{
        return NO;
    }
}

- (void)populateNames:(NSComboBox*)box
{   
    [box addItemWithObjectValue:@"---"];
    for (NSString *key in [defaults objectForKey:@"players"]) {
        [box addItemWithObjectValue:key];    
    }
}

@end
