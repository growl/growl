//
//  GTPToken.m
//  GrowlTunes
//
//  Created by rudy on 9/16/07.
//  Copyright 2007 2007 The Growl Project. All rights reserved.
//

#import "GTPToken.h"


@implementation GTPToken

@synthesize text = displayText;

- (NSString*)description
{
	return [self code];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:displayText];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	displayText = [[decoder decodeObject] retain];
	return self;
}

- (NSString *)code
{
	return [NSString stringWithFormat:@"<<%@>>", displayText];
}

@end
