//
//  ToolBar.h
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ToolBar : NSObject <NSToolbarDelegate> {
    NSToolbar *theBar;
@private
    NSMutableDictionary *items;	   
}

@property (retain) NSToolbar *theBar;

- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)thetoolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)thetoolbar;

- (void)tbclickRefresh:(NSToolbarItem*)item;

@end
