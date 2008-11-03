//
//  GrowlNotificationGNTPPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlNotificationGNTPPacket.h"
#import "GrowlGNTPHeaderItem.h"
#import "GrowlDefines.h"

#define GROWL_GNTP_NOTIFICATION_ID	@"GNTP Notification ID"

@implementation GrowlNotificationGNTPPacket

- (id)init
{
	if ((self = [super init])) {
		notificationDict = [[NSMutableDictionary alloc] init];
		callbackTargetMethod = CallbackURLTargetUnknownMethod;
	} 
	return self;
}
- (void)dealloc
{
	[notificationDict release]; notificationDict = nil;

	[iconID release];
	[iconURL release];

	[super dealloc];
}

- (NSString *)applicationName
{
	return [notificationDict objectForKey:GROWL_APP_NAME];
}
- (void)setApplicationName:(NSString *)string
{
	[notificationDict setValue:string forKey:GROWL_APP_NAME];
}

- (NSString *)notificationName
{
	return [notificationDict objectForKey:GROWL_NOTIFICATION_NAME];
}
- (void)setNotificationName:(NSString *)string
{
	[notificationDict setObject:string
						 forKey:GROWL_NOTIFICATION_NAME];
}

- (NSString *)title
{
	return [notificationDict objectForKey:GROWL_NOTIFICATION_TITLE];
}
- (void)setTitle:(NSString *)string
{
	[notificationDict setObject:string
						 forKey:GROWL_NOTIFICATION_TITLE];
}

- (NSString *)identifier
{
	return [notificationDict objectForKey:GROWL_GNTP_NOTIFICATION_ID];
}
- (void)setIdentifier:(NSString *)string
{
	[notificationDict setObject:string
						 forKey:GROWL_GNTP_NOTIFICATION_ID];
}
- (NSString *)coalesceIdentifier
{
	return [notificationDict objectForKey:GROWL_NOTIFICATION_IDENTIFIER];
}
- (void)setCoalesceIdentifier:(NSString *)string
{
	[notificationDict setObject:string
						 forKey:GROWL_NOTIFICATION_IDENTIFIER];
}

