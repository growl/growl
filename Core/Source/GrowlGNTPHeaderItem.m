//
//  GrowlGNTPHeaderItem.m
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlGNTPHeaderItem.h"
#import "GrowlGNTPPacketParser.h"
#import "AsyncSocket.h"

@interface GrowlGNTPHeaderItem (PRIVATE)
- (id)initForData:(NSData *)inData error:(NSError **)outError;
- (void)setHeaderName:(NSString *)string;
- (void)setHeaderValue:(NSString *)string;
@end

@implementation GrowlGNTPHeaderItem
+ (GrowlGNTPHeaderItem *)headerItemFromData:(NSData *)inData error:(NSError **)outError
{
	return [[[self alloc] initForData:inData error:outError] autorelease];
}

+ (GrowlGNTPHeaderItem *)headerItemWithName:(NSString *)name value:(NSString *)value
{
	GrowlGNTPHeaderItem *headerItem = [[[self alloc] init] autorelease];
	[hedaerItem setHeaderName:name];
	[headerItem setHeaderValue:value];
	return headerItem;
}

+ (GrowlGNTPHeaderItem *)separatorHeaderItem
{
	static GrowlGNTPHeaderItem *separatorHeaderItem = nil;
	if (!separatorHeaderItem)
		separatorHeaderItem = [[GrowlGNTPHeaderItem alloc] init];
	return separatorHeaderItem;
}

- (id)initForData:(NSData *)inData error:(NSError **)outError
{
	if ([inData isEqualToData:[AsyncSocket CRLFData]]) {
		/* Blank line received; this separates one section or block from another */
		[self release];
		return [[GrowlGNTPHeaderItem separatorHeaderItem] retain];
	}
	
	if ((self = [self init])) {
		NSString *headerLine = [[[NSString alloc] initWithData:inData
													  encoding:NSUTF8StringEncoding] autorelease];
		
#define HEADER_DELIMITER @": "
#define HEADER_DELIMITER_LENGTH 2
#define CRLF_LENGTH 2
		
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
		
		[self setHeaderName:[headerLine substringToIndex:endOfHeaderName]];
		[self setHeaderValue:[headerLine substringWithRange:NSMakeRange(endOfHeaderName + HEADER_DELIMITER_LENGTH,
																		[headerLine length] - endOfHeaderName - HEADER_DELIMITER_LENGTH - CRLF_LENGTH)]];
	}

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
- (void)setHeaderName:(NSString *)string
{
	[headerName autorelease];
	headerName = [string retain];
}
- (NSString *)headerValue
{
	return headerValue;
}
- (void)setHeaderValue:(NSString *)string
{
	[headerValue autorelease];
	headerValue = [string retain];
}
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %x: name=%@, value=%@>", NSStringFromClass([self class]), self, headerName, headerValue];
}

@end
