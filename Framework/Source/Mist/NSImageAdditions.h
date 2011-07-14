//
//  NSImageAdditions.h
//  SmokeLite
//
//  Created by Rachel Blackman on 7/13/11.
//  Copyright 2011 Shutteresque Photography. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (GrowlAdditions)

- (void) drawInRect:(NSRect)rect;

- (NSImage *) flippedImage;
- (NSImage *) imageSizedToDimension:(int)dimension;
- (NSImage *) imageSizedToDimensionScalingUp:(int)dimension;
- (NSImage *) imageSizedToDimensionSquaring:(int)dimension;


@end
