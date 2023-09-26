//
//  MenuBar.h
//  DiskFailure
//
//  Created by Vlad Alexa on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MenuBar : NSObject {
@private
	NSStatusItem *_statusItem;
    NSUserDefaults *defaults;
    float progress;
}


- (void) iconClick:(id)sender;

@end
