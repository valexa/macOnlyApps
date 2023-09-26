//
//  AppDelegate.m
//  AppsBar
//
//  Created by Vlad Alexa on 1/23/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import "AppDelegate.h"

#import "LaunchButton.h"

#import "QuartzCore/CIFilter.h"

#import <QuartzCore/CoreAnimation.h>

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    NSImage *image = [NSImage imageNamed:@"menubar"];
    [image setSize:NSMakeSize(20, 20)];
    [statusItem setImage:image];
    NSImage *image_ = [NSImage imageNamed:@"menubar_"];
    [image_ setSize:NSMakeSize(20, 20)];
    [statusItem setAlternateImage:image_];
    //[statusItem setAlternateImage:[self applyCIFilter:@"CIColorInvert" withOptions:nil toImage:image]];
    [statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(menubarClick:)];
       
    magicLauncher = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [magicLauncher setLevel:NSScreenSaverWindowLevel];
    [magicLauncher setHasShadow:NO];
    [magicLauncher setOpaque:YES];
    [magicLauncher setBackgroundColor:[NSColor blackColor]];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:MAIN_OBSERVER_NAME_STRING object:nil];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    /*
    if ([defaults boolForKey:@"shortcutEnabled"] == YES){
        if (AXIsProcessTrustedWithOptions != NULL)
        {
            CFDictionaryRef options = (CFDictionaryRef)CFBridgingRetain([NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:[NSString stringWithFormat:@"%@",kAXTrustedCheckOptionPrompt]]);
            Boolean isTrusted = AXIsProcessTrustedWithOptions(options);
            if (isTrusted == FALSE) {
                CFDictionaryRef options = (CFDictionaryRef)CFBridgingRetain([NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%@",kAXTrustedCheckOptionPrompt]]);
                AXIsProcessTrustedWithOptions(options);
            }
        } else {
            // 10.8 and older
        }
    }
     */
    
    if ([defaults objectForKey:@"gestureEnabled"] == nil) {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"gestureEnabled"];
        [defaults synchronize];
    }
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask | NSKeyDownMask handler:^(NSEvent *theEvent) {
        return [self processEvent:theEvent];
    }];
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask |  NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSKeyDownMask handler:^(NSEvent *theEvent) {
        [self processEvent:theEvent];
    }];
    
    [self setDock];

}

-(void)awakeFromNib
{
    [super awakeFromNib];
    /*
    NSView *matrixView = (NSView*)excludedPicker;
    
    NSLog(@"%@",[matrixView constraintsAffectingLayoutForOrientation:NSLayoutConstraintOrientationVertical]);
    [_window visualizeConstraints:[matrixView constraints]];
    
    if ([[matrixView constraints] count] == 3) {
        [matrixView removeConstraint:[[matrixView constraints] objectAtIndex:1]];
        [matrixView addConstraint:[NSLayoutConstraint constraintWithItem:(NSView*)appTitle attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:matrixView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [matrixView addConstraint:[NSLayoutConstraint constraintWithItem:(NSView*)twitterButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationLessThanOrEqual toItem:matrixView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    }else{
        NSLog(@"ERROR dude wheres my constraints %@",[matrixView constraints]);
    }
    */ 
}

- (void) setDock
{
    // switch to Dock.app
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.dock" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
}

-(NSEvent*)processEvent:(NSEvent *)theEvent
{
    if ([theEvent type] == NSKeyDown && [theEvent keyCode] == 11 && [theEvent modifierFlags] & NSCommandKeyMask && [theEvent modifierFlags] & NSAlternateKeyMask)
    {
        if ([defaults boolForKey:@"shortcutEnabled"] == YES)  [self showApps:self];
        return nil;
    }
    
    NSPoint mouseLoc = [NSEvent mouseLocation];
    NSRect screen = [[NSScreen mainScreen] frame];
    
    if ([theEvent type] == NSLeftMouseDown)
    {
        if (screen.size.height-mouseLoc.y < 4){
            startedDrag = YES;
        }else{
            startedDrag = NO;
        }
    }
    
    if ([theEvent type] == NSLeftMouseUp) startedDrag = NO;
    
    if ([theEvent type] == NSLeftMouseDragged && screen.size.height-mouseLoc.y > 5 && screen.size.height-mouseLoc.y < 25)
    {
        if (startedDrag == YES) {
            if ([defaults boolForKey:@"gestureEnabled"] == YES) [self showApps:self];
            startedDrag = NO;
        }
    }
    
    return theEvent;
    
}

