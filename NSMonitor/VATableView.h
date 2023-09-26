//
//  VATableView.h
//  Loadables
//
//  Created by Vlad Alexa on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VATableViewDelegate;

@interface VATableView : NSTableView {

}

@property (nonatomic, unsafe_unretained) id<VATableViewDelegate> delegate;

@end

@protocol VATableViewDelegate<NSTableViewDelegate>

@required

- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView;

@end
