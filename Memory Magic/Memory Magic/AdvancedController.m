//
//  AdvancedController.m
//  Memory Magic
//
//  Created by Vlad Alexa on 12/18/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "AdvancedController.h"

#import "VASandboxFileAccess.h"

#include <sys/mount.h>

@interface AdvancedController ()

@end

@implementation AdvancedController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"AdvancedPopoverEvent" object:nil];
    
    swapStat = [NSMutableArray arrayWithCapacity:bottomView.frame.size.width];
    
    recoveryStat = [NSMutableArray arrayWithCapacity:topView.frame.size.width];
    
    defaults = [NSUserDefaults standardUserDefaults];   
}

- (void)swapLoop
{
    
    if ([swapStat count] >= bottomView.frame.size.width/2) [swapStat removeObjectAtIndex:0];
    
    NSString *notice = @"The swap size not be available without permissions to it.";
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:@"/private/var/vm" forced:NO denyNotice:notice];
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];
    unsigned long long swapSize = [self sizeForFolderAtPath:@"/private/var/vm" error:nil];
    NSDictionary *imageAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:@"/private/var/vm/sleepimage" error:nil];
    unsigned long long imageSize = [[imageAttributes objectForKey:NSFileSize] longLongValue];
    swapSize = swapSize-imageSize;
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];

    NSError *err;    
    NSString *bootVolume = [NSString stringWithFormat:@"/Volumes/%@",[[NSFileManager defaultManager] displayNameAtPath:@"/"]];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:bootVolume error:&err];
    if (err) {
        NSLog(@"%@",err);
    }else{
        unsigned long long freeSize = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
        unsigned long long totalSize = [[fileAttributes objectForKey:NSFileSystemSize] longLongValue];
        
        NSDictionary *disk = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithLongLong:swapSize],@"swap",
                              [NSNumber numberWithLongLong:freeSize],@"free",
                              [NSNumber numberWithLongLong:totalSize],@"total",
                              nil];
        
        [swapStat addObject:disk];
    }
    
    [self drawSwap:bottomView];
    
}

- (void)recoveryLoop:(NSDictionary*)dict
{
    
    if (!dict || ![dict isKindOfClass:[NSDictionary class]])
    {
        if ([recoveryStat count] >= topView.frame.size.width/2) [recoveryStat removeObjectAtIndex:0];
        [recoveryStat addObject:[NSDictionary dictionaryWithObject:@"_" forKey:@"type"]];
        
        [self drawRecovery:topView];
        return;
    }
    
    NSString *type = [dict objectForKey:@"type"];
    NSNumber *free = [dict objectForKey:@"free"];
    NSNumber *inact = [dict objectForKey:@"inact"];
    
    if (type && free && inact)
    {
        NSDictionary *recovery = [NSDictionary dictionaryWithObjectsAndKeys:
                                  free,@"free",
                                  inact,@"inact",
                                  type,@"type",
                                  nil];
        
        if ([recoveryStat count] >= topView.frame.size.width/2) [recoveryStat removeObjectAtIndex:0];
        [recoveryStat addObject:recovery];
        
        [self drawRecovery:topView];
    }
}

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:@"AdvancedPopoverEvent"]) {
		return;
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {

        if ([[notif object] isEqualToString:@"becameResponder"])
        {
                        
            if (monitor == nil) monitor = [[MMMonitor alloc] init];
        
            [self swapLoop];
            
            if (swapTimer == nil) swapTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(swapLoop) userInfo:nil repeats:YES];
            
            [self recoveryLoop:nil];
            
            if (recoveryTimer == nil) recoveryTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(recoveryLoop:) userInfo:nil repeats:YES];

        }
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
        if ([[notif object] isEqualToString:@"memoryChange"])
        {
            [self recoveryLoop:[notif userInfo]];
        }
        
    }
}

-(IBAction)showTopHelp:(id)sender
{
    
    NSImageView *view = topView;
    
    if (view)
    {
        if ([view tag] == 1){
            [view setTag:0];
        }else{
            [view setTag:1];
        }
    }
    
    [self drawRecovery:view];
}