-(void)didTerminate:(NSNotification*)notification
{
    
    NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    
    NSMutableArray *hist = [NSMutableArray arrayWithCapacity:1];
    int quitCount = 0;
    BOOL isExcluded = NO;
    
    for (NSDictionary *dict in [defaults objectForKey:@"appHistory"])
    {
        if (![[dict objectForKey:@"bid"] isEqualToString:[app bundleIdentifier]])
        {
            if ( [[dict objectForKey:@"quitCount"] intValue] > 32766)
            {
                //TODO remove eventually, temp fix for 1.1 bug
                NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:dict];
                [d setObject:[NSNumber numberWithInt:1] forKey:@"quitCount"];
                [hist addObject:d];
            }else{
                [hist addObject:dict];
            }
        }else{
            quitCount = [[dict objectForKey:@"quitCount"] intValue];
            isExcluded = [[dict objectForKey:@"excluded"] boolValue];
        }
    }
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date],@"date",[app bundleIdentifier],@"bid",[[app bundleURL] path],@"path",[app localizedName],@"name",[NSNumber numberWithInt:quitCount+1],@"quitCount",[NSNumber numberWithBool:isExcluded],@"excluded", nil];
    [hist insertObject:entry atIndex:0];
    [defaults setObject:hist forKey:@"appHistory"];
    [defaults synchronize];
    
}

-(void)theEvent:(NSNotification*)notif
{
	if ([[notif name] isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"]) {
		//NSString *activeApp = [[notif userInfo] objectForKey:@"NSApplicationPath"];
		//NSLog(@"%@",activeApp);
	}
	if (![[notif name] isEqualToString:MAIN_OBSERVER_NAME_STRING]) {
		return;
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]])
    {
		if ([[notif object] isKindOfClass:[NSString class]])
        {
			if ([[notif object] isEqualToString:@"deleteIcon"])
            {
				[self deleteIcon:[[[notif userInfo] objectForKey:@"tag"] intValue]];
			}
			if ([[notif object] isEqualToString:@"showPopover"])
            {
                if ([popOver isShown]) [popOver performClose:self];       
                [self showPopover:[[notif userInfo] objectForKey:@"tag"]];
			}
		}
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {
        if ([[notif object] isEqualToString:@"hidePopover"])
        {
            [iconPopOver performClose:self];
        }
		if ([[notif object] isEqualToString:@"beganEditing"])
        {
			[[NSNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"beganEditing"];
		}
		if ([[notif object] isEqualToString:@"endedEditing"])
        {
			[[NSNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"endedEditing"];
		}
		if ([[notif object] isEqualToString:@"dismiss"])
        {
			[self outsideClick:self];
		}
	}
}

-(void)showPopover:(NSNumber*)number
{
    int tag = [number intValue];
    NSView *button = nil;
    
    for (NSView *view in [[frontScrollView contentView] subviews])
    {
        if ([view isKindOfClass:[NSButton class]]) {
            if ([view tag] == tag) {
                button = view;
            }
        }
    }
    
    if (button) {
        NSArray *list  = [defaults objectForKey:@"appHistory"];
        NSDictionary *dict = [list objectAtIndex:tag];
        [appTitle setStringValue:[NSString stringWithFormat:@"%@ (%@ runs)",[dict objectForKey:@"name"],[dict objectForKey:@"quitCount"]]];
        [appPath setStringValue:[dict objectForKey:@"path"]];
        [appBid setStringValue:[dict objectForKey:@"bid"]];
        [iconPopOver showRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge];
    } else{
        NSLog(@"No button with tag %i",tag);
    }
}

-(void)deleteIcon:(int)tag
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:0];
    
    for (NSView *view in [[frontScrollView contentView] subviews])
    {
        if ([view isKindOfClass:[NSButton class]]) {
            [buttons addObject:view];
        }
    }
    
    for (NSView *view in buttons)
    {
        [view removeFromSuperview];
    }
    
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[defaults objectForKey:@"appHistory"]];
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[arr objectAtIndex:tag]];
    if (excluded == YES) {
        [d setObject:[NSNumber numberWithBool:NO] forKey:@"excluded"];
    }else{
        [d setObject:[NSNumber numberWithBool:YES] forKey:@"excluded"];
    }
    [arr replaceObjectAtIndex:tag withObject:d];
    [defaults setObject:arr forKey:@"appHistory"];
    [defaults synchronize];
    
    [self addButtons];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"beganEditing"];
    
}

