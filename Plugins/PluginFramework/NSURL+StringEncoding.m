//
//  NSURL+StringEncoding.m
//  Boxcar
//
//  Created by Daniel Siemer on 4/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "NSURL+StringEncoding.h"

@implementation NSURL (StringEncoding)

+(NSString*)encodedStringByAddingPercentEscapesToString:(NSString*)string {
	CFStringRef stringRef = CFURLCreateStringByAddingPercentEscapes(NULL,
																						 (CFStringRef)string, 
																						 NULL,
																						 (CFStringRef)@";/?:@&=+$",
																						 kCFStringEncodingUTF8);
	NSString *encodedString = [(NSString*)stringRef copy];
	CFRelease(stringRef);
	
	return [encodedString autorelease];
}

@end
