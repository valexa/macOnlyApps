//
//  SysInfo.h
//  OSXCommander
//
//  Created by Vlad Alexa on 12/13/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sys/sysctl.h>

@interface SysInfo : NSObject {

}

+(NSString *)hardwareSerial;
+(NSString *)hardwareUUID;
+(NSString *)hardwareModel;
+(NSString *)hardwareCPU;

@end
