//
//  DragDropImageView.m
//  CSV Magic
//
//  Created by Vlad Alexa on 1/25/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "DragDropImageView.h"

@implementation DragDropImageView


/*
 
- (void)mouseDown:(NSEvent*)event
{
    if (![self.identifier isEqualToString:@"dragEnabled"]) return;
    
    //create a NSPasteboardItem
    NSPasteboardItem *pbItem = [NSPasteboardItem new];
    [pbItem setDataProvider:self forTypes:[NSArray arrayWithObject:(NSString*)kUTTypeUTF8PlainText]];
    
    //create a new NSDraggingItem with our pasteboard item.
    NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
    NSPoint dragPosition = [self convertPoint:[event locationInWindow] fromView:nil];
    dragPosition.x -= self.image.size.width/5/2;
    dragPosition.y -= self.image.size.height/5/2;
    NSRect draggingRect = NSMakeRect(dragPosition.x, dragPosition.y, self.image.size.width/5, self.image.size.height/5);
    [dragItem setDraggingFrame:draggingRect contents:self.image];
    
    //create a dragging session with our drag item and ourself as the source.
    NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:[NSArray arrayWithObject:dragItem] event:event source:self];
    
    //causes the dragging item to slide back to the source if the drag fails.
    draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
    
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    if (context == NSDraggingContextOutsideApplication) {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

- (void)pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{
    
    if ( [type compare:(NSString*)kUTTypeUTF8PlainText] == NSOrderedSame )
    {
        NSString *path = [NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),[self toolTip]];
        NSData *data = [NSData dataWithContentsOfFile:path];
        [sender setData:data forType:(NSString*)kUTTypeUTF8PlainText];
    }
    
}
 
*/

- (void)mouseDown:(NSEvent*)event
{
    if (![self.identifier isEqualToString:@"dragEnabled"]) return;
    
    NSPoint dragPosition;
    NSRect imageLocation;
    
    dragPosition = [self convertPoint:[event locationInWindow] fromView:nil];
    dragPosition.x -= 16;
    dragPosition.y -= 16;
    imageLocation.origin = dragPosition;
    imageLocation.size = NSMakeSize(32,32);
    [self dragPromisedFilesOfTypes:[NSArray arrayWithObject:NSPasteboardTypeString] fromRect:imageLocation source:self slideBack:YES event:event];
}

//optionally we do this for a bigger image icon
- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation offset:(NSSize)initialOffset event:(NSEvent *)event pasteboard:(NSPasteboard *)pboard source:(id)sourceObj slideBack:(BOOL)slideFlag
{
    NSPoint dragPosition = [self convertPoint:[event locationInWindow] fromView:nil];
    dragPosition.x -= self.image.size.width/5/2;
    dragPosition.y -= self.image.size.height/5/2;
    
    NSImage *dragImage = [[NSImage alloc] initWithSize:self.image.size];
    [dragImage lockFocus];
    [[self image] drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, self.image.size.width, self.image.size.height) operation:NSCompositeCopy fraction:.5];
    [dragImage unlockFocus];
    [dragImage setScalesWhenResized:YES];
    [dragImage setSize:NSMakeSize(self.image.size.width/5, self.image.size.height/5)];
    
    [super dragImage:dragImage at:dragPosition offset:NSZeroSize event:event pasteboard:pboard source:self slideBack:slideFlag];
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
    NSString *destPath = [NSString stringWithFormat:@"%@/%@",[dropDestination path],[self toolTip]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destPath])
    {
        NSAlert *alert = [NSAlert alertWithMessageText:destPath defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"File exists, overwrite ?"];
        [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        //[alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) WTF ?
    }else{
        NSError *err;
        [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),[self toolTip]]  toPath:destPath error:&err];
        if (err) {
            NSLog(@"%@ at %@",[err localizedFailureReason],destPath);
        }
    }
    
    return [NSArray arrayWithObject:[self toolTip]];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 1)
    {
        NSString *destPath = [alert messageText];
        NSError *err;
        [[NSFileManager defaultManager] removeItemAtPath:destPath error:&err];
        if (err) {
            NSLog(@"%@",[err localizedFailureReason]);
            [[NSAlert alertWithError:err] runModal];
        }else{
            NSError *err;
            [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),[self toolTip]]  toPath:destPath error:&err];
            if (err) {
                NSLog(@"%@ at %@",[err localizedFailureReason],destPath);
            }
        }
    }
}


@end
