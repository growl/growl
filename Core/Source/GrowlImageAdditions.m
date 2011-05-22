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

		for (NSImageRep *thisRep in [self representations]) {
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
    //10.5 support
	if (!bestRep) {	
        if([self respondsToSelector:@selector(bestRepresentationForRect:context:hints:)]) {
            bestRep = [self bestRepresentationForRect:NSZeroRect context:nil hints:nil]; 
        }
        else {
            bestRep = (NSImageRep*)[self performSelector:@selector(bestRepresentationForDevice:) withObject:nil];
        }
    }
	return bestRep;
}

- (NSImageRep *) representationOfSize:(NSSize)theSize {
	NSImageRep *rep;
	for (rep in [self representations])
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

- (NSBitmapImageRep *)GrowlBitmapImageRep
{
	NSData *tiffData = [self TIFFRepresentation];
	NSBitmapImageRep *tiffRep = [NSBitmapImageRep imageRepWithData:tiffData];
	return tiffRep;
}

- (NSData *) PNGRepresentation
{
	return ([[self GrowlBitmapImageRep] representationUsingType:NSPNGFileType properties:nil]);
}

- (NSData *) JPEGRepresentation
{
	return ([[self GrowlBitmapImageRep] representationUsingType:NSJPEGFileType properties:nil]);
}


@end
