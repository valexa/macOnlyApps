//
//  AssocController.m
//  CSV Magic
//
//  Created by Vlad Alexa on 1/22/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "AssocController.h"

#import <QuickLook/QuickLook.h>

@implementation AssocController

-(void)awakeFromNib
{
    [scrollView setDocumentView:imageView];
    
    [mainController addObserver:self forKeyPath:@"filteredArray" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSInteger count = 0;
    for (NSDictionary *dict in mainController.filteredArray) count += [mainController.headersArray count];
    if (count > 100000)
    {
        [rowSelector setEnabled:NO];
        [colSelector setEnabled:NO];
        return;
    }else{
        [rowSelector setEnabled:YES];
        [colSelector setEnabled:YES];
    }
    
    [imageView setIdentifier:@"dragDisabled"];
    [imageView setToolTip:@""];
    [imageView setImage:nil];
    
    [rowSelector reloadData];
    [colSelector reloadData];
    
    if ([mainController.headersArray count] == 0) [rowSelector deselectItemAtIndex:[rowSelector indexOfSelectedItem]];
    if ([mainController.headersArray count] == 0) [colSelector deselectItemAtIndex:[colSelector indexOfSelectedItem]];
    
    [self createAssociations];
}

-(void)createAssociations
{
    
    if ([rowSelector indexOfSelectedItem] >= [mainController.headersArray count] || [rowSelector indexOfSelectedItem] < 0 || [colSelector indexOfSelectedItem] >= [mainController.headersArray count] || [colSelector indexOfSelectedItem] < 0) return;
    
    NSString *row = [mainController.headersArray objectAtIndex:[rowSelector indexOfSelectedItem]];
    NSString *col = [mainController.headersArray objectAtIndex:[colSelector indexOfSelectedItem]];
    
    NSArray *uniqueRows = [self uniquesforHeader:row];
    NSArray *uniqueCols = [self uniquesforHeader:col];
    
    NSMutableArray *totals = [NSMutableArray arrayWithCapacity:1];
    //fill totals with zeroes
    for (NSString *rows in uniqueRows)
    {
        NSMutableArray *cols = [NSMutableArray arrayWithCapacity:1];
        for (NSString *col in uniqueCols)
        {
            [cols addObject:[NSNumber numberWithInt:0]];
        }
        [totals addObject:cols];
    }
    
    for (NSDictionary *dict in mainController.filteredArray)
    {
        NSInteger rowIndex = [uniqueRows indexOfObject:[dict objectForKey:row]];
        NSInteger colIndex = [uniqueCols indexOfObject:[dict objectForKey:col]];
        if (rowIndex != NSNotFound && colIndex != NSNotFound)
        {
            //increment
            NSIndexPath *path = [NSIndexPath indexPathWithIndexes:(NSUInteger[]){rowIndex,colIndex} length:2];
            NSNumber *num = [self objectAtIndexPath:path inArray:totals];
            if (num)
            {
                if (![self setObject:[NSNumber numberWithInteger:[num integerValue]+1] atIndexPath:path inArray:totals])
                {
                    NSLog(@"Error incrementing at %@ %@",num,path);
                }
            }else{
                    NSLog(@"Error getting count at %@",path);
            }
        }else{
            //leave zero
        }
    }
    
    NSString *csv = [self createCSV:totals fromRows:uniqueRows andColumns:uniqueCols];
    if (csv) {
        [imageView setToolTip:[NSString stringWithFormat:@"%@-%@ associations.csv",row,col]];
        //[self calculateSizefromRows:uniqueRows andColumns:uniqueCols];
        [self performSelector:@selector(writeCSV:) withObject:csv afterDelay:0.5];
    }
}

-(void)calculateSizefromRows:(NSArray*)rows andColumns:(NSArray*)cols
{
    NSInteger width = 12;
    for (NSString *column in cols)
    {
        NSSize size = [column sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12.0] forKey: NSFontAttributeName]];
        width = width + size.width + 12;
    }
    
    if (width > imageView.frame.size.width)
    {
        [imageView setFrame:NSMakeRect(imageView.frame.origin.x, imageView.frame.origin.y, width, imageView.frame.size.height)];
    }

    NSInteger height = 24;
    for (NSString *row in rows)
    {
        NSSize size = [row sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12.0] forKey: NSFontAttributeName]];
        height = height + size.height + 12;
    }
    
    if (height > imageView.frame.size.height)
    {
        [imageView setFrame:NSMakeRect(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width, height)];
    }
}

-(void)writeCSV:(NSString*)string
{
    NSError *err;
    [string writeToFile:[NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),[imageView toolTip]] atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"%@",[err localizedFailureReason]);
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [imageView setImage:[self imageWithPreviewOfFileAtPath:[NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),imageView.toolTip] ofSize:NSMakeSize(imageView.frame.size.width*1.5, imageView.frame.size.height*1.5) asIcon:YES]];
        });
        [imageView setIdentifier:@"dragEnabled"];
    }
}

-(BOOL)setObject:(id)object atIndexPath:(NSIndexPath*)indexPath inArray:(NSMutableArray*)arr
{
    NSInteger rowIndex = [indexPath indexAtPosition:0];
    NSInteger colIndex = [indexPath indexAtPosition:[indexPath length]-1];
    if (rowIndex < [arr count])
    {
        NSMutableArray *row = [NSMutableArray arrayWithArray:[arr objectAtIndex:rowIndex]];
        if (colIndex < [row count] && object )
        {
            [row replaceObjectAtIndex:colIndex withObject:object];
            [arr replaceObjectAtIndex:rowIndex withObject:row];
            return YES;
        }
    }
    return NO;
}

