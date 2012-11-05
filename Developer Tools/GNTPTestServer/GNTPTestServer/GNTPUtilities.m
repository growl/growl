//
//  GNTPUtilities.m
//  Growl
//
//  Created by Daniel Siemer on 7/13/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GNTPUtilities.h"

@implementation GNTPUtilities

+ (NSData*)doubleCRLF {
	static NSData *_doubleCLRF = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_doubleCLRF = [[NSData alloc] initWithBytes:"\x0D\x0A\x0D\x0A" length:4];
	});
	return _doubleCLRF;
}

+ (NSData*)gntpEndData {
	static NSData *_gntpEndData = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *endString = @"GNTP/1.0 END\r\n\r\n";
		_gntpEndData = [[NSData dataWithBytes:[endString UTF8String] length:[endString length]] retain];
	});
	return _gntpEndData;
}

#pragma mark Header Parsing methods
+(NSString*)headerKeyFromHeader:(NSString*)header {
	NSInteger location = [header rangeOfString:@": "].location;
	if(location != NSNotFound)
		return [header substringToIndex:location];
	return nil;
}
+(NSString*)headerValueFromHeader:(NSString*)header{
	NSInteger location = [header rangeOfString:@": "].location;
	if(location != NSNotFound)
		return [header substringFromIndex:location + 2];
	return nil;
}
+(void)enumerateHeaders:(NSString*)headersString
				  withBlock:(GNTPHeaderBlock)headerBlock
{
	NSArray *headers = [headersString componentsSeparatedByString:@"\r\n"];
	[headers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if(!obj || [obj isEqualToString:@""] || [obj isEqualToString:@"\r\n"])
			return;
		
		NSString *headerKey = [GNTPUtilities headerKeyFromHeader:obj];
		NSString *headerValue = [GNTPUtilities headerValueFromHeader:obj];
		if(headerKey && headerValue){
			if(headerBlock(headerKey, headerValue))
				*stop = YES;
		}else{
			//NSLog(@"Unable to find ': ' that seperates key and value in %@", obj);
		}
	}];
}

@end
