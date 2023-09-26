//
//  PopoverController.m
//  Memory Magic
//
//  Created by Vlad Alexa on 11/1/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "PopoverController.h"

#include <mach/mach_host.h>

#import "MenuBarIcon.h"

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

@interface PopoverController ()

@end

@implementation PopoverController

- (void)freeLoop
{
    if (_waitAfterAppQuit) return;
    NSDictionary *memoryDict = [[memoryStat lastObject] objectForKey:@"vm"];
    if (!memoryDict) {
        //when ran from back without ever loading front pane
        [self memoryLoop];
        memoryDict = [[memoryStat lastObject] objectForKey:@"vm"];
    }else if (tenSecTimer == nil){
        //when no ten sec timer is refreshing the data
        [self memoryLoop];
        memoryDict = [[memoryStat lastObject] objectForKey:@"vm"];
    }
    float perc = [[memoryDict objectForKey:@"free"] floatValue]/[[memoryDict objectForKey:@"total"] floatValue]*100.0;
    if (perc < 25 ) {
        //NSLog(@"Under 25%%, freeing");       
        [self freeMem:nil];
    }
}

- (void)memoryLoop
{
    if (inProgress == YES) return;
    
    if ([memoryStat count] >= leftView.frame.size.width) [memoryStat removeObjectAtIndex:0];
    
    //rm
	vm_statistics_data_t vm_stat;
	int count = HOST_VM_INFO_COUNT;
	kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (integer_t*)&vm_stat, (mach_msg_type_number_t*)&count);
	
	if(kernReturn != KERN_SUCCESS) return;
	
    float wire = ((vm_stat.wire_count * vm_page_size) / 1024.0) / 1024.0;
    float active = ((vm_stat.active_count * vm_page_size) / 1024.0) / 1024.0;
    float inactive = ((vm_stat.inactive_count * vm_page_size) / 1024.0) / 1024.0;
    float free = ((vm_stat.free_count * vm_page_size) / 1024.0) / 1024.0;
    float spec = ((vm_stat.speculative_count * vm_page_size)  / 1024.0) / 1024.0;
    
    float cow = ((vm_stat.cow_faults * vm_page_size) / 1024.0) / 1024.0;
    float zf = ((vm_stat.zero_fill_count * vm_page_size) / 1024.0) / 1024.0;
    float react = ((vm_stat.reactivations * vm_page_size) / 1024.0) / 1024.0;
    float pageins = ((vm_stat.pageins * vm_page_size) / 1024.0) / 1024.0;
    float pageouts = ((vm_stat.pageouts * vm_page_size) / 1024.0) / 1024.0;
    
	float avail = free+inactive;
	float used = wire+active;
    float total = avail+used;
    
    if (([[NSProcessInfo processInfo] physicalMemory]/1024/1024) - total > 10) NSLog(@"Total memory missmatch %1.f",total);
    
    //save new data
    NSDictionary *vm = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithFloat:wire],@"wired",
                        [NSNumber numberWithFloat:active],@"active",
                        [NSNumber numberWithFloat:inactive],@"inactive",
                        [NSNumber numberWithFloat:free],@"free",
                        [NSNumber numberWithFloat:spec],@"speculative",
                        [NSNumber numberWithFloat:used],@"used",
                        [NSNumber numberWithFloat:avail],@"avail",
                        [NSNumber numberWithFloat:total],@"total",
                        [NSNumber numberWithFloat:cow],@"cow",
                        [NSNumber numberWithFloat:zf],@"zf",
                        [NSNumber numberWithFloat:react],@"react",
                        [NSNumber numberWithFloat:pageins],@"in",
                        [NSNumber numberWithFloat:pageouts],@"out",
                        [NSNumber numberWithBool:tick],@"tick",
                        nil];
    
    [memoryStat addObject:[NSDictionary dictionaryWithObjectsAndKeys:vm,@"vm", nil]];
    
    //factor tick change
    if (tick == YES) {
        tick = NO;
        long long free = [[memoryStatBeforeRun objectForKey:@"free"] longLongValue] * 1024 * 1024;
        long long inactive = [[memoryStatBeforeRun objectForKey:@"inactive"] longLongValue] * 1024 * 1024;
        long long freed = ((vm_stat.free_count*vm_page_size) - free);
        long long inactivated = (inactive - (vm_stat.inactive_count*vm_page_size));
        if (freed > 100 * 1024 * 1024) {
            NSString *msg = [NSString stringWithFormat:@"Magic Memory freed %@",[self humanizeSize:freed]];
            NSLog(@"%@",msg);
            if (![popOver isShown] && ![popOverBack isShown]) [self userNotif:@"Memory freed" message:msg];
            long lifetime = [[defaults objectForKey:@"lifetimeRecovered"] integerValue]; //in TB
            [defaults setObject:[NSNumber numberWithFloat:lifetime+(freed/1099511627776.0)] forKey:@"lifetimeRecovered"];
            [defaults synchronize];
        }
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"MM",@"type",[NSNumber numberWithLongLong:freed],@"free",[NSNumber numberWithLongLong:inactivated],@"inact", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AdvancedPopoverEvent" object:@"memoryChange" userInfo:dict];
    }
    
    //pie
	NSMutableArray *sliceNumbers = [NSMutableArray array];    
    [sliceNumbers addObject:[NSNumber numberWithFloat:wire/total]];
	[sliceNumbers addObject:[NSNumber numberWithFloat:active/total]];
	[sliceNumbers addObject:[NSNumber numberWithFloat:inactive/total]];
	[sliceNumbers addObject:[NSNumber numberWithFloat:free/total]];
    if (![pieView isHidden]) pieView.sliceValues = sliceNumbers;
    
    [menuView setImage:[self pieChart:menuView.frame.size slice:(wire+active+inactive)/total]];
    
    NSString *percent = [NSString stringWithFormat:@"%.0f%%",(wire+active+inactive)/total*100];
    [pieMiddleLabel setToolTip:[NSString stringWithFormat:@"%@ used (%.0f%% inactive, %.0f%% active, %.0f%% wired)",percent,inactive/total*100,active/total*100,wire/total*100]];
    [[pieMiddleLabel animator] setStringValue:[NSString stringWithFormat:@"%@",[self humanizeSize:vm_stat.free_count*vm_page_size]]];
    
    [self drawLeft];
    [self drawRight];
    
    [progressView setHidden:YES];
    [progressView setImage:nil];
}

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:@"PopoverEvent"]) {
		return;
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {
        if ([[notif object] isEqualToString:@"leftSlide"])
        {
            if ([[slideView identifier] isEqualToString:@"["]) {   
                [slideView setIdentifier:@"|"];
                [[slideView animator] setFrame:NSMakeRect(-slideView.frame.size.width/2+self.view.frame.size.width/2, 0, slideView.frame.size.width, slideView.frame.size.height)];
            }else if ([[slideView identifier] isEqualToString:@"|"]) {
                [slideView setIdentifier:@"]"];
                [[slideView animator] setFrame:NSMakeRect(-slideView.frame.size.width+self.view.frame.size.width, 0, slideView.frame.size.width, slideView.frame.size.height)];
            }else if ([[slideView identifier] isEqualToString:@"]"]) {
                [slideView setWantsLayer:YES];
                [self horizontalBounceEnd:slideView];
            }
            if ([defaults objectForKey:@"changedSlides"] == nil) {
                [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"changedSlides"];
                [defaults synchronize];
                [swipeLabel setHidden:YES];
            }
        }
        if ([[notif object] isEqualToString:@"rightSlide"])
        {
            if ([[slideView identifier] isEqualToString:@"]"]) {
                [slideView setIdentifier:@"|"];
                [[slideView animator] setFrame:NSMakeRect(-slideView.frame.size.width/2+self.view.frame.size.width/2, 0, slideView.frame.size.width, slideView.frame.size.height)];
            }else if ([[slideView identifier] isEqualToString:@"|"]) {
                [slideView setIdentifier:@"["];
                [[slideView animator] setFrame:NSMakeRect(0, 0, slideView.frame.size.width, slideView.frame.size.height)];
            }else if ([[slideView identifier] isEqualToString:@"["]) {
                [slideView setWantsLayer:YES];
                [self horizontalBounceEnd:slideView];
            }
            if ([defaults objectForKey:@"changedSlides"] == nil) {
                [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"changedSlides"];
                [defaults synchronize];
                [swipeLabel setHidden:YES];                
            }
        }
        if ([[notif object] isEqualToString:@"becameResponder"])
        {

            if ([defaults objectForKey:@"changedSlides"] == nil) {
                [slideView setWantsLayer:YES];
                [self horizontalBounce:slideView];
                [[swipeLabel animator] performSelector:@selector(setHidden:) withObject:nil afterDelay:2.0];
            }

            if ([menuView isHidden] == NO) {
                //initial load
                pieView.sliceValues = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0001],[NSNumber numberWithFloat:0.0001],[NSNumber numberWithFloat:0.0001],[NSNumber numberWithFloat:0.0001], nil];
                [pieView setHidden:YES];
                [pieMiddleLabel setHidden:YES];
                [pieSmallLabel setHidden:YES];
                [self memoryLoop];
                tenSecTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(memoryLoop) userInfo:nil repeats:YES];
                [self performSelector:@selector(showPie) withObject:nil afterDelay:7.5];
                [[pieMiddleLabel animator] performSelector:@selector(setHidden:) withObject:nil afterDelay:11.0];
                [[pieSmallLabel animator] performSelector:@selector(setHidden:) withObject:nil afterDelay:11.0];
            }else{
                //clear help
                [leftView setTag:0];
                [rightView setTag:0];
            }           
        }
        if ([[notif object] isEqualToString:@"force"]) {
            [self freeMem:popOverBack.contentViewController.view.window];
        }
	}
}


