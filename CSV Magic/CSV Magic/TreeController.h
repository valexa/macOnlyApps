//
//  TreeController.h
//  CSV Magic
//
//  Created by Vlad Alexa on 1/22/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MainController.h"

@interface TreeController : NSObject <NSOutlineViewDataSource,NSOutlineViewDelegate,NSComboBoxDataSource>
{
    IBOutlet MainController *mainController;    
    IBOutlet NSOutlineView *treeTable;
    IBOutlet NSComboBox *selector;
    NSMutableArray *tree;
    NSMutableArray *uniques;
}

-(IBAction) selectorChange:(id)sender;

@end