-(IBAction)showBottomHelp:(id)sender
{
    
    NSImageView *view = bottomView;
    
    if (view)
    {
        if ([view tag] == 1){
            [view setTag:0];
        }else{
            [view setTag:1];
        }
    }
    
    [self drawSwap:view];
}

- (unsigned long long)sizeForFolderAtPath:(NSString *)source error:(NSError **)error
{
    NSArray * contents;
    NSUInteger size = 0;
    NSEnumerator * enumerator;
    NSString * path;
    BOOL isDirectory;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Determine Paths to Add
    if ([fm fileExistsAtPath:source isDirectory:&isDirectory] && isDirectory)
    {
        contents = [fm subpathsAtPath:source];
    }
    else
    {
        contents = [NSArray array];
    }
    // Add Size Of All Paths
    enumerator = [contents objectEnumerator];
    while (path = [enumerator nextObject])
    {
        NSDictionary * fattrs = [fm attributesOfItemAtPath:[source stringByAppendingPathComponent:path ] error:error];
        size += [[fattrs objectForKey:NSFileSize] unsignedLongLongValue];
    }
    // Return Total Size in Bytes
    
    return size;
}

#pragma mark draw

-(void)drawLegend:(NSArray*)arr sender:(NSView*)sender
{
    float width = sender.frame.size.width/20.0;
    float height = sender.frame.size.height/10.0;
    float spacing = height/1.5;
    float y = spacing;
    //float y = sender.frame.size.height-height-spacing;
    
    [[[NSColor blackColor] colorWithAlphaComponent:0.3] set];
    NSRectFillUsingOperation(NSMakeRect(0, 0, sender.frame.size.width, sender.frame.size.height),NSCompositePlusDarker);
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:arr];
    //[items insertObject:[NSArray arrayWithObjects:[[NSColor whiteColor] colorWithAlphaComponent:0.7],@"[highlights stand for Memory Magic activity]", nil, nil] atIndex:0];
    
    for (NSArray *item in items)
    {
        
        NSColor *color = [item objectAtIndex:0];
        NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(spacing, y, width, height) xRadius:2 yRadius:2];
        [border setLineWidth:0.8];
        [color set];
        [border fill];
        [[[NSColor whiteColor] colorWithAlphaComponent:0.7] setStroke];
        [border stroke];
        
        NSString *text = [item objectAtIndex:1];
		NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica Light" size:12.0] forKey:NSFontAttributeName];
        [attrsDictionary setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:text attributes:attrsDictionary];
        [string drawInRect:NSMakeRect(width+(spacing*2.0), y-(spacing/1.5), sender.frame.size.width - (width*2), height+spacing)];
        
        y += height+(spacing/2.0);
        //y -= height+(spacing/2.0);
    }
}

-(void)drawShine:(CGRect)rect
{
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    
    [[NSColor clearColor] set];
    
    //create triangle path
    CGMutablePathRef substractTriangle  = CGPathCreateMutable();
    CGPathMoveToPoint(substractTriangle, NULL,0,rect.size.height);
    CGPathAddLineToPoint(substractTriangle, NULL,0,rect.size.height/2.0);
    CGPathAddLineToPoint(substractTriangle, NULL,rect.size.width,rect.size.height);
    
    //clip anything outside triangle
    CGContextBeginPath (context);
    CGContextAddPath(context, substractTriangle);
    CGContextClosePath (context);
    CGContextClip (context);
    CGPathRelease(substractTriangle);
    
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor whiteColor] colorWithAlphaComponent:0.2] endingColor:[[NSColor whiteColor] colorWithAlphaComponent:0.0]];
    [gradient drawInRect:rect angle:180];
    
}