-(void)iconPush:(id)sender
{
	[[NSWorkspace sharedWorkspace] launchApplication:[sender title]];
    NSView *contentView = [magicLauncher contentView];
    NSRect screen = [[NSScreen mainScreen] frame];
    [contentView.animator setFrame:NSMakeRect(0, 0, screen.size.width,screen.size.height+ICON_SIZE+ICON_PAD)];
    [magicLauncher performSelector:@selector(orderOut:) withObject:nil afterDelay:0.25];
    [self performSelector:@selector(setDock) withObject:nil afterDelay:0.26];
    [[NSNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"appInactive"];
    active = NO;    
}


-(void)menubarClick:(id)sender
{
    
    if ([popOver isShown])
    {
        [popOver performClose:self];
        return;
    }
    
    if ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask )
    {
        NSView *button = [[statusItem valueForKey:@"window"] contentView];
        if (button){
            [popOver showRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge];
        }else{
            NSLog(@"ERROR getting menubar button");
        }
        return;
    }
    
    [self showApps:sender];
}

-(void)outsideClick:(id)sender
{
    NSView *contentView = [magicLauncher contentView];
    NSRect screen = [[NSScreen mainScreen] frame];    
    [contentView.animator setFrame:NSMakeRect(0, 0, screen.size.width,screen.size.height+ICON_SIZE+ICON_PAD)];
    [magicLauncher performSelector:@selector(orderOut:) withObject:nil afterDelay:0.25];
    [self performSelector:@selector(setDock) withObject:nil afterDelay:0.26];
    [[NSNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"appInactive"];
    active = NO;
}

-(IBAction)showExcluded:(id)sender
{    
    if ([excludedPicker selectedRow] == 1) {
        excluded = YES;
    }else{
        excluded = NO;
    }
    
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:0];    
    
    for (NSView *view in [[frontScrollView contentView] subviews])
    {
        if ([view isKindOfClass:[NSButton class]]) {
            [buttons addObject:view];
        }
    }
    
    for (NSView *view in buttons)
    {
        [view removeFromSuperview];
    }    
    
    [self addButtons];    
    [self frontFlip:self];
}
    
