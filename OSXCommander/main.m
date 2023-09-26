//
//  main.m
//  OSXCommander
//
//  Created by Vlad Alexa on 7/6/09.
//  Copyright NextDesign 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	
	if(getenv("NSZombieEnabled")) {
		NSLog(@"NSZombieEnabled enabled!!");
	}
	if(getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
		NSLog(@"NSAutoreleaseFreedObjectCheckEnabled enabled!!");
	}		
	if(getenv("NSTraceEvents")) {
		NSLog(@"NSTraceEvents enabled!!");
	}			
	
    return NSApplicationMain(argc,  (const char **) argv);
}
