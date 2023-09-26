//
//  ToolbarController.h
//  OSXCommander
//
//  Created by Vlad Alexa on 11/12/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ToolbarController : NSObject <NSToolbarDelegate> {
	NSMutableDictionary *items;	
}

@property (nonatomic, assign) NSMutableDictionary *items;

- (id)theSender:(id)sender;
- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)thetoolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)thetoolbar;

@end
