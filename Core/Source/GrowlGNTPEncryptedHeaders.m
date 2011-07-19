//
//  GrowlGNTPEncryptedHeaders.m
//  Growl
//
//  Created by Rudy Richter on 10/12/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GrowlGNTPEncryptedHeaders.h"


@implementation GrowlGNTPEncryptedHeaders
@synthesize headers = _headers;

+ (GrowlGNTPEncryptedHeaders *)headerItemFromData:(NSData *)inData error:(NSError **)outError
{
	return [[[self alloc] initForData:inData error:outError] autorelease];
}

- (id)initForData:(NSData *)inData error:(NSError **)outError
{	
	if ((self = [self init])) 
	{
		[self setHeaders:inData];
	}
	return self;
}

- (NSData *)GNTPRepresentation
{
	return [self headers];
}
- (NSString *)GNTPRepresentationAsString
{
	return [[self GNTPRepresentation] description];
}
@end
