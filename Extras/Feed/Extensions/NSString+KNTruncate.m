/*

BSD License

Copyright (c) 2004, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "NSString+KNTruncate.h"
#import <openssl/md5.h>


@implementation NSString (KNTruncate)

-(NSString *)ellipsizeToWidth:(float)width withAttributes:(NSDictionary *)atts{
	NSMutableString *			newString = [NSMutableString stringWithString: self];
	float						currentWidth = [self sizeWithAttributes: atts].width;
	NSString *					ellipses = [NSString stringWithString: @"..."];
	float						ellipsesWidth = [ellipses sizeWithAttributes: atts].width;
	
	//KNDebug(@"KNSTRING: ellipsizeToWidth: %f withAttributes: %@", width, atts);
	// Handle cases where it already fits first
	if( currentWidth <= width ){
		return newString;
	}
	
	while( ((currentWidth + ellipsesWidth) > width) && ([newString length] > 0) ){
		[newString deleteCharactersInRange: NSMakeRange( [newString length]-1, 1 )];
		currentWidth = [newString sizeWithAttributes: atts].width;
	}
	
	[newString appendString: ellipses];
	return newString;
}

-(NSString *)stripNamespace{
	NSArray *				elementList = [self componentsSeparatedByString:@":"];
	//KNDebug(@"TRUNC: stripNamespace '%@'", self);
	if( [elementList count] > 1 ){
		return [elementList objectAtIndex: [elementList count]-1];
	}else{
		return [elementList objectAtIndex: 0];
	}
}

-(NSString *)trimWhitespace{
	//KNDebug(@"TRUNC: trimWhitespace '%@'", self);
	return [self stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


// collapses runs of whitespace into a single space
-(NSString *)collapseWhitespace{
	NSMutableString *		collapsedString = [NSMutableString stringWithString: [self trimWhitespace]];
	NSCharacterSet *		whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSRange					foundWhitespace;
	
	foundWhitespace = [collapsedString rangeOfCharacterFromSet: whitespace];
	while( (foundWhitespace.location != NSNotFound) && (foundWhitespace.length > 1) ){
		[collapsedString replaceCharactersInRange: foundWhitespace withString:@" "];
		foundWhitespace = [collapsedString rangeOfCharacterFromSet: whitespace];
	}
	return collapsedString;
}

-(NSString *)collapseHTML{
	//KNDebug(@"TRUNCATE: collapseHTML %@", self);
	return [[self copy] autorelease];
	
	NSData *				rawData = [self dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion: NO];
	//NSData *				rawData = [[NSData dataWithBytes: [self lossyCString] length: [self length]] retain];
	//KNDebug(@"TRUNCATE: data: %@", rawData);
	//NSData *				rawData = [NSData dataWithBytes: [self UTF8String] length: [self length]];
	NSAttributedString *	attString = [[NSAttributedString alloc] initWithHTML: rawData documentAttributes: nil];
	//KNDebug(@"TRUNCATE: attString: %@", attString);
	//[rawData release];
	
	if( attString != nil ){
		return [attString autorelease];
	}else{
		return [[self copy] autorelease];
	}
}

-(NSString *)md5{
	NSData *				data = [NSArchiver archivedDataWithRootObject: self];
	return [NSString stringWithCString: (const char *) MD5([data bytes], [data length], NULL)];
}

@end
