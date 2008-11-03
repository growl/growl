//
//  GrowlImageAdditions.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 20/09/04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSImage (GrowlImageAdditions)

- (void) drawScaledInRect:(NSRect)targetRect operation:(NSCompositingOperation)operation fraction:(float)f;
- (NSSize) adjustSizeToDrawAtSize:(NSSize)theSize;
- (NSImageRep *) bestRepresentationForSize:(NSSize)theSize;
- (NSImageRep *) representationOfSize:(NSSize)theSize;
- (NSData *) PNGRepresentation;
@end
