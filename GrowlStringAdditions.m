//
//  GrowlStringAdditions.m
//  Display Plugins
//
//  Created by Matthew Walton on 27/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlStringAdditions.h"

#define ELLIPSIS_STRING @"..."

@implementation NSString (GrowlStringAdditions)

- (void)drawWithEllipsisInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );

	if (pantherOrLater) {
		// use the built-in ellipsising system if possible
		NSMutableParagraphStyle *ellipsisingStyle = [[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
			setLineBreakMode:NSLineBreakByTruncatingTail] autorelease];
		NSMutableDictionary *md = [[[NSMutableDictionary alloc] initWithDictionary:attributes] autorelease];
		[md setObject:ellipsisingStyle forKey:NSParagraphStyleAttributeName];
		[self drawInRect:rect withAttributes:md];
		
	} else {
		// use our own ellipsising routine
		NSSize mySize = [self sizeWithAttributes:attributes];
		BOOL didTruncate = NO;
		NSMutableString *newString = [[[NSMutableString alloc] initWithString:self] autorelease];
		
		// while we don't fit (allowing room for the ellipsis), chop off the last character
		while (mySize.width > (NSWidth(rect) - mySize.height)) {
			didTruncate = YES;
			[newString deleteCharactersInRange:NSMakeRange([newString length] - 1, 1)];
			mySize = [newString sizeWithAttributes:attributes];
		}
		
		if (didTruncate) {
			// drop any trailing spaces, it looks odd if we put an ellipsis after a space
			while ([newString characterAtIndex:[newString length] - 1] == ' ') {
				[newString deleteCharactersInRange:NSMakeRange([newString length] - 1, 1)];
			}
			// add the ellipsis itself to indicate that there's missing text
			[newString appendString:ELLIPSIS_STRING];
		}
		
		// draw the string in the supplied rect with the supplied attributes
		[newString drawInRect:rect withAttributes:attributes];
	}
}

@end
