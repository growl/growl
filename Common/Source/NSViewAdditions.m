//
//  NSViewAdditions.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-26
//  Copyright 2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSViewAdditions.h"
#import "NSMutableDictionaryAdditions.h"

@implementation NSView (GrowlAdditions)

- (NSData *) dataWithPNGInsideRect:(NSRect)rect {
	[view lockFocus];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:rect];
	[view unlockFocus];

	NSData *data = [bitmap representationUsingType:NSPNGFileType
	                                    properties:nil];
	[bitmap release];

	return data;
}
- (NSData *) dataWithTIFFInsideRect:(NSRect)rect {
	[view lockFocus];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:rect];
	[view unlockFocus];

	NSData *data = [bitmap TIFFRepresentationUsingCompression:NSTIFFCompressionPackBits
	                                                   factor:1.0f];
	[bitmap release];

	return data;
}

@end