-(void)awakeFromNib
{
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"PopoverEvent" object:nil];
    
    [self.view addSubview:slideView];
    [slideView setFrame:NSMakeRect(-slideView.frame.size.width/2+self.view.frame.size.width/2, 0, slideView.frame.size.width, slideView.frame.size.height)];
    [slideView setIdentifier:@"|"];
    
    [menuView setImage:[self pieChart:menuView.frame.size slice:0.0]];
    
    memoryStat = [NSMutableArray arrayWithCapacity:leftView.frame.size.width];
    
    memoryStatBeforeRun = [[NSMutableDictionary alloc] init];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(freeLoop) userInfo:nil repeats:YES];
}

-(void)didTerminate:(NSNotification*)notification
{
    _waitAfterAppQuit = YES;
    [self performSelector:@selector(setWaitAfterAppQuit:) withObject:nil afterDelay:5];
}

-(void)freeMem:(id)sender
{
    NSDictionary *memoryDict = [[memoryStat lastObject] objectForKey:@"vm"];
    if (!memoryDict) {
        //when ran from back without ever loading front pane
        [self memoryLoop];
        memoryDict = [[memoryStat lastObject] objectForKey:@"vm"];        
    }
    float free = ([[memoryDict objectForKey:@"free"] floatValue] * 1024.0) * 1024.0;
    float size = ([[memoryDict objectForKey:@"inactive"] floatValue] * 1024.0) * 1024.0;
    float perc = [[memoryDict objectForKey:@"inactive"] floatValue]/[[memoryDict objectForKey:@"total"] floatValue]*100.0;
    
    if (perc < 5 ) size = free;
    if (perc > 50 ) size = size/2.0;
    if (free > size) size += free/2.0;
    
    if (size < 1024) {
        if (sender) [self shakeWindow:popOverBack.contentViewController.view.window];
        //[self userNotif:@"Unable to recover memory" message:@"No memory available to free"];
        //NSLog(@"No memory available to free");
        return;
    }
    
    if ([MenuBarIcon skipWorkBasedOnAPM] && !sender) {
        //[self userNotif:@"Aborted recovering memory" message:@"CPU load too high"];
        //NSLog(@"CPU load too high");
        return;
    }
        
    if (sender && [menuView isHidden]) [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuBarEvent" object:@"click" userInfo:nil];
    if (tenSecTimer && [pieView isHidden]) {
        //in case the user initailizes the app just before free triggered and still has not seen the init animation
        [self performSelector:@selector(freeMemDelayed:) withObject:[NSNumber numberWithFloat:size] afterDelay:12.0];
    }else{
        [self performSelector:@selector(freeMemDelayed:) withObject:[NSNumber numberWithFloat:size] afterDelay:1.0];
    }
}

-(void)freeMemDelayed:(NSNumber *)sizeNumber
{
    if (inProgress) return;
    
    float size = [sizeNumber floatValue];
    
    [memoryStatBeforeRun setDictionary:[[memoryStat lastObject] objectForKey:@"vm"]];
    NSString *preValue = [pieMiddleLabel stringValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuBarIconEvent" object:@"progressStart" userInfo:nil];
    [pieMiddleLabel setFont:[NSFont fontWithName:@"Helvetica Light" size:25]];
    [pieMiddleLabel setStringValue:@"working"];
    [pieSmallLabel setStringValue:@"trying to free memory"];
    [progressView setHidden:NO];
    inProgress = YES;
    tick = NO;     
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        NSMutableData *data = [NSMutableData dataWithCapacity:1];
        float lastTick = 0.0;
        while ([data length] < size)
        {
            if (CFAbsoluteTimeGetCurrent()-startTime > 10) {
                NSLog(@"Aborted freeing mem after 10 seconds");
                break;
            }
            
            [data appendBytes:MEM_FILL length:400];
            
            float t = [self tickX:11 timesOfTotal:size current:[data length] lastTick:lastTick];
            if (t > 0) {
                //NSLog(@"allocated %.1f %f",[data length] / 1024.0 / 1024.0,t);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuBarIconEvent" object:[NSString stringWithFormat:@"%f",t] userInfo:[NSDictionary dictionary]];
                [progressView setImage:[self progressChart:NSMakeSize(190, 190) slice:t]];
                lastTick = t;                
            }
        }
        //NSLog(@"Attempted to free %.1f MiB memory in %.1f sec",size / 1024.0 / 1024.0,CFAbsoluteTimeGetCurrent()-startTime);
        
        tick = YES;
        inProgress = NO;
        [progressView setImage:nil];
        [progressView setHidden:YES];
        [pieMiddleLabel setStringValue:preValue];
        [pieSmallLabel setStringValue:@"free memory"];
        [pieMiddleLabel setFont:[NSFont fontWithName:@"Helvetica Light" size:32]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuBarIconEvent" object:@"progressEnd" userInfo:nil];
        [self performSelector:@selector(memoryLoop) withObject:nil afterDelay:2.0];
    });
}

-(IBAction)alternateLeft:(id)sender
{
    //if ([[slideView identifier] isEqualToString:@"|"]) return; //disable switching from center
    
    if (alternateLeft) {
        alternateLeft = NO;
        [leftLabel setStringValue:@"RAM history"];
    }else{
        alternateLeft = YES;
        [leftLabel setStringValue:@"Swap history"];
    }
    
    [self drawLeft];    
    
}

-(IBAction)alternateRight:(id)sender
{
    //if ([[slideView identifier] isEqualToString:@"|"]) return; //disable switching from center
    
    if (alternateRight) {
        alternateRight = NO;
        [rightLabel setStringValue:@"Swap history"];
    }else{
        alternateRight = YES;
        [rightLabel setStringValue:@"RAM history"];
    }
    
    [self drawRight];
    
}

-(IBAction)showHelp:(id)sender
{
    NSImageView *view = nil;
    if ([[slideView identifier] isEqualToString:@"["]) {
        view = leftView;
    }
    if ([[slideView identifier] isEqualToString:@"]"]) {
        view = rightView;
    }
    
    if (view)
    {
        if ([view tag] == 1){
            [view setTag:0];
        }else{
            [view setTag:1];
        }
    }
    
    if (view == leftView) [self drawLeft];
    if (view == rightView) [self drawRight];
    
}

#pragma mark anim

-(void)horizontalBounceEnd:(NSView*)theView
{
    float start = theView.layer.position.x;
    float direction = 1.0;
    if (start > 0) direction = -1.0;
    
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
    [animation setDuration:0.5];
    [animation setRepeatCount:1];
    
	NSMutableArray *values = [NSMutableArray array];
    
    [values addObject:[NSNumber numberWithFloat:start-50.0*direction]];
    
    [values addObject:[NSNumber numberWithFloat:start+25.0*direction]];
    
    [values addObject:[NSNumber numberWithFloat:start]];    
    
	[animation setValues:values];
    
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    
	[theView.layer addAnimation:animation forKey:@"position.x"];
}

-(void)horizontalBounce:(NSView*)theView
{

    float start = theView.layer.position.x;
    
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
    [animation setDuration:1.0];
    [animation setRepeatCount:1];
    
	NSMutableArray *values = [NSMutableArray array];
    
    [values addObject:[NSNumber numberWithFloat:start-20.0]];
    
    [values addObject:[NSNumber numberWithFloat:start+20.0]];
    
    [values addObject:[NSNumber numberWithFloat:start-10.0]];
    
    [values addObject:[NSNumber numberWithFloat:start+10.0]];
    
    [values addObject:[NSNumber numberWithFloat:start]];
    
	[animation setValues:values];
    
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
	[theView.layer addAnimation:animation forKey:@"position.x"];
    
}

-(void)shakeWindow:(NSWindow*)w{
	
    NSRect f = [w frame];
    int c = 0; //counter variable
    int off = -8; //shake amount (offset)
    while(c<4) //shake 5 times
    {
        [w setFrame: NSMakeRect(f.origin.x + off,
                                f.origin.y,
                                f.size.width,
                                f.size.height) display: NO];
        [NSThread sleepForTimeInterval: .04]; //slight pause
        off *= -1; //back and forth
        c++; //inc counter
    }
    [w setFrame:f display: NO]; //return window to original frame
}

-(void) showPie
{
    NSViewAnimation *theAnim;
    NSMutableDictionary* firstViewDict;
    NSMutableDictionary* secondViewDict;
	
    firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [firstViewDict setObject:menuView forKey:NSViewAnimationTargetKey];
    [firstViewDict setObject:[NSValue valueWithRect:[menuView frame]] forKey:NSViewAnimationStartFrameKey];
    [firstViewDict setObject:[NSValue valueWithRect:[pieView frame]] forKey:NSViewAnimationEndFrameKey];
    
    secondViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [secondViewDict setObject:pieView forKey:NSViewAnimationTargetKey];
    [secondViewDict setObject:[NSValue valueWithRect:[pieView frame]] forKey:NSViewAnimationStartFrameKey];
    [secondViewDict setObject:[NSValue valueWithRect:[menuView frame]] forKey:NSViewAnimationEndFrameKey];
    
    [firstViewDict setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
	[secondViewDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];

    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict, secondViewDict, nil]];
    [theAnim setDuration:3.0];
    [theAnim setAnimationCurve:NSAnimationLinear];
    [theAnim startAnimation];
}