- (void)drawRecovery:(NSImageView*)view
{
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(view.frame.size.width,view.frame.size.height)];
    
	float height = view.frame.size.height;
	float width = view.frame.size.width;
	float barWidth = view.frame.size.width/[recoveryStat count];
    float whiteSpace = 0.75;
    
    if (barWidth < 1 ) barWidth = 1.0;
    if (barWidth == 1) whiteSpace = 0.0;
    
	[image lockFocus];
    
    int count = 0;
    NSDictionary *memoryDict = nil;
    
    for (memoryDict in recoveryStat)
    {
        float y = 0.0;
        float ybottom = 0.0;
        NSString *type = [memoryDict objectForKey:@"type"];
        float total = (float)[[NSProcessInfo processInfo] physicalMemory];
        float inact = [[memoryDict objectForKey:@"inact"] floatValue]/total;
        float free = [[memoryDict objectForKey:@"free"] floatValue]/total;
        
        NSColor *firstColor = [NSColor blackColor];
        if ([type isEqualToString:@"MM"])  firstColor = [NSColor greenColor];
        if ([type isEqualToString:@"User"]) firstColor = [NSColor orangeColor];
        if ([type isEqualToString:@"Kernel"]) firstColor = [NSColor redColor];
        firstColor = [firstColor shadowWithLevel:0.40];
        NSColor *secondColor = [firstColor highlightWithLevel:0.60];
        
		[[[NSColor whiteColor] colorWithAlphaComponent:0.75] set];
    
        NSGradient *gradient;
        
        y = free * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[firstColor colorWithAlphaComponent:0.7] endingColor:firstColor];
        if (y - whiteSpace > 0)[gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
        NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y = inact * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[secondColor colorWithAlphaComponent:0.7] endingColor:secondColor];
        if (y - whiteSpace > 0)[gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        
        NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        if ([recoveryStat count] < 60) NSRectFill (NSMakeRect(barWidth*count, 0, whiteSpace, height));//vertical line
        
        //add tick
        [[firstColor colorWithAlphaComponent:0.1] set];
        NSRectFillUsingOperation(NSMakeRect(barWidth*count, 0, barWidth, height),NSCompositeHighlight);
        
        count++;
    }
    
    if ([view tag] == 1) {
        NSArray *items = [NSArray arrayWithObjects:
                          [NSArray arrayWithObjects:[[[NSColor greenColor] shadowWithLevel:0.40] colorWithAlphaComponent:0.8],@"Memory recovered by Memory Magic", nil],
                          [NSArray arrayWithObjects:[[[NSColor orangeColor] shadowWithLevel:0.40] colorWithAlphaComponent:0.8],@"Memory recovered by user", nil],
                          [NSArray arrayWithObjects:[[[NSColor redColor] shadowWithLevel:0.40] colorWithAlphaComponent:0.8],@"Memory recovered by kernel", nil],
                          nil];
        [self drawLegend:items sender:view];
    }
    
    //draw border
    NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, width, height) xRadius:4 yRadius:4];
    [border setLineWidth:2.0];
    [[NSColor whiteColor] set];
    [border stroke];
    
    //blank corners
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0, 0, 1, 1));
    NSRectFill(NSMakeRect(0, height-1, 1, 1));
    NSRectFill(NSMakeRect(width-1, 0, 1, 1));
    NSRectFill(NSMakeRect(width-1, height-1, 1, 1));
    
    //clip anything outside base rectangle
    //CGContextSaveGState(context);
    //CGContextAddPath(context, border.CGPath);
    //CGContextClip(context);
    
    [self drawShine:NSMakeRect(0, 0, view.frame.size.width,view.frame.size.height)];
    
	[image unlockFocus];
    
    [view setImage:image];
}