-(IBAction)showApps:(id)sender
{
    excluded = NO;
    [excludedPicker selectCellAtRow:0 column:0];
    [excludedPicker setTag:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"appActive"];
    
    if (active == YES) {
        [self outsideClick:self];
        return;
    }else{
        active = YES;
    }
    
    NSRect screen = [[NSScreen mainScreen] frame];
    [magicLauncher setFrame:NSMakeRect(0, 0, screen.size.width, screen.size.height) display:YES];
    
    NSView *rootView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, screen.size.width ,screen.size.height+ICON_SIZE+ICON_PAD)];
    [rootView setWantsLayer:YES];
    [magicLauncher setContentView:rootView];
    
    //add bar
    
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    backRootView = [[NSView alloc] initWithFrame:NSMakeRect(0, screen.size.height-MENUBAR_HEIGHT, screen.size.width , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    frontRootView = [[NSView alloc] initWithFrame:NSMakeRect(0, screen.size.height-MENUBAR_HEIGHT, screen.size.width , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];

    //add back bar
    backScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, screen.size.width , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    [backScrollView setScrollerKnobStyle:NSScrollerKnobStyleLight];
    [backScrollView setBackgroundColor:[NSColor colorWithCalibratedRed:0.164 green:0.164 blue:0.164 alpha:1]];
    [backScrollView setDocumentView:backView];
    [backView setFrame:NSMakeRect(0, 0, screen.size.width+718-340 , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    [centerButtons setFrame:NSMakeRect(screen.size.width/2-186, 0, 372 , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    [toggleButtons setFrame:NSMakeRect(screen.size.width-340, 0, 718 , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    [excludedPicker setFrame:NSMakeRect(screen.size.width/4-64, 32, 164 , 38)];
    [backScrollView setHasHorizontalScroller:YES];
    [backRootView addSubview:backScrollView];
    
    [rootView addSubview:backRootView];
    [backRootView setHidden:YES];
    
    //add blurred menubar
    NSImage *croppedImage = [self cropImage:[self desktopAsImage]
                                   fromRect:NSMakeRect(0, screen.size.height-MENUBAR_HEIGHT, screen.size.width , MENUBAR_HEIGHT)
                                     toRect:NSMakeRect(0, 0, screen.size.width ,MENUBAR_HEIGHT)
                                       size:NSMakeSize(screen.size.width, ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    
    NSImageView *backgroundView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, screen.size.width , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    [backgroundView setImage:croppedImage];

    [backgroundView setWantsLayer:YES];
    [backgroundView setLayerUsesCoreImageFilters:YES];
    CALayer *backgroundLayer = [CALayer layer];
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:[NSNumber numberWithFloat:2.2] forKey:@"inputRadius"];
    backgroundLayer.backgroundFilters = [NSArray arrayWithObject:blurFilter];
    [[backgroundView layer] addSublayer:backgroundLayer];

    [frontRootView addSubview:backgroundView];

    //add front bar    
    frontScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, MENUBAR_HEIGHT, screen.size.width , ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    [frontScrollView setDrawsBackground:NO];
    [frontScrollView setHasHorizontalScroller:YES];
    
    NSInteger count = [self addButtons];
    
    [frontRootView addSubview:frontScrollView];
    
    [rootView addSubview:frontRootView];
    
    //add welcome
    
    if (count == 0) {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, screen.size.width , ICON_SIZE+ICON_PAD)];
        NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:ICON_SIZE/4];
        NSString *string = @"Icons for applications you quit will start to appear here in the order they were closed.";
        NSSize textSize = [string sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]];
        NSTextField *text = [[NSTextField alloc] initWithFrame:NSMakeRect(0, (ICON_SIZE+ICON_PAD)/2-textSize.height/2.2, screen.size.width , textSize.height)];
        [text setAlignment:NSCenterTextAlignment];
        [text setBordered:NO];
        [text setDrawsBackground:NO];
        [text setTextColor:[NSColor lightGrayColor]];
        [text setSelectable:NO];
        [text setFont:font];
        [text setStringValue:string];
        [imageView addSubview:text];
        [imageView setImage:[self cutoutImage:textSize]];
        [imageView setImageAlignment:NSImageAlignCenter];
        [[frontScrollView contentView] addSubview:imageView];
    }
    
    NSLog(@"Loaded %li apps in %f sec",count,CFAbsoluteTimeGetCurrent()-startTime);
    
    //add desktop
    
    NSImage *desktopImage = [self cropImage:[self desktopAsImage] fromRect:NSMakeRect(0, 0, screen.size.width ,screen.size.height-MENUBAR_HEIGHT) toRect:NSMakeRect(0, 0, screen.size.width ,screen.size.height-MENUBAR_HEIGHT) size:NSMakeSize(screen.size.width, screen.size.height-MENUBAR_HEIGHT)];
    /*
    if ([self hasTheSunSet]){
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.3],@"inputIntensity", nil];
        desktopImage = [self applyCIFilter:@"CISepiaTone" withOptions:options toImage:desktopImage];
    }
    */
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"d MMM"];
    if ([[dateFormatter stringFromDate:[NSDate date]] isEqualToString:@"5 Oct"]) {
        desktopImage = [self applyCIFilter:@"CIPhotoEffectMono" withOptions:nil toImage:desktopImage];
    }
    
    NSButton *desktop = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, screen.size.width ,screen.size.height-MENUBAR_HEIGHT)];
    [desktop setImage:desktopImage];
    [desktop setBordered:NO];
    [desktop setTarget:self];
    [desktop setAction:@selector(outsideClick:)];
    [desktop setImagePosition:NSImageOnly];
    [desktop.cell setShowsStateBy:NSNoCellMask];
    [desktop.cell setHighlightsBy:NSNoCellMask];
    
    [rootView addSubview:desktop];
    
    if ([desktopImage isValid]) {
        [magicLauncher makeKeyAndOrderFront:nil];
        [rootView.animator setFrame:NSMakeRect(0, 0-ICON_SIZE-ICON_PAD, screen.size.width,screen.size.height+ICON_SIZE+ICON_PAD)];
    }else{
        [[NSAlert alertWithMessageText:@"Error getting desktop." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please contact me at vladalexa.com"] runModal];
    }

}

-(NSInteger)addButtons
{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *launched = [NSMutableArray arrayWithCapacity:1];
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
    {
        if ([app bundleIdentifier])[launched addObject:[app bundleIdentifier]];
	}
    
    int visibleCount = 0;
    int excludedCount = 0;
    
    NSArray *list  = [defaults objectForKey:@"appHistory"];
    for (NSDictionary *dict in list)
    {
        if (![launched containsObject:[dict objectForKey:@"bid"]] && [[NSFileManager defaultManager] fileExistsAtPath:[dict objectForKey:@"path"]]) {
            if ([[dict objectForKey:@"excluded"] boolValue] == YES)
            {
                excludedCount++;
                if (excluded == YES) [arr addObject:dict];
            }
            else if ([[dict objectForKey:@"excluded"] boolValue] == NO)
            {
                visibleCount++;
                if (excluded == NO) [arr addObject:dict];
            }
        }
    }
    
    //if all exclusions were removed
    if (excluded == YES && excludedCount == 0)
    {
        excluded = NO;
        return [self addButtons];
    }
    
    [self updateMatrix:visibleCount excluded:excludedCount];
    
    //set documentview
    NSRect screen = [[NSScreen mainScreen] frame];
    NSInteger scrollWidth = ([arr count] + 2) * ICON_SIZE; //icons could be further removed when checking isGoodIcon
    if (screen.size.width > scrollWidth) scrollWidth = screen.size.width;
    NSView *documentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, scrollWidth ,ICON_SIZE+ICON_PAD+MENUBAR_HEIGHT)];
    [frontScrollView setDocumentView:documentView];
    
    
    //NSShadow *shadow = [[NSShadow alloc] init];
    //[shadow setShadowBlurRadius:6.0];
    //[shadow setShadowOffset:NSMakeSize(2, 2)];
    //[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.7]];
    
    int count = 0;
    for (NSDictionary *dict in arr)
    {
        LaunchButton *button = [[LaunchButton alloc] initWithFrame:NSMakeRect(count*ICON_SIZE,ICON_PAD/2,ICON_SIZE,ICON_SIZE)];
        NSImage *ico = [[NSWorkspace sharedWorkspace] iconForFile:[dict objectForKey:@"path"]];
        if (![self isGoodIcon:ico]) continue;
        [ico setSize:NSMakeSize(48, 48)];
        [button setTag:[list indexOfObject:dict]];
        [button setImage:ico];
        if (excluded == YES ) [button setImage:[self applyCIFilter:@"CIPhotoEffectNoir" withOptions:nil toImage:ico]];
        [button setBordered:NO];
        //[button setShadow:shadow];
        //[button setWantsLayer:YES]; //laggy
        [button setTarget:self];
        [button setAction:@selector(iconPush:)];
        [button setTitle:[dict objectForKey:@"path"]];
        //[button setToolTip:[[dict objectForKey:@"name"] substringWithRange:NSMakeRange(0,[[dict objectForKey:@"name"] length]-4)]];
        [button setImagePosition: NSImageOnly];
        [button setButtonType:NSMomentaryChangeButton];
        //factor usage
        NSInteger use = [[dict objectForKey:@"quitCount"] intValue];
        if (use < 5)[button setAlphaValue:0.55];
        if (use >= 5)[button setAlphaValue:0.75];
        if (use >= 10)[button setAlphaValue:1.0];
        [[frontScrollView contentView] addSubview:button];
        count++;
    }
    
    [self addFlipButton:count];
    
    return count;
}

-(void)addFlipButton:(int)count
{
    NSString *flipImage = @"backflip";
    if (count == 0) flipImage = @"backflip_empty";
    float scrollWidth = [(NSView *)[frontScrollView documentView] frame].size.width;
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(scrollWidth-ICON_SIZE,ICON_PAD/2,ICON_SIZE,ICON_SIZE)];
    [button setImage:[NSImage imageNamed:flipImage]];
    [button setBordered:NO];
    [button setTarget:self];
    [button setAction:@selector(backFlip:)];
    [button setImagePosition: NSImageOnly];
    [button setButtonType:NSMomentaryChangeButton];
    [[frontScrollView contentView] addSubview:button];
}

-(void)updateMatrix:(int)visibleCount excluded:(int)excludedCount
{
    if (excludedCount > 0) {
        [excludedPicker setHidden:NO];
        if ([defaults boolForKey:@"hasExcluded"] != YES){
            [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"hasExcluded"];
            [defaults synchronize];
        }
    }else{
        [excludedPicker setHidden:YES];
        if ([defaults boolForKey:@"hasExcluded"] != NO){
            [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"hasExcluded"];
            [defaults synchronize];
        }
    }
    
    NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    [attrsDictionary setObject:[NSColor lightGrayColor] forKey:NSForegroundColorAttributeName];
    
    NSButtonCell *v = [excludedPicker cellWithTag:0];
    NSAttributedString *visibleStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i visible applications",visibleCount] attributes:attrsDictionary];
    [v setAttributedTitle:visibleStr];
    
    NSButtonCell *e = [excludedPicker cellWithTag:1];
    NSAttributedString *excludedStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i excluded applications",excludedCount] attributes:attrsDictionary];
    [e setAttributedTitle:excludedStr];    
}

#pragma mark flip

- (CGImageRef) getCachedImage:(NSImage *) img
{
    NSGraphicsContext *context = [[NSGraphicsContext currentContext] graphicsPort];
    NSRect rect = NSMakeRect(0, 0, [img size].width, [img size].height);
    return [img CGImageForProposedRect:&rect context:context hints:NULL];
}

-(NSImage*)imageFromView:(NSView *)view
{
    BOOL hidden = [view isHidden];
    [view setHidden:NO];
    NSBitmapImageRep *bir = [view bitmapImageRepForCachingDisplayInRect:[view bounds]];
    [bir setSize:view.bounds.size];
    [view cacheDisplayInRect:[view bounds] toBitmapImageRep:bir];
    [view setHidden:hidden];
    NSImage* image = [[NSImage alloc] initWithSize:view.bounds.size];
    [image addRepresentation:bir];
    
    return image;
}

-(IBAction)backFlip:(id)sender
{
    if ([popOver isShown]) [popOver performClose:self];     
    [self flipAnimation:1];
}

-(IBAction)frontFlip:(id)sender
{
    [self flipAnimation:-1];
}

-(void)flipAnimation:(int)dir
{
	NSView *cubeView = [[NSView alloc] initWithFrame:NSMakeRect(frontRootView.frame.origin.x, frontRootView.frame.origin.y, frontRootView.frame.size.width, frontRootView.frame.size.height)];
    [[frontRootView superview] addSubview:cubeView positioned:NSWindowAbove relativeTo:frontRootView];
    
    [frontRootView setHidden:YES];
    [backRootView setHidden:YES];
    
    NSImage *front;
    NSImage *back;
    
    if (dir == -1) {
        [frontRootView setHidden:NO];
        back = [self imageFromView:frontRootView];
        front = [self imageFromView:backRootView];
    }else{
        [backRootView setHidden:NO];
        front = [self imageFromView:frontRootView];
        back = [self imageFromView:backRootView];
    }
    
    CATransformLayer *transformLayer = [CATransformLayer layer];
    transformLayer.position = CGPointMake(cubeView.bounds.size.width / 2,cubeView.bounds.size.height / 2);
    
    float halfHeight = cubeView.bounds.size.height/2.0; //size for sides
    float halfWidth = cubeView.bounds.size.width/2.0; //size for sides
    CGRect layerRect = CGRectMake(0.0, 0.0, halfWidth*2.0, halfHeight*2.0); //frame rect for cube sides
    CGPoint screenCenter = CGPointMake(transformLayer.bounds.size.width / 2, transformLayer.bounds.size.height / 2);
    
    //side1
    CALayer *side1 = [CALayer layer];
    side1.frame = layerRect;
    side1.position = screenCenter;
    side1.contents = (id)[self getCachedImage:front];
    [transformLayer addSublayer:side1];
    
    //side2
    CALayer *side2 = [CALayer layer];
    side2.frame = layerRect;
    side2.position = screenCenter;
    side2.contents = (id)[self getCachedImage:back];
    //positioning
    CATransform3D rotation = CATransform3DMakeRotation(DEGREES_TO_RADIANS(dir*-90), 1.0, 0.0, 0.0);
    CATransform3D translation = CATransform3DMakeTranslation(0.0, dir*halfHeight, -halfHeight );
    CATransform3D position = CATransform3DConcat(rotation, translation);
    side2.transform = position;
    [transformLayer addSublayer:side2];
    
    transformLayer.anchorPointZ = -halfHeight;
    [cubeView setWantsLayer:YES];
    [cubeView.layer addSublayer:transformLayer];
    
    //completion
    
	[CATransaction setCompletionBlock:^(void) {
        [transformLayer removeFromSuperlayer];
        [cubeView removeFromSuperview];
	}];
    
    //animate
    
	CGFloat perspective = -1.0/100000.0;
	CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	
    CATransform3D transform = CATransform3DIdentity;
	transform.m34 = perspective;
	transformAnimation.fromValue = [NSValue valueWithCATransform3D:transform];
	
	transform.m34 = perspective;
    transform = CATransform3DRotate(transform, DEGREES_TO_RADIANS(dir*90) , 1, 0, 0);
	transformAnimation.toValue = [NSValue valueWithCATransform3D:transform];
    
    transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    transformAnimation.duration = 0.7;
    [transformLayer addAnimation:transformAnimation forKey:@"Rotate"];
    
}

#pragma mark desktop

-(NSImage*)applyCIFilter:(NSString*)name withOptions:(NSDictionary*)options toImage:(NSImage*)source
{
    //CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    NSImage *ret = nil;
    CIImage *image = [CIImage imageWithData:[source TIFFRepresentation]];
    
    //apply the filter
    CIFilter *filter = [CIFilter filterWithName:name];
    [filter setValue:image forKey:@"inputImage"];
    for (NSString *key in options) {
        [filter setValue:[options objectForKey:key] forKey:key];
    }
    image = [filter valueForKey:@"outputImage"];
    
    //make the output
    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:image];
    ret = [[NSImage alloc] initWithSize:[imageRep size]];
    [ret setSize:[source size]];
    [ret addRepresentation:imageRep];
    
    //NSLog(@"Applied %@ filter in %f sec",name,CFAbsoluteTimeGetCurrent()-startTime);
    
    return ret;
}

