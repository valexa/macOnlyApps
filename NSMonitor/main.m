//
//  main.m
//  NSMonitor
//
//  Created by Vlad Alexa on 1/7/10.
//  Copyright 2010 NextDesign. All rights reserved.
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
