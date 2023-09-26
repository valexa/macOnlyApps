//
//  SysInfo.m
//  OSXCommander
//
//  Created by Vlad Alexa on 12/13/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "SysInfo.h"

@implementation SysInfo


-(NSString *)machineUUID
{
	NSString *ret = nil;
	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));			
	if (platformExpert) {
		CFTypeRef cfstring = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
        if (cfstring) {
            ret = [NSString stringWithFormat:@"%@",cfstring];        
            CFRelease(cfstring);                    
        }
		IOObjectRelease(platformExpert);        
	}		
    return [ret stringByReplacingOccurrencesOfString:@"00000000-0000-1000-8000-" withString:@""];
}

+(NSString *)hardwareSerial
{
    static NSString *returnStr = nil;
	
	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));			
	if (platformExpert) {
		CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault, 0);
		if (serialNumberAsCFString) {
			returnStr = (NSString *)serialNumberAsCFString;
		}				
		IOObjectRelease(platformExpert);
	}	
	
    return returnStr;  
}

+(NSString *)hardwareUUID
{
    static NSString *returnStr = nil;
	
	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));			
	if (platformExpert) {
		CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
		if (serialNumberAsCFString) {
			returnStr = (NSString *)serialNumberAsCFString;
		}				
		IOObjectRelease(platformExpert);
	}	
	
    return returnStr;    
}

+(NSString *)hardwareModel
{
    static NSString *hardwareModel = nil;
    if (!hardwareModel) {
        char buffer[128];
        size_t length = sizeof(buffer);
        if (sysctlbyname("hw.model", &buffer, &length, NULL, 0) == 0) {
            hardwareModel = [[NSString allocWithZone:NULL] initWithCString:buffer encoding:NSASCIIStringEncoding];
        }
        if (!hardwareModel || [hardwareModel length] == 0) {
            hardwareModel = @"Unknown";
        }
    }
    return hardwareModel;    
}

+(NSString *)hardwareCPU
{
    static NSString *computerModel = nil;
    if (!computerModel) {
        NSString *path, *hardwareModel = [self hardwareModel];
        if ((path = [[NSBundle mainBundle] pathForResource:@"Macintosh" ofType:@"dict"])) {
            computerModel = [[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:hardwareModel] copy];
        }
        if (!computerModel) {
            char buffer[128];
            size_t length = sizeof(buffer);
            if (sysctlbyname("hw.machine", &buffer, &length, NULL, 0) == 0) {
                computerModel = [[NSString allocWithZone:NULL] initWithCString:buffer encoding:NSASCIIStringEncoding];
            }
        }
        if (!computerModel || [computerModel length] == 0) {
            computerModel = [[NSString allocWithZone:NULL] initWithFormat:@"%@ computer model", hardwareModel];
        }
    }
    return computerModel;
}

@end
