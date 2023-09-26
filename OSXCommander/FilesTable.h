//
//  FilesTable.h
//  OSXCommander
//
//  Created by Vlad Alexa on 11/7/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKXattrMetadataStore.h"
#import "AppDelegate.h"

@interface FilesTable : NSObject {
	NSMutableDictionary *sysDict;
}

-(NSDictionary *)travPath:(NSString *)path;
-(NSDictionary *)listDir:(NSString *)path;
-(NSDictionary *)listDirRec:(NSString *)path;
-(NSString *)resolveAlias:(NSString *)path;
-(NSString *)resolveSymlink:(NSString *)path;
-(NSDictionary *)fileInfo:(NSString *)path;
-(BOOL)hasResource:(ResType)type path:(NSString *)path;
-(void)makeAliasToFolder:(NSString *)destFolder inFolder:(NSString *)parentFolder withName:(NSString *)name;

@end
