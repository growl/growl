//
//  GrowlImageAdditions.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 20/09/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlImageAdditions.h"

@implementation NSImage (GrowlImageAdditions)

- (void)drawScaledInRect:(NSRect)targetRect operation:(NSCompositingOperation)operation fraction:(float)f
{
	NSRect drawRect;
	NSRect imageSize;
	imageSize.size = [self size];
	// make sure the icon isn't too large. If it is, scale it down
	if( imageSize.size.width > targetRect.size.width || imageSize.size.height > targetRect.size.height ) {
		// scale the image appropriately
		if( imageSize.size.width > imageSize.size.height ) {
			drawRect.size.width = targetRect.size.width;
			drawRect.size.height = targetRect.size.height / imageSize.size.width * imageSize.size.height;
		} else if( imageSize.size.width < imageSize.size.height ) {
			drawRect.size.width = targetRect.size.width / imageSize.size.height * imageSize.size.width;
			drawRect.size.height = targetRect.size.height;
		} else {
			drawRect.size.width = targetRect.size.width;
			drawRect.size.height = targetRect.size.height;
		}
		
		drawRect.origin.x = floorf(targetRect.origin.x + (targetRect.size.width - drawRect.size.width) * 0.5f);
		drawRect.origin.y = floorf(targetRect.origin.y + (targetRect.size.height - drawRect.size.height) * 0.5f);

		[self setScalesWhenResized:TRUE];
	} else {
		drawRect.origin.x = targetRect.origin.x;
		drawRect.origin.y = targetRect.origin.y;
		drawRect.size.width = imageSize.size.width;
		drawRect.size.height = imageSize.size.height;
	}

	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[self drawInRect:drawRect fromRect:imageSize operation:operation fraction:f];
}

- (NSSize)adjustSizeToDrawAtSize:(NSSize)theSize {
    NSImageRep *bestRep=[self bestRepresentationForSize:theSize];
    [self setSize:[bestRep size]];
    return [bestRep size];
}

- (NSImageRep *)bestRepresentationForSize:(NSSize)theSize {
	NSImageRep *bestRep = nil;
    if (!( bestRep = [self representationOfSize:theSize]) ) {
		NSArray *reps = [self representations];
		// ***warning   * handle other sizes
		float repDistance = 65536.0;
		// ***warning   * this is totally not the highest, but hey...
		NSImageRep *thisRep;
		float thisDistance;
		int i;
		for ( i=0; i < (int)[reps count]; i++ ) {
			thisRep=[reps objectAtIndex:i];
			thisDistance=theSize.width-[thisRep size].width;  if (repDistance<0 && thisDistance>0) continue;
			if (ABS(thisDistance)<ABS(repDistance)|| (thisDistance<0 && repDistance>0)){
				repDistance=thisDistance;
				bestRep=thisRep;
			}
		}
	}
	if (!bestRep) {
		bestRep=[self bestRepresentationForDevice:nil];
	}

    return bestRep;
}
- (NSImageRep *)representationOfSize:(NSSize)theSize {
    NSArray *reps=[self representations];
    int i;
    for (i=0;i<(int)[reps count];i++) {
        if (NSEqualSizes([[reps objectAtIndex:i]size],theSize)) {
            return [reps objectAtIndex:i];
		}
	}
    return nil;
}

@end