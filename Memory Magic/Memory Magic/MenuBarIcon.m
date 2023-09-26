//
//  MenuBarIcon.m
//  Files
//
//  Created by Vlad Alexa on 5/23/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "MenuBarIcon.h"

#import "PieView.h"

#import <QuartzCore/CoreAnimation.h>

#include <mach/mach_host.h>

#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/pwr_mgt/IOPM.h>

@implementation MenuBarIcon

@synthesize mouseDown;

- (void)memoryLoop
{
    if (inPogress == YES) return;
    
	vm_statistics_data_t vm_stat;
	int count = HOST_VM_INFO_COUNT;
	kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (integer_t*)&vm_stat, (mach_msg_type_number_t*)&count);
	
	if(kernReturn != KERN_SUCCESS) return;
	
    float wire = ((vm_stat.wire_count * vm_page_size) / 1024.0) / 1024.0;
    float active = ((vm_stat.active_count * vm_page_size) / 1024.0) / 1024.0;
    float inactive = ((vm_stat.inactive_count * vm_page_size) / 1024.0) / 1024.0;
    float free = ((vm_stat.free_count * vm_page_size) / 1024.0) / 1024.0;
    
	float avail = free+inactive;
	float used = wire+active;
    float total = avail+used;
    
    if (pieSlice != (wire+active+inactive)/total) {
        [self setNeedsDisplay:YES];
    }

    NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
    NSString *percent = [NSString stringWithFormat:@"%.0f%%",(wire+active+inactive)/total*100];
    [tile setBadgeLabel:percent];
    [tile display];
    
    [self setToolTip:[NSString stringWithFormat:@"%.0f MiB free \nClick for graphs, right click for options.",free]];
    
    //[[self window] setAllowsToolTipsWhenApplicationIsInactive:YES]; //useless, is already set
    
    pieSlice = (wire+active+inactive)/total;
    
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        [self memoryLoop];
        
        [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(memoryLoop) userInfo:nil repeats:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MenuBarIconEvent" object:nil];
        
		//NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:frame options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect owner:self userInfo:nil];
		//[self addTrackingArea:area];

    }
    
    return self;
}


-(void)mouseEntered:(NSEvent *)event {
    //[super mouseEntered:event]; //useless
    [self accessibilitySetValue:[self toolTip] forAttribute:NSAccessibilityHelpAttribute];
    [self showContextHelp:self];
}

-(void)mouseExited:(NSEvent *)event {
    //[super mouseExited:event];//useless
    [self accessibilitySetValue:[self toolTip] forAttribute:NSAccessibilityHelpAttribute];
    [self showContextHelp:self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    mouseDown = YES;
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuBarEvent" object:@"click" userInfo:nil];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    mouseDown = YES;
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuBarEvent" object:@"rightclick" userInfo:nil];
}

- (void)drawRect:(NSRect)dirtyRect
{
    
    if (!NSIsEmptyRect(self.bounds)) {
        float height = self.bounds.size.height/1.15;
        imagerect = NSMakeRect(self.bounds.size.width/6.0,self.bounds.size.height/10.0,height,height);
    }
    
    // Drawing code here.
    
    NSImage *image = [self pieChart:imagerect.size slice:pieSlice];
    if (inPogress) image = [self progressChart:imagerect.size slice:progress];
        
	NSImageRep *imagerep = [image bestRepresentationForRect:self.frame context:nil hints:nil];
	[imagerep drawInRect:imagerect];	   
    
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
    
    CGPoint center = CGPointMake(size.width/2.0, size.height/2);
    CGFloat radius = MIN(center.x-1.0, center.y-1.0);
    
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
        [aGradient drawInBezierPath:slicePath angle:-90];
        [slicePath stroke];
        if (slice > 0.75){
            if ([MenuBarIcon skipWorkBasedOnAPM]) {
                [[NSColor whiteColor] setFill]; //color white when low mem and high cpu
            }
            [slicePath fill];//color black when low mem
        }
    }else{
        [aGradient drawInBezierPath:piePath angle:-90];
    }
    
    [compositeImage unlockFocus];
    
    return compositeImage;
}

#pragma mark progress

-(NSImage*)progressChart:(CGSize)size slice:(float)slice
{
    if (slice > 0.94) slice = 0.9999;
    
    NSImage *compositeImage = [[NSImage alloc] initWithSize:size];
	[compositeImage setCacheMode:NSImageCacheNever];
    [compositeImage lockFocus];
    
    float offset = 90.1;
    
    CGPoint center = CGPointMake(size.width/2.0, size.height/2);
    CGFloat radius = MIN(center.x-1.0, center.y-1.0);
    
    NSBezierPath *piePath = [NSBezierPath bezierPath];
    [piePath moveToPoint:NSMakePoint(center.x, center.y+radius)];
    [piePath appendBezierPathWithArcWithCenter:center radius:radius startAngle:offset endAngle:90.1 clockwise:YES];
    [piePath closePath];
    [[NSColor lightGrayColor] setFill];
    [piePath fill];
    
    NSBezierPath *slicePath = [NSBezierPath bezierPath];
    slicePath.lineWidth = 0.7;
    [slicePath moveToPoint:center];
    [slicePath lineToPoint:CGPointMake(center.x + radius * cosf(DEG2RAD(offset)), center.y + radius * sinf(DEG2RAD(offset)))];
    [slicePath appendBezierPathWithArcWithCenter:center radius:radius startAngle:offset endAngle:360-(slice*360)+offset clockwise:YES];
    [slicePath closePath];
    [[NSColor blackColor] setFill];
    [slicePath fill];
    
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    
    if (!CGContextIsPathEmpty(context)) CGContextClip(context);
    
    CGContextSetFillColorWithColor( context, [NSColor redColor].CGColorCompat );
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGRect holeRect= CGRectMake((size.width-radius)/2.0, (size.height-radius)/2.0, radius, radius);
    CGContextFillEllipseInRect( context, holeRect );
    
    [compositeImage unlockFocus];
    
    return compositeImage;
}

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:@"MenuBarIconEvent"]) {
		return;
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {
        if ([[notif object] isEqualToString:@"progressStart"]) {
            inPogress = YES;
            progress = 0.0001;
            [self setNeedsDisplay:YES];
        }
        if ([[notif object] isEqualToString:@"progressEnd"]) {
            inPogress = NO;
            [self setNeedsDisplay:YES];
            [self performSelector:@selector(memoryLoop) withObject:nil afterDelay:3.0];
        }
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
        progress = [[notif object] floatValue];
        [self setNeedsDisplay:YES];        
    }    
}

