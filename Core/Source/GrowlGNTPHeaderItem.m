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
@end

@implementation GrowlGNTPHeaderItem
+ (GrowlGNTPHeaderItem *)headerItemFromData:(NSData *)inData error:(NSError **)outError
{
	return [[[self alloc] initForData:inData error:outError] autorelease];
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
		/* Blank line received; this separates one section from another */
		/* GrowlReadDirective_SectionComplete vs. GrowlReadDirective_Continue */
		[self release];
		return [[GrowlGNTPHeaderItem separatorHeaderItem] retain];
	}
	
	if ((self = [self init])) {
		NSString *headerLine = [[[NSString alloc] initWithData:inData
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
		/* XXX .... is that right? -1 is for the CRLF at the end */
		headerValue = [[headerLine substringWithRange:NSMakeRange(endOfHeaderName + HEADER_DELIMITER_LENGTH,
																  [headerLine length] - endOfHeaderName - HEADER_DELIMITER_LENGTH - 2)] retain];
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

- (NSString *)headerValue
{
	return headerValue;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %x: name=%@, value=%@>", NSStringFromClass([self class]), self, headerName, headerValue];
}

@end
