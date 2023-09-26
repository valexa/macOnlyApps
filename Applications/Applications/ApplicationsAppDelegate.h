//
//  ApplicationsAppDelegate.h
//  Applications
//
//  Created by Vlad Alexa on 9/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ApplicationsAppDelegate : NSObject <NSApplicationDelegate,NSMetadataQueryDelegate> {
    NSWindow *window;
    NSUserDefaults *defaults;
    NSMetadataQuery *query;
    NSTimer *queryTimeout; 
    NSMutableArray *appsList;
    NSMutableArray *appsListSearch;   
    NSString *searchString; 
    BOOL updating;
    
    NSString *otoolPath;
    NSString *lipoPath;    
    
    IBOutlet NSPanel *windowPrefs;
    IBOutlet NSTableView *appsTable;
    IBOutlet NSProgressIndicator *progMsg;
    IBOutlet NSTextField *textMsg;  
    IBOutlet NSPanel *windowMsg;
    IBOutlet NSTextField *bottomLeftLabel;
    IBOutlet NSTextField *bottomRightLabel;    
    IBOutlet NSProgressIndicator *bottomProgress;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSMutableArray *appsList;
@property (retain) NSMutableArray *appsListSearch;
@property (retain) NSString *searchString;

-(void)setupQuery;
- (NSArray*)filteredQueryResults;
- (void)queryNote:(NSNotification *)note;

-(void)updateApps;
-(void)analyzeApps;
-(NSDictionary*)analyzeApp:(NSDictionary*)dict;

- (void)showMsg:(NSString *)msg;
- (void)closeMsg;

- (IBAction)showPrefs:(id)sender;
- (IBAction)closePrefs:(id)sender;

-(NSArray*)getArchitectures:(NSString*)executable;
-(NSArray*)getFrameworks:(NSString*)executable;
-(NSArray*)getLocalizations:(NSString*)path;
-(NSDictionary*)getPackagedInfoPlist:(NSString*)executable;

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args;
-(NSDictionary*)entitlementsForFile:(NSString*)path;
-(NSDictionary*)signInfoForFile:(NSString*)path;

@end
