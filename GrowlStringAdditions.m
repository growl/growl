//
//  GrowlStringAdditions.m
//  Display Plugins
//
//  Created by Matthew Walton on 27/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlStringAdditions.h"

@implementation NSString (GrowlStringAdditions)

- (void)drawWithEllipsisInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );

	if (pantherOrLater) {
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
	} else {
		// use our own ellipsising routine
		NSSize mySize = [self sizeWithAttributes:attributes];
		BOOL didTruncate = NO;
		NSMutableString *newString = [NSMutableString stringWithString:self];

		unsigned length = [newString length];
		NSRange range = {
			.location = length,
			.length   = 1U,
		};

		// while we don't fit (allowing room for the ellipsis), chop off the last character
		while (mySize.width > (NSWidth(rect) - mySize.height)) {
			if(!length) break;
			range.location = --length;

			didTruncate = YES;
			[newString deleteCharactersInRange:range];
			mySize = [newString sizeWithAttributes:attributes];
		}
		
		if (didTruncate) {
			// drop any trailing spaces, it looks odd if we put an ellipsis after a space
			while (length && ([newString characterAtIndex:range.location] == ' ')) {
				range.location = --length;
				[newString deleteCharactersInRange:range];
			}

			if(length) {
				// add the ellipsis itself to indicate that there's missing text
				static const unichar ellipsis = 0x2026U;
				[newString appendString:[NSString stringWithCharacters:&ellipsis length:1U]];
			}
		}
		
		// draw the string in the supplied rect with the supplied attributes
		[newString drawInRect:rect withAttributes:attributes];
	}
}

@end
