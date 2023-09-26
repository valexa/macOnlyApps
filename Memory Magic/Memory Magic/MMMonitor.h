//
//  MMMonitor.h
//  Memory Magic
//
//  Created by Vlad Alexa on 11/10/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMMonitor : NSObject{

    NSMutableArray *memDb;
    NSInteger lastSyslogPollTime;

}

@end
