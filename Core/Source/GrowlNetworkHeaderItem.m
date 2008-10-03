//
//  GrowlNetworkHeaderItem.m
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlNetworkHeaderItem.h"

@interface GrowlNetworkHeaderItem (PRIVATE)
- (id)initForData:(NSData *)inData error:(NSError **)outError;
@end

@implementation GrowlNetworkHeaderItem
+ (GrowlNetworkHeaderItem *)headerItemFromData:(NSData *)inData error:(NSError **)outError
{
	return [[[self alloc] initForData:inData error:outError] autorelease];
}

+ (GrowlNetworkHeaderItem *)separatorHeaderItem
{
	static GrowlNetworkHeaderItem *separatorHeaderItem = nil;
	if (!separatorHeaderItem)
		separatorHeaderItem = [[GrowlNetworkHeaderItem alloc] init];
	return separatorHeaderItem;
}

- (id)initForData:(NSData *)inData error:(NSError **)outError
{
	if ([inData isEqualToData:[AsyncSocket CRLFData]]) {
		/* Blank line received; this separates one section from another */
		/* GrowlReadDirective_SectionComplete vs. GrowlReadDirective_Continue */
		[self release];
		return [[GrowlNetworkHeaderItem separatorHeaderItem] retain];
	}
	
	self = [super init];

	NSString *headerLine = [[[NSString alloc] initWithData:data
												  encoding:NSUTF8StringEncoding] autorelease];
	
#define HEADER_DELIMITER @": "
#define HEADER_DELIMITER_LENGTH 2

	int endOfHeaderName = [headerLine rangeOfString:HEADER_DELIMITER options:NSLiteralSearch].location;
	if (endOfHeaderName == NSNotFound) {
		/* Malformed header; no "name: value" setup */
		if (outError)
			*outError = [NSError errorWithDomain:@"GrowlNetwork"
											code:GrowlHeaderError
										userInfo:[NSDictionary dictionaryWithObject:@"Malformed header; \"name: value\" not found"
																			 forKey:NSLocalizedFailureReasonErrorKey]];
		[self release];
		return nil;
	}
	
	headerName = [[headerLine substringToIndex:endOfHeaderName] retain];
	headerValue = [[headerLine substringFromIndex:(endOfHeaderName + HEADER_DELIMITER_LENGTH)] retain];

	return self;
}

- (void)dealloc
{
	[headerName release];
	[headerValue release];
	[super dealloc];
}

- (NSString *)headerName
{
	return headerName;	
}

- (NSString *)headerValue
{
	return headerValue;
}

@end