#pragma mark graphs

-(void)drawLeft
{
    if ([[leftLabel stringValue] isEqualToString:@"Swap history"]) {
        [self drawSwap:leftView];
        return;
    }
    if ([[leftLabel stringValue] isEqualToString:@"RAM history"]) {
        [self drawRAM:leftView];
        return;
    }
    NSLog(@"Unknown left content: %@",[leftLabel stringValue]);
}

-(void)drawRight
{
    if ([[rightLabel stringValue] isEqualToString:@"Swap history"]){
        [self drawSwap:rightView];
        return;
    }
    if ([[rightLabel stringValue] isEqualToString:@"RAM history"]){
        [self drawRAM:rightView];
        return;
    }
    NSLog(@"Unknown right content: %@",[rightLabel stringValue]);
}


-(NSImage*)pieChart:(CGSize)size slice:(float)slice
{
    
    NSImage *compositeImage = [[NSImage alloc] initWithSize:size];
	[compositeImage setCacheMode:NSImageCacheNever];
    [compositeImage lockFocus];
    
    float offset = 90.0;
    
    NSColor *topColor = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.1];
    NSColor *botColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.1];
    NSGradient *aGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];
    
    CGPoint center = CGPointMake(size.width/2, size.height/2);
    CGFloat radius = MIN(center.x-1, center.y-1);
    
    NSBezierPath *piePath = [NSBezierPath bezierPath];
    [piePath appendBezierPathWithArcWithCenter:center radius:radius startAngle:0.0 endAngle:360.0 clockwise:NO];
    piePath.lineWidth = 0.3;
    [[[NSColor blackColor] colorWithAlphaComponent:0.5] setStroke]; 
    [piePath stroke];
    
    if (slice < 1.0) {
        NSBezierPath *slicePath = [NSBezierPath bezierPath];
        slicePath.lineWidth = 0.7;
        [slicePath moveToPoint:center];
        [slicePath lineToPoint:CGPointMake(center.x + radius * cosf(DEG2RAD(offset)), center.y + radius * sinf(DEG2RAD(offset)))];
        [slicePath appendBezierPathWithArcWithCenter:center radius:radius startAngle:offset endAngle:360-(slice*360)+offset clockwise:YES];
        [slicePath closePath]; // this will automatically add a straight line to the center
        [[NSColor blackColor] setStroke];
        [aGradient drawInBezierPath:slicePath angle:-90];
        [slicePath stroke];      
    }else{
        [aGradient drawInBezierPath:piePath angle:-90];
    }
    
    [compositeImage unlockFocus];
    
    return compositeImage;
}

