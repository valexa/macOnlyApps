//
//  main.m
//  Memory Magic
//
//  Created by Vlad Alexa on 11/1/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
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
