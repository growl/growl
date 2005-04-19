//
//  NSMutableStringAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 19.04.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "NSMutableStringAdditions.h"

@implementation NSMutableString (GrowlAdditions)
/*!
 * @brief Escape a string for passing to JavaScript scripts.
 */
- (NSMutableString *) escapeForJavaScript {
	NSRange range = NSMakeRange(0, [self length]);
	unsigned delta;
	//We need to escape a few things to get our string to the javascript without trouble
	delta = [self replaceOccurrencesOfString:@"\\" withString:@"\\\\"
									 options:NSLiteralSearch range:range];
	range.length += delta;
	
	delta = [self replaceOccurrencesOfString:@"\"" withString:@"\\\""
									 options:NSLiteralSearch range:range];
	range.length += delta;

	delta = [self replaceOccurrencesOfString:@"\n" withString:@""
									 options:NSLiteralSearch range:range];
	range.length -= delta;

	delta = [self replaceOccurrencesOfString:@"\r" withString:@"<br />"
									 options:NSLiteralSearch range:range];
	range.length += delta * 5;

	return self;
}

/*!
 * @brief Escape a string for HTML.
 */
- (NSMutableString *) escapeForHTML {
	NSRange range = NSMakeRange(0, [self length]);
	unsigned delta;
	delta = [self replaceOccurrencesOfString:@"&" withString:@"&amp;"
									 options:NSLiteralSearch range:range];
	range.length += delta * 4;
	
	delta = [self replaceOccurrencesOfString:@"<" withString:@"&lt;"
									 options:NSLiteralSearch range:range];
	range.length += delta * 3;
	
	delta = [self replaceOccurrencesOfString:@">" withString:@"&gt;"
									 options:NSLiteralSearch range:range];
	range.length += delta * 3;
	
	delta = [self replaceOccurrencesOfString:@"'" withString:@"&apos;"
									 options:NSLiteralSearch range:range];
	range.length += delta * 4;
	
	delta = [self replaceOccurrencesOfString:@"\n" withString:@"<br />"
									 options:NSLiteralSearch range:range];
	range.length += delta * 5;
	
	return self;
}
@end
