//
//  GrowlStringAdditions.m
//  Display Plugins
//
//  Created by Matthew Walton on 27/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "GrowlStringAdditions.h"

@implementation NSString (GrowlStringAdditions)

- (void)drawWithEllipsisInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
	// use the built-in ellipsising system if possible
	NSParagraphStyle *paragraphStyle = [attributes objectForKey:NSParagraphStyleAttributeName];
	if (!paragraphStyle) {
		paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
	}
	NSMutableParagraphStyle *ellipsisingStyle = [[paragraphStyle mutableCopy] autorelease];
	[ellipsisingStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:attributes];
	[md setObject:ellipsisingStyle forKey:NSParagraphStyleAttributeName];
	[self drawInRect:rect withAttributes:md];
}

@end
