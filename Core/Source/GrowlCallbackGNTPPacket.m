//
//  GrowlCallbackGNTPPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 11/3/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlCallbackGNTPPacket.h"
#import "GrowlGNTPHeaderItem.h"

@implementation GrowlCallbackGNTPPacket
- (id)init
{
	if ((self = [super init])) {
		callbackDict = [[NSMutableDictionary alloc] init];
	} 
	return self;
}
- (void)dealloc
{
	[callbackDict release]; callbackDict = nil;
	
	[super dealloc];
}

- (NSString *)identifier
{
	return [callbackDict objectForKey:GROWL_NOTIFICATION_GNTP_ID];
}
- (void)setIdentifier:(NSString *)string
{
	[callbackDict setObject:string
						 forKey:GROWL_NOTIFICATION_GNTP_ID];
}

- (GrowlReadDirective)receivedHeaderItem:(GrowlGNTPHeaderItem *)headerItem
{
	NSString *name = [headerItem headerName];
	NSString *value = [headerItem headerValue];

	if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
		if ([self identifier])
			return GrowlReadDirective_PacketComplete;
		else {
			[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
											   code:GrowlGNTPCallbackPacketError
										   userInfo:[NSDictionary dictionaryWithObject:@"Notification-ID header is required in a callback response"
																				forKey:NSLocalizedFailureReasonErrorKey]]];
			return GrowlReadDirective_Error;
		}
	}

	if ([name caseInsensitiveCompare:@"Notification-ID"] == NSOrderedSame) {
		[self setIdentifier:value];
	} else if ([name rangeOfString:@"X-" options:NSLiteralSearch | NSAnchoredSearch].location != NSNotFound) {
		[self addCustomHeader:headerItem];
	}

	return GrowlReadDirective_Continue;
}

- (GrowlGNTPCallbackType)callbackType
{
	return (([[self action] caseInsensitiveCompare:@"-CLICKED"] == NSOrderedSame) ?
			GrowlGNTPCallback_Clicked :
			GrowlGNTPCallback_Closed);
}

/*!
 * @brief Headers to be returned via the -OK success result
 *
 * In the superclass, we just send any custom headers included in the packet originally
 */
- (NSArray *)headersForSuccessResult
{
	NSMutableArray *headersForSuccessResult = [[[super headersForSuccessResult] mutableCopy] autorelease];
	if (!headersForSuccessResult) headersForSuccessResult = [NSMutableArray array];
	[headersForSuccessResult addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-ID" value:[self identifier]]];
	
	return headersForSuccessResult;
}

@end
