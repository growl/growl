//
//  NSStringAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 16.05.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "NSStringAdditions.h"

@implementation NSString (GrowlAdditions)

+ (NSString *) stringWithUTF8String:(const char *)bytes length:(unsigned)len {
	return [[[NSString alloc] initWithUTF8String:bytes length:len] autorelease];
}

- (id) initWithUTF8String:(const char *)bytes length:(unsigned)len {
	return [self initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
}

//for greater polymorphism with NSNumber.
- (BOOL) boolValue {
	return [self intValue] != 0
	|| [self caseInsensitiveCompare:@"yes"]  == NSOrderedSame
	|| [self caseInsensitiveCompare:@"true"] == NSOrderedSame;
}

- (unsigned long) unsignedLongValue {
	return strtoul([self UTF8String], /*endptr*/ NULL, /*base*/ 0);
}

- (unsigned) unsignedIntValue {
	return [self unsignedLongValue];
}

- (BOOL) isSubpathOf:(NSString *)superpath {
	NSString *canonicalSuperpath = [superpath stringByStandardizingPath];
	NSString *canonicalSubpath = [self stringByStandardizingPath];
	return [canonicalSubpath isEqualToString:canonicalSuperpath]
		|| [canonicalSubpath hasPrefix:[canonicalSuperpath stringByAppendingString:@"/"]];
}

- (NSAttributedString *) hyperlinkWithColor:(NSColor *)color {
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
		self, NSLinkAttributeName,    // link to self
		[NSFont systemFontOfSize:[NSFont smallSystemFontSize]],	NSFontAttributeName,
		color, NSForegroundColorAttributeName,
		[NSCursor pointingHandCursor], NSCursorAttributeName,
        nil];
	NSAttributedString *result = [[[NSAttributedString alloc] initWithString:self attributes:attributes] autorelease];
	[attributes release];
	return result;
}

- (NSAttributedString *) hyperlink {
	return [self hyperlinkWithColor:[NSColor blueColor]];
}
- (NSAttributedString *) activeHyperlink {
	return [self hyperlinkWithColor:[NSColor redColor]];
}

@end
