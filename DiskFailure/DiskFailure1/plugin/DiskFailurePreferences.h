//
//  DiskFailurePreferences.h
//  DiskFailure
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiskFailurePreferences : NSViewController <NSTableViewDataSource,NSTableViewDelegate> {

	IBOutlet NSTableView	*theTable;	    
    NSMutableArray *theList;  
	
}

-(void)getData;

-(NSString*)humanizeCount:(NSString*)count;
-(NSString*)humanizeDate:(NSDate*)date;

@end

@interface NSColor (StringOverrides)
+(NSArray *)controlAlternatingRowBackgroundColors;
@end