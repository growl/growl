//
//  GrowlImageAdditions.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 20/09/04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlImageAdditions.h"

@implementation NSImage (GrowlImageAdditions)

- (void) drawScaledInRect:(NSRect)targetRect operation:(NSCompositingOperation)operation fraction:(float)f {
	NSRect imageRect;
	imageRect.origin.x = 0.0f;
	imageRect.origin.y = 0.0f;
	imageRect.size = [self size];
	NSLog(@"iconSize=%@ rectSize=%@", NSStringFromSize(imageRect.size), NSStringFromSize(targetRect.size));
	// make sure the icon isn't too large. If it is, scale it down
	if (imageRect.size.width > targetRect.size.width || imageRect.size.height > targetRect.size.height) {
		// scale the image appropriately
		if (imageRect.size.width > imageRect.size.height) {
			float oldHeight = targetRect.size.height;
			targetRect.size.height = oldHeight / imageRect.size.width * imageRect.size.height;
			targetRect.origin.y = floorf(targetRect.origin.y - (targetRect.size.height - oldHeight) * 0.5f);
		} else if (imageRect.size.width < imageRect.size.height) {
			float oldWidth = targetRect.size.width;
			targetRect.size.width = oldWidth / imageRect.size.height * imageRect.size.width;
			targetRect.origin.x = floorf(targetRect.origin.x - (targetRect.size.width - oldWidth) * 0.5f);
		}

		[self setScalesWhenResized:YES];
	} else {
		// center image if it is too small
		if (imageRect.size.width < targetRect.size.width) {
			targetRect.origin.x += ceilf((targetRect.size.width - imageRect.size.width) * 0.5f);
		}
		if (imageRect.size.height < targetRect.size.height) {
			targetRect.origin.y += ceilf((targetRect.size.height - imageRect.size.height) * 0.5f);
		}
		targetRect.size = imageRect.size;
	}

	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[self drawInRect:targetRect fromRect:imageRect operation:operation fraction:f];
}

@end
