//
//  GrowlSubscribeGNTPPacket.m
//  Growl
//
//  Created by Rudy Richter on 10/7/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GrowlSubscribeGNTPPacket.h"


@implementation GrowlSubscribeGNTPPacket

@synthesize subscriberKeyHash = mSubscriberKeyHash;
@synthesize subscriberID = mSubscriberID;
@synthesize subscriberName = mSubscriberName;
@synthesize subscriberPort = mSubscriberPort;
@synthesize ttl = mTTL;

- (id)init
{
	if ((self = [super init])) {
		subscriptionDict = [[NSMutableDictionary alloc] init];
		mTTL = 300;
	}
	
	return self;
}

- (void)dealloc
{
	[subscriptionDict release];
	
	[super dealloc];
}

- (GrowlReadDirective)receivedHeaderItem:(GrowlGNTPHeaderItem *)headerItem
{
	NSString *name = [headerItem headerName];
	NSString *value = [headerItem headerValue];
	
	if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
		/* A notification just has a single section; we're done */
		if (pendingBinaryIdentifiers.count > 0)
			return GrowlReadDirective_SectionComplete;
		else
			return GrowlReadDirective_PacketComplete;
	}
	
	if ([name caseInsensitiveCompare:GrowlGNTPSubscriberID] == NSOrderedSame) {
		[self setSubscriberID:value];
	} else if ([name caseInsensitiveCompare:GrowlGNTPSubscriberName] == NSOrderedSame) {
		[self setSubscriberName:value];	
	} else if ([name caseInsensitiveCompare:GrowlGNTPSubscriberPort] == NSOrderedSame) {
		[self setSubscriberPort:[value integerValue]];	
	} else if ([name caseInsensitiveCompare:GrowlGNTPOriginMachineName] == NSOrderedSame) {
		[subscriptionDict setObject:value
							 forKey:GROWL_GNTP_ORIGIN_MACHINE];
	} else if ([name caseInsensitiveCompare:GrowlGNTPOriginSoftwareName] == NSOrderedSame) {
		[subscriptionDict setObject:value
							 forKey:GROWL_GNTP_ORIGIN_SOFTWARE_NAME];
	} else if ([name caseInsensitiveCompare:GrowlGNTPOriginSoftwareVersion] == NSOrderedSame) {
		[subscriptionDict setObject:value
							 forKey:GROWL_GNTP_ORIGIN_SOFTWARE_VERSION];
	} else if ([name caseInsensitiveCompare:GrowlGNTPOriginPlatformName] == NSOrderedSame) {
		[subscriptionDict setObject:value
							 forKey:GROWL_GNTP_ORIGIN_PLATFORM_NAME];
	} else if ([name caseInsensitiveCompare:GrowlGNTPOriginPlatformVersion] == NSOrderedSame) {
		[subscriptionDict setObject:value
							 forKey:GROWL_GNTP_ORIGIN_PLATFORM_VERSION];
	} else if ([name caseInsensitiveCompare:@"X-Application-PID"] == NSOrderedSame) {
		[subscriptionDict setObject:value
							 forKey:GROWL_APP_PID];
	} else if ([name rangeOfString:@"X-" options:(NSLiteralSearch | NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound) {
		[self addCustomHeader:headerItem];
	}
	
	return GrowlReadDirective_Continue;
}

- (NSArray *)headersForResult
{
	NSMutableArray *headersForResult = [[[super headersForResult] mutableCopy] autorelease];
	if (!headersForResult) 
		headersForResult = [NSMutableArray array];
	[headersForResult addObject:[GrowlGNTPHeaderItem headerItemWithName:GrowlGNTPResponseSubscriptionTTL value:[NSString stringWithFormat:@"%ld",[self ttl]]]];
	
	return headersForResult;
}
@end
