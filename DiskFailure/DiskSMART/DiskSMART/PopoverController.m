//
//  PopoverController.m
//  DiskSMART
//
//  Created by Vlad Alexa on 1/27/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "PopoverController.h"

@implementation PopoverController

@synthesize theDict;

-(void)awakeFromNib {
    [self addObserver:self forKeyPath:@"theDict" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [theTable reloadData];
}

#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [theDict count];	
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
	NSString *ident = [theColumn identifier]; 
    
    if ([ident isEqualToString:@"one"]) {
        return [[theDict allKeys] objectAtIndex:rowIndex];
    }
    if ([ident isEqualToString:@"two"]) {
        id ret = [[theDict allValues] objectAtIndex:rowIndex];
        if (CFGetTypeID(ret) == CFBooleanGetTypeID()) {
            return ret ? @"YES" : @"NO";
        }
        return ret;
    }    
    return nil;
}

@end
