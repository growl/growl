//
//  CFMutableStringAdditions.c
//  Growl
//
//  Created by Ingmar Stein on 19.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#include "CFMutableStringAdditions.h"

/*!
 * @brief Escape a string for passing to JavaScript scripts.
 */
CFMutableStringRef escapeForJavaScript(CFMutableStringRef theString) {
	CFRange range = CFRangeMake(0, CFStringGetLength(theString));
	unsigned delta;
	//We need to escape a few things to get our string to the javascript without trouble
	delta = CFStringFindAndReplace(theString, CFSTR("\\"), CFSTR("\\\\"), range, 0);
	range.length += delta;
	delta = CFStringFindAndReplace(theString, CFSTR("\""), CFSTR("\\\""), range, 0);
	range.length += delta;
	delta = CFStringFindAndReplace(theString, CFSTR("\n"), CFSTR(""), range, 0);
	range.length -= delta;
	delta = CFStringFindAndReplace(theString, CFSTR("\r"), CFSTR("<br />"), range, 0);
	range.length += delta * 5;

	return theString;
}

/*!
 * @brief Escape a string for HTML.
 */
CFStringRef createStringByEscapingForHTML(CFStringRef theString) {
	Boolean freeWhenDone;
	unsigned j = 0U;
	unsigned count = CFStringGetLength(theString);
	UniChar c;
	UniChar *inbuffer = (UniChar *)CFStringGetCharactersPtr(theString);
	// worst case is a string consisting only of newlines or apostrophes
	UniChar *outbuffer = (UniChar *)malloc(6 * count * sizeof(UniChar));

	if (inbuffer) {
		freeWhenDone = false;
	} else {
		CFRange range;
		range.location = 0U;
		range.length = count;

		freeWhenDone = true;
		inbuffer = (UniChar *)malloc(count * sizeof(UniChar));
		CFStringGetCharacters(theString, range, inbuffer);
	}

	for (unsigned i=0U; i < count; ++i) {
		switch ((c=inbuffer[i])) {
			default:
				outbuffer[j++] = c;
				break;
			case '&':
				outbuffer[j++] = '&';
				outbuffer[j++] = 'a';
				outbuffer[j++] = 'm';
				outbuffer[j++] = 'p';
				outbuffer[j++] = ';';
				break;
			case '"':
				outbuffer[j++] = '&';
				outbuffer[j++] = 'q';
				outbuffer[j++] = 'u';
				outbuffer[j++] = 'o';
				outbuffer[j++] = 't';
				outbuffer[j++] = ';';
				break;
			case '<':
				outbuffer[j++] = '&';
				outbuffer[j++] = 'l';
				outbuffer[j++] = 't';
				outbuffer[j++] = ';';
				break;
			case '>':
				outbuffer[j++] = '&';
				outbuffer[j++] = 'g';
				outbuffer[j++] = 't';
				outbuffer[j++] = ';';
				break;
			case '\'':
				outbuffer[j++] = '&';
				outbuffer[j++] = 'a';
				outbuffer[j++] = 'p';
				outbuffer[j++] = 'o';
				outbuffer[j++] = 's';
				outbuffer[j++] = ';';
				break;
			case '\n':
			case '\r':
				outbuffer[j++] = '<';
				outbuffer[j++] = 'b';
				outbuffer[j++] = 'r';
				outbuffer[j++] = ' ';
				outbuffer[j++] = '/';
				outbuffer[j++] = '>';
				break;
		}
	}
	if (freeWhenDone)
		free(inbuffer);

	return CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault, outbuffer, j, kCFAllocatorMalloc);
}
