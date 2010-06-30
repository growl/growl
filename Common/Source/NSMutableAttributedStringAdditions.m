//
//  NSMutableAttributedStringAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 19.06.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "NSMutableAttributedStringAdditions.h"

@implementation NSMutableAttributedString(GrowlAdditions)

/*!
 * Add each attribute in the defaultAttributes dictionary to all ranges where
 * the attribute is not set.
 */
- (void) addDefaultAttributes:(NSDictionary *)defaultAttributes {
	NSRange range;
	for (NSUInteger i=0U, length = [self length]; i<length; i += range.length) {
		NSDictionary *currentAttributes = [[self attributesAtIndex:i effectiveRange:&range] retain];
		for (NSString *attributeName in defaultAttributes)
			if (![currentAttributes objectForKey:attributeName])
				[self addAttribute:attributeName
							 value:[defaultAttributes objectForKey:attributeName]
							 range:range];
		[currentAttributes release];
	}
}

@end
