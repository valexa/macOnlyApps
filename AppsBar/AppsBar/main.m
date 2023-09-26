//
//  main.m
//  AppsBar
//
//  Created by Vlad Alexa on 1/23/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VAValidation.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        int v = [VAValidation v];
        int a = [VAValidation a];
        if (v+a != 0) return(v+a);
    }
    
    return NSApplicationMain(argc, (const char **)argv);
}