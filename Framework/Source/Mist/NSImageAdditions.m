//
//  NSImageAdditions.m
//
//  Created by Rachel Blackman on 7/13/11.
//

#import "NSImageAdditions.h"


@implementation NSImage (GrowlAdditions)

- (NSImage *) flippedImage
{
    NSImage *l_result = [[NSImage alloc] initWithSize:[self size]];
    [l_result lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    NSRect l_target = NSZeroRect;
    l_target.size = [self size];
	
    NSAffineTransform* xform = [NSAffineTransform transform];
    [xform translateXBy:0.0 yBy:l_target.size.height];
    [xform scaleXBy:1.0 yBy:-1.0];
    [xform concat];    
    
    [self drawInRect:l_target fromRect:l_target operation:NSCompositeCopy fraction:1.0f];
    [l_result unlockFocus];
    
    return [l_result autorelease];
}

- (NSImage *) imageSizedToDimension:(int)dimension
{
	NSSize imageSize = [self size];
	
	if ((imageSize.width <= dimension) && (imageSize.height <= dimension))
		return self;
	
	return [self imageSizedToDimensionScalingUp:dimension];
}

- (NSImage *) imageSizedToDimensionScalingUp:(int)dimension
{
	NSSize imageSize = [self size];
	float ratio = 1;
	
	if (imageSize.width > imageSize.height) {
		ratio = imageSize.height / imageSize.width;
		imageSize.width = dimension;
		imageSize.height = dimension * ratio;
	}
	else {
		ratio = imageSize.width / imageSize.height;
		imageSize.height = dimension;
		imageSize.width = dimension * ratio;				
	}
	
	NSImage *result = [[[NSImage alloc] initWithSize:imageSize] autorelease];
	[result lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	NSRect destRect = NSZeroRect;
	destRect.size = imageSize;
	NSRect sourceRect = NSZeroRect;
	sourceRect.size = [self size];
	
	[self drawInRect:destRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0f];
	
	[result unlockFocus];
	
	return result;
}

- (NSImage *) imageSizedToDimensionSquaring:(int)dimension
{
	NSSize imageSize = [self size];
	float ratio = 1;
	
	if (imageSize.width > imageSize.height) {
		ratio = imageSize.height / imageSize.width;
		imageSize.width = dimension;
		imageSize.height = dimension * ratio;
	}
	else {
		ratio = imageSize.width / imageSize.height;
		imageSize.height = dimension;
		imageSize.width = dimension * ratio;				
	}
	
	NSSize finalSize = NSMakeSize(dimension, dimension);
	
	NSImage *result = [[[NSImage alloc] initWithSize:finalSize] autorelease];
	[result lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	NSRect destRect = NSZeroRect;
	destRect.size = imageSize;
	
	destRect.origin.y = truncf((dimension - destRect.size.height) / 2);
	destRect.origin.x = truncf((dimension - destRect.size.width) / 2);
	
	NSRect sourceRect = NSZeroRect;
	sourceRect.size = [self size];
	
	[self drawInRect:destRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0f];
	
	[result unlockFocus];
	
	return result;
}

- (void) drawInRect:(NSRect)rect
{
	NSRect sourceRect = NSZeroRect;
	sourceRect.size = [self size];
	[self drawInRect:rect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0f];
}

@end
