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

@end
