//
//  GrowlImageAdditions.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 20/09/04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlImageAdditions.h"

@implementation NSImage (GrowlImageAdditions)

- (void) drawScaledInRect:(NSRect)targetRect operation:(NSCompositingOperation)operation fraction:(CGFloat)f {
	if (!NSEqualSizes([self size], targetRect.size))
		[self adjustSizeToDrawAtSize:targetRect.size];
	NSRect imageRect;
	imageRect.origin.x = 0.0;
	imageRect.origin.y = 0.0;
	imageRect.size = [self size];
	if (imageRect.size.width > targetRect.size.width || imageRect.size.height > targetRect.size.height) {
		// make sure the icon isn't too large. If it is, scale it down
		if (imageRect.size.width > imageRect.size.height) {
			CGFloat oldHeight = targetRect.size.height;
			targetRect.size.height = oldHeight / imageRect.size.width * imageRect.size.height;
			targetRect.origin.y = GrowlCGFloatFloor(targetRect.origin.y - (targetRect.size.height - oldHeight) * 0.5);
		} else if (imageRect.size.width < imageRect.size.height) {
			CGFloat oldWidth = targetRect.size.width;
			targetRect.size.width = oldWidth / imageRect.size.height * imageRect.size.width;
			targetRect.origin.x = GrowlCGFloatFloor(targetRect.origin.x - (targetRect.size.width - oldWidth) * 0.5);
		}

		[self setScalesWhenResized:YES];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	} else {
		// center image if it is too small
		if (imageRect.size.width < targetRect.size.width)
			targetRect.origin.x += GrowlCGFloatCeiling((targetRect.size.width - imageRect.size.width) * 0.5);
	 	if (imageRect.size.height < targetRect.size.height)
			targetRect.origin.y += GrowlCGFloatCeiling((targetRect.size.height - imageRect.size.height) * 0.5);
		targetRect.size = imageRect.size;
	}

	[self drawInRect:targetRect fromRect:imageRect operation:operation fraction:f];
}

- (NSSize) adjustSizeToDrawAtSize:(NSSize)theSize {
	NSImageRep *bestRep = [self bestRepresentationForSize:theSize];
	NSSize size = [bestRep size];
	[self setSize:size];
	return size;
}

- (NSImageRep *) bestRepresentationForSize:(NSSize)theSize {
	NSImageRep *bestRep = [self representationOfSize:theSize];
	if (!bestRep) {
		BOOL isFirst = YES;
		CGFloat repDistance = 0.0;
		NSImageRep *thisRep;
		NSEnumerator *enumerator = [[self representations] objectEnumerator];
		while ((thisRep = [enumerator nextObject])) {
			CGFloat thisDistance = theSize.width - [thisRep size].width;
			if (repDistance < 0.0 && thisDistance > 0.0)
				continue;
			if (isFirst || GrowlCGFloatAbsoluteValue(thisDistance) < GrowlCGFloatAbsoluteValue(repDistance) || (thisDistance < 0.0 && repDistance > 0.0)) {
				isFirst = NO;
				repDistance = thisDistance;
				bestRep = thisRep;
			}
		}
	}
	if (!bestRep)
		bestRep = [self bestRepresentationForDevice:nil];

	return bestRep;
}

- (NSImageRep *) representationOfSize:(NSSize)theSize {
	NSEnumerator *enumerator = [[self representations] objectEnumerator];
	NSImageRep *rep;
	while ((rep = [enumerator nextObject]))
		if (NSEqualSizes([rep size], theSize))
			break;
	return rep;
}

// Send NSImages as copies via DO
- (id) replacementObjectForPortCoder:(NSPortCoder *)encoder {
	if ([encoder isBycopy])
		return self;
	else
		return [super replacementObjectForPortCoder:encoder];
}

- (NSBitmapImageRep *)GrowlBitmapImageRepForPNG
{
	//Find the biggest image
	NSEnumerator *repsEnum = [[self representations] objectEnumerator];
	NSBitmapImageRep *bestRep = nil;
	NSImageRep *rep;
	Class NSBitmapImageRepClass = [NSBitmapImageRep class];
	float maxWidth = 0;
	while ((rep = [repsEnum nextObject])) {
		if ([rep isKindOfClass:NSBitmapImageRepClass]) {
			//We can't convert a 1-bit image to PNG format (libpng throws an error), so ignore any 1-bit image reps, regardless of size.
			if ([rep bitsPerSample] > 1) {
				float width = [rep size].width;
				if (width >= maxWidth) {
					//Cast explanation: GCC warns about us returning an NSImageRep here, presumably because it could be some other kind of NSImageRep if we don't check the class. Fortunately, we have such a check. This cast silences the warning.
					bestRep = (NSBitmapImageRep *)rep;
					
					maxWidth = width;
				}
			}
		}
	}
	
	return bestRep;
}

- (NSData *) PNGRepresentation
{
	return ([(NSBitmapImageRep *)[self GrowlBitmapImageRepForPNG] representationUsingType:NSPNGFileType properties:nil]);
}

@end
