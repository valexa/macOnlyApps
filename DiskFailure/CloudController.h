//
//  CloudController.h
//  DiskFailure
//
//  Created by Vlad Alexa on 3/1/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudController : NSObject

- (void)mainWindowOpened:(NSNotification *)notification;

-(BOOL)isiCloudAvailable;
- (NSURL*)getiCloudURLFor:(NSString*)fileName containerID:(NSString*)containerID;
- (void)makeUbiquitousItemAtURL:(NSURL*)cloudURL;
- (void)makeNonUbiquitousItemAtURL:(NSURL*)cloudURL;
- (void)mergeWithiCloudCheck:(NSURL*)cloudURL;
- (void)resolveConflicts:(NSURL*)cloudURL;
-(NSURL*)getSnapshotLink:(NSURL*)cloudURL;

-(void)addLogs:(NSDictionary*)newOnes toCloud:(NSURL*)cloudURL;
-(void)addDisks:(NSDictionary*)newOnes toCloud:(NSURL*)cloudURL;

@end
