//
//  PaneController.m
//  OSXCommander
//
//  Created by Vlad Alexa on 11/6/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "PaneController.h"


@implementation PaneController

@synthesize paneName;

- (id)theName:(NSString *)name theType:(NSString *)type theSender:(id)sender{	
    self = [super init];
	if (self) {
		self.paneName = name;
		//NSLog(@"Pane Controller for %@ (%@) from %p",name,type,sender);				
		[NSBundle loadNibNamed:@"Tabs" owner:self];	
		if (type == @"file"){
			[self makePane:name sender:sender type:fileView];
		}
		if (type == @"list"){
			[self makePane:name sender:sender type:listView];
			
		}
	
	}	
	return self;
}

-(void)makePane:(NSString*)name sender:(id)sender type:(id)type{
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:name];
	NSView *headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, [sender frame].size.height-25, [sender frame].size.width, 25)];
	
	int space = 0;
	for (id mykey in dict) {		
		NSDictionary *t = [dict objectForKey:mykey];
		[topPath addItemWithObjectValue:[t objectForKey:@"path"]];
		[topVol addItemWithTitle:[t objectForKey:@"path"]];		
		NSButton *aButton = [[NSButton alloc] init];
		aButton.image = [NSImage imageNamed:@"selected"];
		aButton.title = [t valueForKey:@"path"];	
		aButton.frame = NSMakeRect(space, 0, 150, 25);
		//aButton.lineBreakMode = NSLineBreakByTruncatingTail;
		[aButton setFont:[NSFont systemFontOfSize:12.0]];
		[aButton setBordered:NO];
		if ( [[t valueForKey:@"active"] isEqualToString:@"1"] ) {	
			[aButton setEnabled:YES];
			[topPath selectItemWithObjectValue:[t objectForKey:@"path"]];
			[topVol selectItemWithTitle:[t objectForKey:@"path"]];
			[topVol setTitle:[t objectForKey:@"path"]];			
		}else {
			[aButton setEnabled:NO];				
		}		
		[headerView addSubview:aButton];
		[aButton release];
		space += 151;
	}	
	
	[headerView setAutoresizingMask:(2|8)];	
	[sender addSubview:headerView];
	[type setFrame:NSMakeRect(0, 0, [sender frame].size.width, [sender frame].size.height-24)];
	[sender addSubview:type positioned:NSWindowBelow relativeTo:headerView];
	[headerView release];
    [sender setFocusRingType:NSFocusRingTypeNone];		
    [type setFocusRingType:NSFocusRingTypeExterior];	
	
}

- (void)dealloc {
	[super dealloc];
}

@end
