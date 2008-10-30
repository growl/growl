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

@implementation GrowlNotificationGNTPPacket

- (id)init
{
	if ((self = [super init])) {
		notificationDict = [[NSMutableDictionary alloc] init];
	} 
	return self;
}
- (void)dealloc
{
	[notificationDict release]; notificationDict = nil;
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
	return [notificationDict objectForKey:GROWL_NOTIFICATION_IDENTIFIER];
}
- (void)setIdentifier:(NSString *)string
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

- (void)setCallbackContext:(NSString *)value
{
	[notificationDict setObject:value
						 forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
}

- (void)setCallbackTarget:(NSURL *)url
{
	[callbackTarget autorelease];
	callbackTarget = [url retain];
}
- (void)setCallbackTargetMethod:(CallbackURLTargetMethod)inMethod
{
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

	if (!name || !value) {
		NSLog(@"Missing name or value");
		return GrowlReadDirective_Error;
	}

	if ([name caseInsensitiveCompare:@"Application-Name"] == NSOrderedSame) {
		[self setApplicationName:value];
	} else if ([name caseInsensitiveCompare:@"Notification-Name"] == NSOrderedSame) {
		[self setNotificationName:value];	
	} else if ([name caseInsensitiveCompare:@"Notification-Title"] == NSOrderedSame) {
		[self setTitle:value];	
	} else if ([name caseInsensitiveCompare:@"Notification-ID"] == NSOrderedSame) {
		[self setIdentifier:value];	
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
	} else if ([name caseInsensitiveCompare:@"Notification-Callback-Target"] == NSOrderedSame) {
		[self setCallbackTarget:[NSURL URLWithString:value]];
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
	} else {
		[self setCustomHeaderWithName:name value:value];
	}
	
	return GrowlReadDirective_Continue;
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
