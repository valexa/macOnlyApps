//
//  SplitImage.m
//  OSXCommander
//
//  Created by Vlad Alexa on 11/11/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "SplitImage.h"


@implementation SplitImage

static NSImage *topLeftCornerImage;
static NSImage *topEdgeImage;
static NSImage *topRightCornerImage;
static NSImage *leftEdgeImage;
static NSImage *centerImage;
static NSImage *rightEdgeImage;
static NSImage *bottomLeftCornerImage;
static NSImage *bottomEdgeImage;
static NSImage *bottomRightCornerImage;

- (void)awakeFromNib {
	baseImage = nil;
	[self initialize];	
}

- (id)initialize{	
	if (baseImage == nil) {
		
		NSRect tileRect = NSMakeRect(0,0,8,8);
		
		baseImage = [NSImage imageNamed:@"pane"];
		
		topLeftCornerImage = [[NSImage alloc] initWithSize:tileRect.size];
		[topLeftCornerImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(0,16,8,8) operation:NSCompositeCopy fraction:1];
		[topLeftCornerImage unlockFocus];
		
		topEdgeImage = [[NSImage alloc] initWithSize:tileRect.size];
		[topEdgeImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(8,16,8,8) operation:NSCompositeCopy fraction:1];
		[topEdgeImage unlockFocus];
		
		topRightCornerImage = [[NSImage alloc] initWithSize:tileRect.size];
		[topRightCornerImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(16,16,8,8) operation:NSCompositeCopy fraction:1];
		[topRightCornerImage unlockFocus];
		
		leftEdgeImage = [[NSImage alloc] initWithSize:tileRect.size];
		[leftEdgeImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(0,8,8,8)	operation:NSCompositeCopy fraction:1];
		[leftEdgeImage unlockFocus];
		
		centerImage = [[NSImage alloc] initWithSize:tileRect.size];
		[centerImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(8,8,8,8)	operation:NSCompositeCopy fraction:1];
		[centerImage unlockFocus];
		
		rightEdgeImage = [[NSImage alloc] initWithSize:tileRect.size];
		[rightEdgeImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(16,8,8,8) operation:NSCompositeCopy fraction:1];
		[rightEdgeImage unlockFocus];
		
		bottomLeftCornerImage = [[NSImage alloc] initWithSize:tileRect.size];
		[bottomLeftCornerImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(0,0,8,8) operation:NSCompositeCopy fraction:1];
		[bottomLeftCornerImage unlockFocus];
		
		bottomEdgeImage = [[NSImage alloc] initWithSize:tileRect.size];
		[bottomEdgeImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(8,0,8,8)	operation:NSCompositeCopy fraction:1];
		[bottomEdgeImage unlockFocus];
		
		bottomRightCornerImage = [[NSImage alloc] initWithSize:tileRect.size];
		[bottomRightCornerImage lockFocus];
		[baseImage drawInRect:tileRect fromRect:NSMakeRect(16,0,8,8) operation:NSCompositeCopy fraction:1];
		[bottomRightCornerImage unlockFocus];
		
	}	
	return self;
}

- (void)drawRect:(NSRect)rect;
{	
	NSDrawNinePartImage([self bounds],
						topLeftCornerImage, topEdgeImage, topRightCornerImage,
						leftEdgeImage, centerImage, rightEdgeImage,
						bottomLeftCornerImage, bottomEdgeImage, bottomRightCornerImage,
						NSCompositeSourceOver, 1, NO);
}

@end
