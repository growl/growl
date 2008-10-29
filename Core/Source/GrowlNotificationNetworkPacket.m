//
//  GrowlNotificationNetworkPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlNotificationNetworkPacket.h"

@implementation GrowlNotificationNetworkPacket
- (NSString *)applicationName
{
	return applicationName;
}
- (void)setApplicationName:(NSString *)string
{
	[applicationName autorelease];
	applicationName = [string retain];
}

- (NSString *)notificationName
{
	return notificationName;
}
- (void)setNotificationName:(NSString *)string
{
	[notificationName autorelease];
	notificationName = [string retain];
}

- (NSString *)title
{
	return title;
}
- (void)setTitle:(NSString *)string
{
	[title autorelease];
	title = [string retain];
}

- (NSString *)identifier
{
	return identifier;
}
- (void)setIdentifier:(NSString *)string
{
	[identifier autorelease];
	identifier = [string retain];
}

- (NSString *)text
{
	return text;
}
- (void)setText:(NSString *)string
{
	[text autorelease];
	text = [string retain];
}

- (BOOL)sticky
{
	return sticky;
}
- (void)setSticky:(BOOL)inSticky
{
	sticky = inSticky;
}

- (void)setIconID:(NSString *)string
{
	[iconID autorelease];
	iconID = [string retain];
}
- (void)setIconURL:(NSURL *)url
{
	[iconURL autorelease];
	iconURL = [url retain];
	
	/* XXX Start loading the URL in the background */
}
- (NSImage *)icon
{
	/* XXX retrieve the icon */
	return nil;
}

- (void)setCallbackContext:(NSString *)value
{
	[callbackContext autorelease];
	callBackContext = [value retain];
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

- (GrowlReadDirective)receivedHeaderItem:(GrowlNetworkHeaderItem *)headerItem
{
	NSString *name = [headerItem headerName];
	NSString *value = [headerItem headerValue];
	
	if (headerItem == [GrowlNetworkHeaderItem separatorHeaderItem]) {
		/* A notification just has a single section; we're done */
		return GrowlReadDirective_SectionComplete;
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
		[self setSticky:[value caseInsensitiveCompare:@"yes"]];	
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

@end
