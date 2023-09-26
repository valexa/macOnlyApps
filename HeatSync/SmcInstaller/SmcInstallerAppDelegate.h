//
//  SmcInstallerAppDelegate.h
//  SmcInstaller
//
//  Created by Vlad Alexa on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SmcInstallerAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
