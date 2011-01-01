//
//  NSViewAdditions.h
//  Growl
//
//  Created by Peter Hosey on 2005-06-26
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSView (GrowlAdditions)

- (NSData *) dataWithPNGInsideRect:(NSRect)rect;
- (NSData *) dataWithTIFFInsideRect:(NSRect)rect;

@end
