//
//  main.m
//  DiskFailure
//
//  Created by Vlad Alexa on 1/15/11.
//  Copyright 2011 NextDesign. All rights reserved.
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
    
    return NSApplicationMain(argc,  (const char **) argv);    

}