- (NSImage*) desktopAsImage
{
    // Can not use old "NSWorspace desktopImageURLForScreen + NSImage initWithContents" trick
    // because app is sandboxed and has no access to FS. WD-rpw 04-21-2012
    
    //NSURL* desktopImageFile = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen: [NSScreen mainScreen]];
    //return [[NSImage alloc] initWithContentsOfURL: desktopImageFile];
    
    //CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    CFMutableArrayRef windowIDs = CFArrayCreateMutable(NULL, 0, NULL);
    
    CGImageRef cgImage = CGWindowListCreateImageFromArray( [NSScreen mainScreen].frame, windowIDs, kCGWindowImageDefault);
    CFRelease(windowIDs);
    
    // Create a bitmap rep from the image...
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    CFRelease(cgImage);
    
    // Create an NSImage and add the bitmap rep to it...
    NSImage *ret = [[NSImage alloc] init];
    [ret addRepresentation:bitmapRep];
    [ret setSize:NSMakeSize([NSScreen mainScreen].frame.size.width, [NSScreen mainScreen].frame.size.height)];    
    
    //NSLog(@"Got desktop in %f sec",CFAbsoluteTimeGetCurrent()-startTime);
    return ret;
    
}

-(NSImage*) cutoutImage:(NSSize)size
{    
    NSImage *ret = [[NSImage alloc] initWithSize:NSMakeSize(size.width+ICON_SIZE*2, ICON_SIZE+ICON_PAD)];
    
    [ret lockFocus];
    
    [[NSColor clearColor] set];
    
    //base rectangle
    NSBezierPath *baseShape = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(ICON_PAD/2,ret.size.height/4, ret.size.width-ICON_PAD, ret.size.height/2) xRadius:16.0 yRadius:16.0];
    baseShape.lineWidth = 4.0;
    [[NSColor colorWithCalibratedWhite:0.8 alpha:0.7] setStroke];
    const CGFloat p[2] = {14, 14};
    [baseShape setLineDash:p count:2 phase:2];
    [baseShape stroke];
    
    [ret unlockFocus];
    
    return  ret;
    
}

- (NSImage*) cropImage:(NSImage *)image fromRect:(NSRect)fromRect toRect:(NSRect)toRect size:(NSSize)size
{
    NSImage *ret = [[NSImage alloc] initWithSize:size];
    
    [ret lockFocus];

    [[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
    [NSBezierPath fillRect:NSMakeRect(0, 0, size.width, size.height)];
   
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    [image drawInRect:toRect fromRect:fromRect operation:NSCompositeCopy fraction:1];
    
    [ret unlockFocus];
    
    return ret;
}

#pragma mark tools

-(BOOL)appWasLaunched:(NSString*)path
{
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]){
		if ([path isEqualToString:[[app bundleURL] path]]) {
			return TRUE;
		}
	}
	return FALSE;
}

-(BOOL)isGoodIcon:(NSImage*)image
{
    NSArray *reps = [image representations];
    if (![image isValid]) return NO;
    if ([reps count] < 1) return NO;
    
	return YES;
}

-(BOOL)hasTheSunSet
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSHourCalendarUnit fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    if (hour > 18 || hour < 8)  {
        return YES;
    }
    
    return NO;
}

@end
