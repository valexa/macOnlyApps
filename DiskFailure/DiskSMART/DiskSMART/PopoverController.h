//
//  PopoverController.h
//  DiskSMART
//
//  Created by Vlad Alexa on 1/27/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PopoverController : NSViewController{
    NSDictionary        *theDict;
    IBOutlet NSTableView *theTable;
}

@property (retain) NSDictionary *theDict;

@end