- (void)drawSwap:(NSImageView*)view
{
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(view.frame.size.width,view.frame.size.height)];
    
	float height = view.frame.size.height;
	float width = view.frame.size.width;
	float barWidth = view.frame.size.width/[swapStat count];
    float whiteSpace = 0.3;
    
    if (barWidth < 1 ) barWidth = 1.0;
    if (barWidth == 1) whiteSpace = 0.0;
    
	[image lockFocus];
    
    int count = 0;
    NSDictionary *memoryDict = nil;
    for (memoryDict in swapStat)
    {
        float y = 0.0;
        float ybottom = 0.0;
        float total = [[memoryDict objectForKey:@"swap"] floatValue]+[[memoryDict objectForKey:@"free"] floatValue];
        float swap = [[memoryDict objectForKey:@"swap"] floatValue]/total;
        float free = [[memoryDict objectForKey:@"free"] floatValue]/total;
        
		[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
        
        NSGradient *gradient;
        
        y = swap * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor orangeColor] colorWithAlphaComponent:0.7] endingColor:[NSColor orangeColor]];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y = free * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[GREEN_COLOR colorWithAlphaComponent:0.7] endingColor:GREEN_COLOR];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        
        if ([swapStat count] < 60) NSRectFill (NSMakeRect(barWidth*count, 0, whiteSpace, height));//vertical line
        
        //add tick
        if ([[memoryDict objectForKey:@"tick"] boolValue] == YES) {
            [[[NSColor whiteColor] colorWithAlphaComponent:0.2] set];
            NSRectFillUsingOperation(NSMakeRect(barWidth*count, 0, barWidth, height),NSCompositeHighlight);
        }
        
        count++;
    }
    
    memoryDict = [swapStat lastObject];
    
    if ([view tag] == 1) {
        NSArray *items = [NSArray arrayWithObjects:
                          [NSArray arrayWithObjects:[[NSColor orangeColor] colorWithAlphaComponent:0.8],[NSString stringWithFormat:@"Swap %@",[self humanizeSize:[[memoryDict objectForKey:@"swap"] longLongValue]]], nil],
                          [NSArray arrayWithObjects:[GREEN_COLOR colorWithAlphaComponent:0.8],[NSString stringWithFormat:@"Free %@",[self humanizeSize:[[memoryDict objectForKey:@"free"] longLongValue]]], nil],
                          [NSArray arrayWithObjects:[[NSColor whiteColor] colorWithAlphaComponent:0.1],[NSString stringWithFormat:@"Total %@",[self humanizeSize:[[memoryDict objectForKey:@"total"] longLongValue]]], nil],
                          nil];
        [self drawLegend:items sender:view];
    }
    
    //draw border
    NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, width, height) xRadius:4 yRadius:4];
    [border setLineWidth:2.0];
    [[NSColor whiteColor] set];
    [border stroke];
    
    //blank corners
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0, 0, 1, 1));
    NSRectFill(NSMakeRect(0, height-1, 1, 1));
    NSRectFill(NSMakeRect(width-1, 0, 1, 1));
    NSRectFill(NSMakeRect(width-1, height-1, 1, 1));
    
    //clip anything outside base rectangle
    //CGContextSaveGState(context);
    //CGContextAddPath(context, border.CGPath);
    //CGContextClip(context);
    
    [self drawShine:NSMakeRect(0, 0, view.frame.size.width,view.frame.size.height)];
    
	[image unlockFocus];
    
    [view setImage:image];
}

-(NSString *)humanizeSize:(long long)value
{
    
    float ret = 0.0;
	NSString *sizeType = @"";
    
	if (value >= 1000000000000){ //base 10
		ret = value / 1000000000000.0; sizeType = @"TB";
	}else if (value >= 1000000000){
		ret = value / 1000000000.0; sizeType = @"GB";
	}else if (value >= 1000000)	{
		ret = value / 1000000.0; sizeType = @"MB";
	}else if (value >= 1000) {
		ret = value / 1000.0; sizeType = @"KB";
	}else if (value >= 0){
		ret = (float)value; sizeType = @"B";
	}
    
    BOOL IEC = NO;
    
    if (IEC == YES) { //base 2
        if (value >= 1099511627776){
            ret = value / 1099511627776.0; sizeType = @"TiB";
        }else if (value >= 1073741824){
            ret = value / 1073741824.0; sizeType = @"GiB";
        }else if (value >= 1048576)	{
            ret = value / 1048576.0; sizeType = @"MiB";
        }else if (value >= 1024) {
            ret = value / 1024.0; sizeType = @"KiB";
        }else if (value >= 0){
            ret = (float)value; sizeType = @"B";
        }
    }
	
	return [NSString stringWithFormat:@"%.1f %@",ret,sizeType];
}

@end