-(id)objectAtIndexPath:(NSIndexPath*)indexPath inArray:(NSArray*)arr
{
    
    NSInteger rowIndex = [indexPath indexAtPosition:0];
    NSInteger colIndex = [indexPath indexAtPosition:[indexPath length]-1];
    if (rowIndex < [arr count])
    {
        NSArray *row = [arr objectAtIndex:rowIndex];
        if (colIndex < [row count])
        {
            return [row objectAtIndex:colIndex];
        }
    }
    return  nil;
}

-(NSArray*)uniquesforHeader:(NSString*)header
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *dict in mainController.filteredArray)
    {
        NSString *unique = [dict objectForKey:header];
        if (unique) {
            if (![ret containsObject:unique]) [ret addObject:unique];
        }else{
            //NSLog(@"NIL %@ in %@",header,dict);
        }
    }
    

    return [ret sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];;
}

-(NSString*)createCSV:(NSArray*)content fromRows:(NSArray*)rows andColumns:(NSArray*)cols
{
    NSMutableString *ret = [NSMutableString stringWithCapacity:1];

    //add headers
    NSMutableString *headers = [NSMutableString stringWithCapacity:1];
    [ret appendString:@","];
    for (NSString *col in cols)
    {
        [headers appendFormat:@"\"%@\",",col];
    }
    if ([headers length] > 0) [ret appendFormat:@"%@\n",[headers substringToIndex:[headers length]-1]];
    
    for (NSString *row in rows)
    {
        NSUInteger rowIndex = [rows indexOfObject:row];
        NSMutableString *line = [NSMutableString stringWithCapacity:1];
        [line appendFormat:@"\"%@\",",row];
        for (NSString *col in cols)
        {
            NSUInteger colIndex = [cols indexOfObject:col];
            NSIndexPath *path = [NSIndexPath indexPathWithIndexes:(NSUInteger[]){rowIndex,colIndex} length:2];
            NSNumber *num = [self objectAtIndexPath:path inArray:content];
            if ([num integerValue] == 0) {
                [line appendString:@","];
            }else{
                [line appendFormat:@"%@,",num];
            }
        }
        if ([line length] > 0) [ret appendFormat:@"%@\n",[line substringToIndex:[line length]-1]];
    }
    return ret;
}

#pragma mark NSComboBoxDelegate

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == rowSelector && [rowSelector indexOfSelectedItem] >= 0)
    {
        if ([rowSelector indexOfSelectedItem] == [colSelector indexOfSelectedItem])
        {
            [self shakeWindow:[NSApp mainWindow]];
            [rowSelector deselectItemAtIndex:[rowSelector indexOfSelectedItem]];
        }else{
            if ([rowSelector indexOfSelectedItem] >= 0 && [colSelector indexOfSelectedItem] >= 0)
            {
                [self createAssociations];
            }
        }
    }
    if ([notification object] == colSelector && [colSelector indexOfSelectedItem] >= 0)
    {
        if ([rowSelector indexOfSelectedItem] == [colSelector indexOfSelectedItem])
        {
            [self shakeWindow:[NSApp mainWindow]];
            [colSelector deselectItemAtIndex:[colSelector indexOfSelectedItem]];
        }else{
            if ([rowSelector indexOfSelectedItem] >= 0 && [colSelector indexOfSelectedItem] >= 0)
            {
                [self createAssociations];
            }
        }
    }
}
         
-(void)shakeWindow:(NSWindow*)w
{
	
    NSRect f = [w frame];
    int c = 0; //counter variable
    int off = -12; //shake amount (offset)
    while(c<4) //shake 5 times
    {
        [w setFrame: NSMakeRect(f.origin.x + off,
                                f.origin.y,
                                f.size.width,
                                f.size.height) display: NO];
        [NSThread sleepForTimeInterval: .06]; //slight pause
        off *= -1; //back and forth
        c++; //inc counter
    }
    [w setFrame:f display: NO]; //return window to original frame
}


#pragma mark NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [mainController.headersArray count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (index < [mainController.headersArray count])
    {
        return [mainController.headersArray objectAtIndex:index];
    }else{
        NSLog(@"Out of bounds %li",(long)index);
    }
    
    return nil;
}


#pragma mark image

- (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (!path || !fileURL) {
        return nil;
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:icon] forKey:(NSString *)kQLThumbnailOptionIconModeKey];
    CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault,(CFURLRef)CFBridgingRetain(fileURL),CGSizeMake(size.width, size.height),(CFDictionaryRef)CFBridgingRetain(dict));
    
    if (ref != NULL) {
        // Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, new in Leopard,
        // which is a lot more efficient than copying pixel data into a brand new NSImage.
        // Thanks to Troy Stephens @ Apple for pointing this new method out to me.
        NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:ref];
        NSImage *newImage = nil;
        if (bitmapImageRep)
        {
            newImage = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
            [newImage addRepresentation:bitmapImageRep];
            if (newImage) return newImage;
        }
        CFRelease(ref);
    } else {
        // If we couldn't get a Quick Look preview, fall back on the file's Finder icon.
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        if (icon) {
            [icon setSize:size];
        }
        return icon;
    }
    
    return nil;
}

@end