-(NSImage*)progressChart:(CGSize)size slice:(float)slice
{
    if (slice > 0.94) slice = 0.9999;
    
    NSImage *compositeImage = [[NSImage alloc] initWithSize:size];
	[compositeImage setCacheMode:NSImageCacheNever];
    [compositeImage lockFocus];
    
    float offset = 90.1;
    
    CGPoint center = CGPointMake(size.width/2.0, size.height/2.0);
    CGFloat radius = MIN(center.x-1.0, center.y-1.0);
        
    NSBezierPath *slicePath = [NSBezierPath bezierPath];
    slicePath.lineWidth = 0.7;
    [slicePath moveToPoint:center];
    [slicePath lineToPoint:CGPointMake(center.x + radius * cosf(DEG2RAD(offset)), center.y + radius * sinf(DEG2RAD(offset)))];
    [slicePath appendBezierPathWithArcWithCenter:center radius:radius startAngle:offset endAngle:360-(slice*360.0)+offset clockwise:YES];
    [slicePath closePath];
    [[NSColor blackColor] setFill];
    [slicePath fill];
    
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    
    if (!CGContextIsPathEmpty(context)) CGContextClip(context);
    
    CGContextSetFillColorWithColor( context, [NSColor redColor].CGColorCompat );
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGRect holeRect= CGRectMake((size.width-radius*1.6)/2.0, (size.height-radius*1.6)/2.0, radius*1.6, radius*1.6);
    CGContextFillEllipseInRect( context, holeRect );
    
    [compositeImage unlockFocus];
    
    return compositeImage;
}