- (NSString *)text
{
	return [notificationDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
}
- (void)setText:(NSString *)string
{
	[notificationDict setObject:string
						 forKey:GROWL_NOTIFICATION_DESCRIPTION];
}

- (BOOL)sticky
{
	return [[notificationDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue];
}
- (void)setSticky:(BOOL)inSticky
{
	[notificationDict setObject:[NSNumber numberWithBool:inSticky]
						 forKey:GROWL_NOTIFICATION_STICKY];
}


- (void)setIconID:(NSString *)string
{
	[iconID autorelease];
	iconID = [string retain];
	[pendingBinaryIdentifiers addObject:iconID];
}
- (void)setIconURL:(NSURL *)url
{
	[iconURL autorelease];
	iconURL = [url retain];
	
	/* XXX Start loading the URL in the background */
}
- (NSImage *)icon
{
	NSData *data = nil;
	if (iconID) {
		data = [binaryDataByIdentifier objectForKey:iconID];
	} else if (iconURL) {
		/* XXX Blocking */
		data = [NSData dataWithContentsOfURL:iconURL];
	}
	
	return (data ? [[[NSImage alloc] initWithData:data] autorelease] : nil);
}

- (NSString *)callbackContext
{
	return [notificationDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
}
- (void)setCallbackContext:(NSString *)value
{
	[notificationDict setObject:value
						 forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
}
- (NSString *)callbackContextType
{
	return [notificationDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
}
- (void)setCallbackContextType:(NSString *)value
{
	[notificationDict setObject:value
						 forKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
}
- (NSString *)callbackTarget
{
	return [notificationDict objectForKey:GROWL_NOTIFICATION_CALLBACK_URL_TARGET];
}
- (void)setCallbackTarget:(NSString *)value
{
	[notificationDict setObject:value
						 forKey:GROWL_NOTIFICATION_CALLBACK_URL_TARGET];
}
- (void)setCallbackTargetMethod:(CallbackURLTargetMethod)inMethod
{
	[notificationDict setObject:(inMethod == CallbackURLTargetGetMethod ? @"GET" : @"POST")
						 forKey:GROWL_NOTIFICATION_CALLBACK_URL_TARGET_METHOD];
	callbackTargetMethod = inMethod;
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

	if ([name caseInsensitiveCompare:@"Application-Name"] == NSOrderedSame) {
		[self setApplicationName:value];
	} else if ([name caseInsensitiveCompare:@"Notification-Name"] == NSOrderedSame) {
		[self setNotificationName:value];	
	} else if ([name caseInsensitiveCompare:@"Notification-Title"] == NSOrderedSame) {
		[self setTitle:value];	
	} else if ([name caseInsensitiveCompare:@"Notification-ID"] == NSOrderedSame) {
		[self setIdentifier:value];	
	} else if ([name caseInsensitiveCompare:@"Notification-Coalesce-ID"] == NSOrderedSame) {
		[self setCoalesceIdentifier:value];
	} else if ([name caseInsensitiveCompare:@"Notification-Text"] == NSOrderedSame) {
		[self setText:value];	
	} else if ([name caseInsensitiveCompare:@"Notification-Sticky"] == NSOrderedSame) {
		BOOL sticky = (([value caseInsensitiveCompare:@"Yes"] == NSOrderedSame) ||
						([value caseInsensitiveCompare:@"True"] == NSOrderedSame));
		[self setSticky:sticky];	
	} else if ([name caseInsensitiveCompare:@"Notification-Icon"] == NSOrderedSame) {
		if ([value hasPrefix:@"x-growl-resource://"]) {
			/* Extract the resource ID from the value */
			[self setIconID:[value substringFromIndex:[@"x-growl-resource://" length]]];
		} else {
			/* If it's not an x-growl-resource, it must be a URL. If value isn't an URL, we'll be setting
			 * iconURL to nil as NSURL returns nil. That's fine fall-through behavior.
			 */
			[self setIconURL:[NSURL URLWithString:value]];
		}
	} else if ([name caseInsensitiveCompare:@"Notification-Callback-Context"] == NSOrderedSame) {
		[self setCallbackContext:value];
	} else if ([name caseInsensitiveCompare:@"Notification-Callback-Context-Type"] == NSOrderedSame) {
		[self setCallbackContextType:value];

	} else if ([name caseInsensitiveCompare:@"Notification-Callback-Target"] == NSOrderedSame) {
		[self setCallbackTarget:value];
	} else if ([name caseInsensitiveCompare:@"Notification-Callback-Target-Method"] == NSOrderedSame) {
		CallbackURLTargetMethod method;
		if ([value caseInsensitiveCompare:@"GET"]) {
			method = CallbackURLTargetGetMethod;
		} else if ([value caseInsensitiveCompare:@"POST"]) {
			method = CallbackURLTargetPostMethod;
		} else {
			method = CallbackURLTargetUnknownMethod;
		}

		[self setCallbackTargetMethod:method];
	} else if ([name rangeOfString:@"X-" options:NSLiteralSearch | NSAnchoredSearch].location != NSNotFound) {
		[self addCustomHeader:headerItem];
	}
	
	return GrowlReadDirective_Continue;
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

#pragma mark Callbacks
- (GrowlGNTPCallbackBehavior)callbackResultSendBehavior
{
	if ([self callbackContext] && [self callbackContextType]) {
		if ([self callbackTarget] && (callbackTargetMethod != CallbackURLTargetUnknownMethod)) {
			return GrowlGNTP_URLCallback;
		} else {
			return GrowlGNTP_TCPCallback;
		}
	} else {
		return GrowlGNTP_NoCallback;	
	}
}

- (NSArray *)headersForCallbackResult
{
	NSMutableArray *headersForCallbackResult = [NSMutableArray array];
	[headersForCallbackResult addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-ID" value:[self identifier]]];
	[headersForCallbackResult addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Callback-Context" value:[self callbackContext]]];
	[headersForCallbackResult addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Callback-Context-Type" value:[self callbackContextType]]];
	if (customHeaders) [headersForCallbackResult addObjectsFromArray:customHeaders];
	
	return headersForCallbackResult;
}

- (NSURLRequest *)urlRequestForCallbackResult
{
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

	NSMutableString *responsePost = [NSMutableString string];
	[responsePost appendFormat:@"Notification-ID=%@", [self identifier]];
	[responsePost appendFormat:@"&Notification-Callback-Context-Type=%@", [self callbackContextType]];
	[responsePost appendFormat:@"&Notification-Callback-Context=%@", [self callbackContext]];

	NSEnumerator *enumerator = [[self customHeaders] objectEnumerator];
	GrowlGNTPHeaderItem *headerItem;
	while ((headerItem = [enumerator nextObject])) {
		[responsePost appendFormat:@"&%@=%@", [headerItem headerName], [headerItem headerValue]];
	}
	
	if (callbackTargetMethod == CallbackURLTargetPostMethod) {
		NSData *responsePostData = [responsePost dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		NSString *responsePostLength = [NSString stringWithFormat:@"%d", [responsePostData length]];

		[request setHTTPMethod:@"POST"];
		[request setURL:[NSURL URLWithString:[self callbackTarget]]];
		[request setValue:responsePostLength forHTTPHeaderField:@"Content-Length"];
		[request setHTTPBody:responsePostData];
	
	} else /* CallbackURLTargetGetMethod */ {
		NSString *urlString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																				  (CFStringRef)[NSString stringWithFormat:@"%@?%@", [self callbackTarget], responsePost],
																				  /* charactersToLeaveUnescaped */ NULL,
																				  /* legalURLCharactersToBeEscaped */ NULL,
																				  kCFStringEncodingUTF8);
		
	    [request setHTTPMethod:@"GET"];
		[request setURL:[NSURL URLWithString:urlString]];
		[urlString release];
	}

	return request;
}


/*!
 * @brief Return a Growl registration dictionary
 *
 * Dictionary format as per the documentation for GrowlApplicationBridgeDelegate_InformalProtocol's registrationDictionary
 * found in GrowlApplicationBridge.h.
 */
- (NSDictionary *)growlDictionary
{
	NSMutableDictionary *growlDictionary = [[[super growlDictionary] mutableCopy] autorelease];
	
	[growlDictionary addEntriesFromDictionary:notificationDict];
	[growlDictionary setValue:[self icon]
					   forKey:GROWL_NOTIFICATION_ICON];
	
	return growlDictionary;
}

@end
