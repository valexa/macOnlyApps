//
//  DragDropView.h
//  Music Library Magic
//
//  Created by Vlad Alexa on 12/2/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LoadController.h"

@interface DragDropView : NSView <NSDraggingDestination>{
    BOOL red;
    IBOutlet LoadController *loadController;
}

@end
