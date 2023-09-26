//
//  DiskFailureMainCore.h
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DiskFailureMainCore : NSObject {
@private
    NSUserDefaults *defaults; 
}

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;
-(NSArray*)mergePrefs:(NSArray*)newDisks;
-(NSDictionary*)processData:(NSDictionary*)dict;
-(NSDictionary*)cacheForDevice:(NSString*)name bsd:(NSString*)bsd serial:(NSString*)serial;
-(NSString*)naIfNil:(id)object;

-(void)timerLoop:(id)sender;
-(void)doCheck:(id)sender;
-(NSDictionary*)poolSmart:(NSDictionary*)dict forced:(BOOL)forced;
-(NSDictionary*) parseIOBlockStorageDriver:(io_service_t)service;
-(NSString*)interfaceType:(io_service_t)device;
-(NSString*)getPathAsStringFor:(io_service_t)service;
-(NSDictionary*)getPower:(io_service_t)root interface:(NSString*)interface;
-(BOOL)isSleeping:(NSDictionary*)dict;
-(BOOL)isSmartCapable:(io_service_t)device;
- (NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device;
- (NSString*)getStringForProperty:(NSString*)propertyName device:(io_service_t)device;
- (int)getIntForProperty:(NSString*)propertyName device:(io_service_t)device;
-(int64_t)machineIdleTime;
    
-(void)doNotifications:(NSDictionary*)dict;
-(void)sendGrowlNotification:(NSString*)desc title:(NSString*)title;
-(void)showAlert:(NSString*)desc title:(NSString*)title;

@end
