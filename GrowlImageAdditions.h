//
//  GrowlImageAdditions.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 20/09/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (GrowlImageAdditions)

- (void)drawScaledInRect:(NSRect)targetRect operation:(NSCompositingOperation)operation fraction:(float)fraction;
- (NSSize)adjustSizeToDrawAtSize:(NSSize)theSize;
- (NSImageRep *)bestRepresentationForSize:(NSSize)theSize;
- (NSImageRep *)representationOfSize:(NSSize)theSize;

@end