+(unsigned long)APMAggressiveness
{
    mach_port_t master_device_port;
    io_connect_t fb = 0;
    kern_return_t kr = kIOReturnSuccess;
    IOReturn err = kIOReturnSuccess;
    unsigned long value = 0;
    
    kr = IOMasterPort( bootstrap_port, &master_device_port );
    if ( kr == kIOReturnSuccess ) {
        fb = IOPMFindPowerManagement( master_device_port );
        if ( fb ) {
            err = IOPMGetAggressiveness( fb, kPMGeneralAggressiveness, &value );
            IOServiceClose( fb );
        }
    }
    return value;
}

+(BOOL)skipWorkBasedOnAPM
{
    
    //NSLog(@"APM aggressivness %li",[MenuBarIcon APMAggressiveness]);    

    if ([MenuBarIcon cpuLoad] > 100) {
        NSLog(@"CPU load over 100");
        return YES;
    }
    
    uint32_t thermalLevel;
    IOPMGetThermalWarningLevel(&thermalLevel);
    if (thermalLevel == kIOPMThermalWarningLevelNormal) {
        //NSLog(@"Normal thermal level");
    }else if (thermalLevel == kIOPMThermalWarningLevelCrisis || thermalLevel == kIOPMThermalWarningLevelDanger){
        NSLog(@"%i thermal level",thermalLevel);
        return YES;
    }
    
    if (IOGetSystemLoadAdvisory() != kIOSystemLoadAdvisoryLevelBad){
        //NSLog(@"System load not bad");
    }else{
        NSLog(@"System load is %i",IOGetSystemLoadAdvisory());
        return YES;
    }
    
    return NO;
    
}

+(int)cpuLoad
{
	natural_t numProcessors;
	processor_cpu_load_info_t processorInfo;
	mach_msg_type_number_t numProcessorInfo;
	processor_cpu_load_info_t processorInfo_new;
	mach_msg_type_number_t numProcessorInfo_new;
    
	kern_return_t err = host_processor_info(mach_host_self(),
	                                        PROCESSOR_CPU_LOAD_INFO,
	                                        (natural_t *)&numProcessors,
	                                        (processor_info_array_t *)&processorInfo,
	                                        (mach_msg_type_number_t *)&numProcessorInfo);
    
	if(err != KERN_SUCCESS) NSLog(@"failed to get cpu info");
	if(numProcessorInfo != numProcessors * CPU_STATE_MAX) NSLog(@"numProcessorInfo missmatch");
    
    [NSThread sleepForTimeInterval:1.0];
    
	host_processor_info(mach_host_self(),
                        PROCESSOR_CPU_LOAD_INFO,
                        (natural_t *)&numProcessors,
                        (processor_info_array_t *)&processorInfo_new,
                        (mach_msg_type_number_t *)&numProcessorInfo_new);    
    
    int ret = 0;
	unsigned i;
    
	for(i = 0U; i < numProcessors; ++i)
    {
		unsigned int inUse, total, user, sys, nice, idle;
        
		user = processorInfo_new[i].cpu_ticks[CPU_STATE_USER] - processorInfo[i].cpu_ticks[CPU_STATE_USER];
		sys = processorInfo_new[i].cpu_ticks[CPU_STATE_SYSTEM] - processorInfo[i].cpu_ticks[CPU_STATE_SYSTEM];
		nice = processorInfo_new[i].cpu_ticks[CPU_STATE_NICE] - processorInfo[i].cpu_ticks[CPU_STATE_NICE];
		idle = processorInfo_new[i].cpu_ticks[CPU_STATE_IDLE] - processorInfo[i].cpu_ticks[CPU_STATE_IDLE];
        
		inUse = user + sys + nice;
		total = inUse + idle;
        ret += ((double)inUse/(double)total)*100.0;
        
		//NSLog(@"CPU %d: User: %.2f\n", i, (double)user / (double)total);
		//NSLog(@"CPU %d: Sys: %.2f\n", i, (double)sys / (double)total);
		//NSLog(@"CPU %d: Nice: %.2f\n", i, (double)nice / (double)total);
		//NSLog(@"CPU %d: Idle: %.2f\n", i, (double)idle / (double)total);
	}
        
    return ret;
    
}

@end