-(void)drawLegend:(NSArray*)arr sender:(NSView*)sender
{
    float width = sender.frame.size.width/17.0;
    float height = sender.frame.size.height/20.0;
    float spacing = height/1.7;
    float y = spacing;
    //float y = sender.frame.size.height-height-spacing;
    
    [[[NSColor blackColor] colorWithAlphaComponent:0.3] set];
    NSRectFillUsingOperation(NSMakeRect(0, 0, sender.frame.size.width, sender.frame.size.height),NSCompositePlusDarker);
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:arr];
    [items insertObject:[NSArray arrayWithObjects:[[NSColor whiteColor] colorWithAlphaComponent:0.7],@"[highlights stand for Memory Magic activity]", nil, nil] atIndex:0];
    
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

- (void)drawRAM:(NSImageView*)view
{
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(view.frame.size.width,view.frame.size.height)];
    
	float height = view.frame.size.height;
	float width = view.frame.size.width;
	float barWidth = view.frame.size.width/[memoryStat count];
    float whiteSpace = 0.3;
    
    if (barWidth < 1 ) barWidth = 1.0;
    if (barWidth == 1) whiteSpace = 0.0;
    
	[image lockFocus];
    
    int count = 0;
    for (NSDictionary *dict in memoryStat)
    {
        NSDictionary *memoryDict = [dict objectForKey:@"vm"];
        float y = 0.0;
        float ybottom = 0.0;
        float total = [[memoryDict objectForKey:@"total"] floatValue];
        float wired = [[memoryDict objectForKey:@"wired"] floatValue]/total;
        float active = [[memoryDict objectForKey:@"active"] floatValue]/total;
        float inactive = [[memoryDict objectForKey:@"inactive"] floatValue]/total;
        float free = [[memoryDict objectForKey:@"free"] floatValue]/total;
        
		[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
        
        NSGradient *gradient;
        
        y =  wired * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[RED_COLOR colorWithAlphaComponent:0.7] endingColor:RED_COLOR];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y = active * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[ORANGE_COLOR colorWithAlphaComponent:0.7] endingColor:ORANGE_COLOR];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y = inactive * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[BLUE_COLOR colorWithAlphaComponent:0.7] endingColor:BLUE_COLOR];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y = free * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[GREEN_COLOR colorWithAlphaComponent:0.7] endingColor:GREEN_COLOR];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));

        
        if ([memoryStat count] < 60) NSRectFill (NSMakeRect(barWidth*count, 0, whiteSpace, height));//vertical line
        
        //add tick
        if ([[memoryDict objectForKey:@"tick"] boolValue] == YES) {
            [[[NSColor whiteColor] colorWithAlphaComponent:0.2] set];
            NSRectFillUsingOperation(NSMakeRect(barWidth*count, 0, barWidth, height),NSCompositeHighlight);
        }
        
        count++;
    }
        
    if ([view tag] == 1) {
        NSArray *items = [NSArray arrayWithObjects:
                          [NSArray arrayWithObjects:RED_COLOR,@"Wired (non-swapable non-available memory)", nil],
                          [NSArray arrayWithObjects:ORANGE_COLOR,@"Active (swapable non-available memory)", nil],
                          [NSArray arrayWithObjects:BLUE_COLOR,@"Inactive (non-empty available memory)", nil],
                          [NSArray arrayWithObjects:GREEN_COLOR,@"Free (empty available memory)", nil],
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
	float barWidth = view.frame.size.width/[memoryStat count];
    float whiteSpace = 0.3;
    
    if (barWidth < 1 ) barWidth = 1.0;
    if (barWidth == 1) whiteSpace = 0.0;
    
	[image lockFocus];
    
    int count = 0;
    for (NSDictionary *dict in memoryStat)
    {
        NSDictionary *memoryDict = [dict objectForKey:@"vm"];
        float y = 0.0;
        float ybottom = 0.0;
        float total = [[memoryDict objectForKey:@"cow"] floatValue]+[[memoryDict objectForKey:@"out"] floatValue]+[[memoryDict objectForKey:@"in"] floatValue]+[[memoryDict objectForKey:@"react"] floatValue];
        float outs = [[memoryDict objectForKey:@"out"] floatValue]/total; //should be lower than ins
        float shared = [[memoryDict objectForKey:@"cow"] floatValue]/total; //shared
        float ins = [[memoryDict objectForKey:@"in"] floatValue]/total; //should be higher than outs
        float inactive = [[memoryDict objectForKey:@"react"] floatValue]/total; //inactive
        
		[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
        
        NSGradient *gradient;
        
        y = outs * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor blackColor] colorWithAlphaComponent:0.4] endingColor:[[NSColor blackColor] colorWithAlphaComponent:0.8]];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y = ins * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor grayColor] colorWithAlphaComponent:0.4] endingColor:[[NSColor grayColor] colorWithAlphaComponent:0.8]];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y =  shared * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor orangeColor] colorWithAlphaComponent:0.4] endingColor:[[NSColor orangeColor] colorWithAlphaComponent:0.8]];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        ybottom += y;
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        y = inactive * height;
        gradient = [[NSGradient alloc] initWithStartingColor:[LBLUE_COLOR colorWithAlphaComponent:0.4] endingColor:[LBLUE_COLOR colorWithAlphaComponent:0.8]];
        [gradient drawInRect:NSMakeRect(barWidth*count, ybottom, barWidth, y - whiteSpace) angle:-90];
        
		NSRectFill (NSMakeRect(barWidth*count, ybottom, barWidth, whiteSpace));
        
        if ([memoryStat count] < 60) NSRectFill (NSMakeRect(barWidth*count, 0, whiteSpace, height));//vertical line
        
        //add tick
        if ([[memoryDict objectForKey:@"tick"] boolValue] == YES) {
            [[[NSColor whiteColor] colorWithAlphaComponent:0.2] set];
            NSRectFillUsingOperation(NSMakeRect(barWidth*count, 0, barWidth, height),NSCompositeHighlight);
        }
        
        count++;
    }
    
    if ([view tag] == 1) {
        NSArray *items = [NSArray arrayWithObjects:
                          [NSArray arrayWithObjects:[[NSColor blackColor] colorWithAlphaComponent:0.8],@"Pageouts (should be lower than pageins)", nil],
                          [NSArray arrayWithObjects:[[NSColor grayColor] colorWithAlphaComponent:0.8],@"Pageins (should be higher than pageouts)", nil],
                          [NSArray arrayWithObjects:[[NSColor orangeColor] colorWithAlphaComponent:0.8],@"Copy-on-write (typically is higher than reactiv.)", nil],
                          [NSArray arrayWithObjects:[LBLUE_COLOR colorWithAlphaComponent:0.8],@"Reactivated (typically is lower than C-o-w)", nil],
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

#pragma mark tools

-(NSInteger)vmFromString:(NSString*)str
{
    NSArray *parts = [str componentsSeparatedByString:@":"];
    if ([parts count] == 2) {
        NSString *ret = [[[parts objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"." withString:@""];
        return [ret integerValue]*vm_page_size;
    }else{
        NSLog(@"Error on %@",str);
    }
    return 0;
}


-(NSDictionary*)parseConsole
{
    NSString *vmstring = [self execTask:@"/usr/bin/vm_stat" args:[NSArray array]];
    NSArray *lines = [vmstring componentsSeparatedByString:@"\n"];
    
    NSDictionary *vm = nil;
    if ([lines count] == 14) {
        float vm_wire = ([self vmFromString:[lines objectAtIndex:5]] / 1024.0) / 1024.0;
        float vm_active = ([self vmFromString:[lines objectAtIndex:2]] / 1024.0) / 1024.0;
        float vm_inactive = ([self vmFromString:[lines objectAtIndex:3]] / 1024.0) / 1024.0;
        float vm_free = ([self vmFromString:[lines objectAtIndex:1]] / 1024.0) / 1024.0;
        float vm_spec = ([self vmFromString:[lines objectAtIndex:4]] / 1024.0) / 1024.0;
        
        float vm_avail = vm_free+vm_inactive+vm_spec;
        float vm_used = vm_wire+vm_active;
        float vm_total = vm_avail+vm_used;
        
        float vm_cow = ([self vmFromString:[lines objectAtIndex:7]] / 1024.0) / 1024.0;
        float vm_zf = ([self vmFromString:[lines objectAtIndex:8]] / 1024.0) / 1024.0;
        float vm_react = ([self vmFromString:[lines objectAtIndex:9]] / 1024.0) / 1024.0;
        float vm_pageins = ([self vmFromString:[lines objectAtIndex:10]] / 1024.0) / 1024.0;
        float vm_pageouts = ([self vmFromString:[lines objectAtIndex:11]] / 1024.0) / 1024.0;
        
        vm = [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithFloat:vm_wire],@"wired",
              [NSNumber numberWithFloat:vm_active],@"active",
              [NSNumber numberWithFloat:vm_inactive],@"inactive",
              [NSNumber numberWithFloat:vm_free],@"free",
              [NSNumber numberWithFloat:vm_spec],@"speculative",
              [NSNumber numberWithFloat:vm_used],@"used",
              [NSNumber numberWithFloat:vm_avail],@"avail",
              [NSNumber numberWithFloat:vm_total],@"total",
              [NSNumber numberWithFloat:vm_cow],@"cow",
              [NSNumber numberWithFloat:vm_zf],@"zf",
              [NSNumber numberWithFloat:vm_react],@"react",
              [NSNumber numberWithFloat:vm_pageins],@"in",
              [NSNumber numberWithFloat:vm_pageouts],@"out",
              nil];
    }else{
        NSLog(@"Error got %li lines, expecting 14",[lines count]);
    }
    return vm;
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
    
    BOOL IEC = YES;
    
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

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args
{
    
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:launch] != YES){
        return nil;
    }
    
	NSPipe *stdout_pipe = [[NSPipe alloc] init];
    if (stdout_pipe == nil) {
        NSLog(@"ERROR ran out of file descriptors at %@ %@",launch,[args lastObject]);
        return nil;
    }
    
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:launch];
	[task setArguments:args];
	[task setStandardOutput:stdout_pipe];
    [task setStandardError:[task standardOutput]];
    
    NSFileHandle *stdout_file = [stdout_pipe fileHandleForReading];
    NSMutableString *output = [NSMutableString stringWithCapacity:1];
	
    //set a timer to terminate the task if not done in a timely manner
    NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:task selector:@selector(terminate) userInfo:nil repeats:NO];
	[task launch];
    
    //read all data chunks as they come in
    NSData *inData = nil;
    while ( (inData = [stdout_file availableData]) && [inData length] ) {
        NSString *str = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
        if (str) {
            [output appendString:str];
            if ([output length] > 8000000) {
                NSLog(@"%@ data exceeds maximum, terminating, remaining output skipped",launch);
                [output appendString:@"\n**Data exceeds maximum, remaining output skipped"];
                [task terminate];
                break;
            }
        }
    }
    
	[task waitUntilExit];
    [timeoutTimer invalidate];
    
    if ([task terminationStatus] == 0){
        //NSLog(@"Task %@ succeeded.",launch);
    }else{
        //NSLog(@"Task %@ failed.",launch);
    }
    
    [stdout_file closeFile]; //unless we do this pipes are never released even if documentation says different
    return output;
}

-(void) userNotif:(NSString*)title message:(NSString*)message
{
    if (!title || !message) {
        NSLog(@"Notification with empty %@ / %@",title,message);
        return;
    }
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    if (notif) {
        [notif setTitle:title];
        [notif setInformativeText:message];
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:notif];
    }else {
        NSLog(@"No notification center, logging %@",message);
    }
}

-(float)tickX:(int)times timesOfTotal:(float)total current:(float)current lastTick:(float)last
{
    float ret = last + 0.1;
    float oneUnit = total/times;
    float nextUnit = oneUnit * (ret * 10.0);
    
    if (current > nextUnit){
        return ret;
    }else{
        return  0.0;
    }
}

@end
