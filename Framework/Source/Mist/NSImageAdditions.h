//
//  NSImageAdditions.h
//
//  Created by Rachel Blackman on 7/13/11.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (GrowlAdditions)

- (void) drawInRect:(NSRect)rect;

- (NSImage *) flippedImage;
- (NSImage *) imageSizedToDimension:(int)dimension;
- (NSImage *) imageSizedToDimensionScalingUp:(int)dimension;
- (NSImage *) imageSizedToDimensionSquaring:(int)dimension;


@end
