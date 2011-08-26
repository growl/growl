//
//  NSMutableStringAdditions.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-11.
//  Copyright 2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details
//

#import "NSMutableStringAdditions.h"


@implementation NSMutableString (GrowlAdditions)

- (void) appendCharacter:(unichar)ch {
	CFStringAppendCharacters((CFMutableStringRef)self, &ch, /*numChars*/ 1L);
}


/*!
 * @brief Escape a string for passing to JavaScript scripts.
 */
- (NSMutableString*)escapeForJavaScript {
	NSRange range = NSMakeRange(0, [self length]);
	CFIndex delta;
	//We need to escape a few things to get our string to the javascript without trouble
	delta = [self replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:range];
	range.length += delta;
	delta = [self replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:range];
	range.length += delta;
	delta = [self replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:range];
	range.length -= delta;
	delta = [self replaceOccurrencesOfString:@"\r" withString:@"<br />" options:0 range:range];
	range.length += delta * 5;
    
	return self;
}

/*!
 * @brief Escape a string for HTML.
 */
- (NSMutableString*)escapeForHTML {
    NSRange range = NSMakeRange(0, [self length]);
    CFIndex delta;
    
	delta = [self replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:range];
    range.length += delta * 4;
    delta = [self replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:range];
    range.length += delta * 5;
    delta = [self replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:range];
    range.length += delta * 3;
    delta = [self replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:range];
    range.length += delta * 3;
    delta = [self replaceOccurrencesOfString:@"\'" withString:@"&apos;" options:0 range:range];
    range.length += delta * 5;
    delta = [self replaceOccurrencesOfString:@"\n" withString:@"<br />" options:0 range:range];
    range.length += delta * 5;
    delta = [self replaceOccurrencesOfString:@"\r" withString:@"<br />" options:0 range:range];
    range.length += delta * 5;
        
	return self;
}

@end
