//
//  GrowlRegisterGNTPPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlRegisterGNTPPacket.h"
#import "GrowlGNTPHeaderItem.h"
#import "GrowlGNTPBinaryChunk.h"
#import "NSStringAdditions.h"
#import "GrowlDefines.h"

#define GROWL_NOTIFICATION_HUMAN_READABLE_NAME		@"HumanReadableName"
#define GROWL_NOTIFICATION_ENABLED_BY_DEFAULT		@"EnabledByDefault"

#define GROWL_NOTIFICATION_ICON_ID					@"NotificationIconID"
#define GROWL_NOTIFICATION_ICON_URL					@"NotificationIconURL"

/*
 * XXX Growl doesn't currently have a per-notification icon mechanism which can be 'registered'
 */
@implementation GrowlRegisterGNTPPacket

- (id)init
{
	if ((self = [super init])) {
		registrationDict = [[NSMutableDictionary alloc] init];
		notifications = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[registrationDict release];
	[notifications release];
	[currentNotification release];
	
	[applicationIconID release];
	[applicationIconURL release];
	
	[super dealloc];
}


- (NSString *)applicationName
{
	return [registrationDict objectForKey:GROWL_APP_NAME];
}
- (void)setApplicationName:(NSString *)string
{
	[registrationDict setValue:string forKey:GROWL_APP_NAME];
}

- (NSString *)applicationBundleID
{
	return [registrationDict objectForKey:GROWL_APP_ID];
}
- (void)setApplicationBundleID:(NSString *)string
{
	[registrationDict setValue:string forKey:GROWL_APP_ID];
}

- (void)setApplicationIconID:(NSString *)string
{
	[applicationIconID autorelease];
	applicationIconID = [string retain];
	[pendingBinaryIdentifiers addObject:applicationIconID];
}
- (NSString *)applicationIconID
{
	return applicationIconID;
}
- (void)setApplicationIconURL:(NSURL *)url
{
	[applicationIconURL autorelease];
	applicationIconURL = [url retain];
	
	/* XXX Start loading the URL in the background? */
}
- (NSURL *)applicationIconURL
{
	return applicationIconURL;
}

- (NSImage *)applicationIcon
{
	NSData *data = nil;
	if (applicationIconID) {
		data = [binaryDataByIdentifier objectForKey:applicationIconID];
	} else if (applicationIconURL) {
		/* XXX Blocking */
		data = [NSData dataWithContentsOfURL:applicationIconURL];
	}

	return (data ? [[[NSImage alloc] initWithData:data] autorelease] : nil);
}

- (void)addReceivedHeader:(NSString *)string
{
	NSMutableArray *receivedValues = [registrationDict valueForKey:GROWL_NOTIFICATION_GNTP_RECEIVED];
	if (!receivedValues) {
		receivedValues = [NSMutableArray array];
		[registrationDict setObject:receivedValues
							 forKey:GROWL_NOTIFICATION_GNTP_RECEIVED];
	}
	
	[receivedValues addObject:string];
}
- (void)setSentBy:(NSString *)string
{
	[registrationDict setValue:string forKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
}

/*!
 * @brief Is currentNotification valid (i.e. does it have all required keys?)
 *
 * @param error If invalid, will return by reference the NSError describing the invalidating factor
 * @return YES if valid, NO if not
 */
- (BOOL)validateCurrentNotification:(NSError **)anError
{
	NSString *errorString = nil;

	if (![currentNotification valueForKey:GROWL_NOTIFICATION_NAME])
		errorString = @"Notification-Name is a required header for each notification in a REGISTER request";
	else if (![currentNotification valueForKey:GROWL_NOTIFICATION_HUMAN_READABLE_NAME])
		errorString = @"Notification-Display-Name is a required header for each notification in a REGISTER request";

	if (errorString)
		*anError = [NSError errorWithDomain:GROWL_NETWORK_DOMAIN
									 code:GrowlGNTPRegistrationPacketError
								 userInfo:[NSDictionary dictionaryWithObject:errorString
																	  forKey:NSLocalizedFailureReasonErrorKey]];
	else
		*anError = nil;

	return (*anError == nil);
}

- (GrowlReadDirective)receivedHeaderItem:(GrowlGNTPHeaderItem *)headerItem
{
	GrowlReadDirective directive = GrowlReadDirective_Continue;

	NSString *name = [headerItem headerName];
	NSString *value = [headerItem headerValue];

	switch (currentStep) {
		case GrowlRegisterStepRegistrationHeader:
		{
			if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
				/* Done with the registration header; time to get actual notifications */
				currentStep = GrowlRegisterStepNotification;
				
				/* If we haven't gotten name, icon, and notification count at this point, throw an error */
				NSString *errorString = nil;
				if (![self applicationName]) {
					errorString = @"Application-Name is a required header for registration";
				} else if (![self applicationIconID] && ![self applicationIconURL]) {
					errorString = @"Application-Icon is a required header for registration";
				} else if (numberOfNotifications == 0) {
					errorString = @"Notifications-Count	is a required header for registration and must not be 0";
				}

				if (errorString) {
					[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
													   code:GrowlGNTPRegistrationPacketError
												   userInfo:[NSDictionary dictionaryWithObject:errorString
																						forKey:NSLocalizedFailureReasonErrorKey]]];
					directive = GrowlReadDirective_Error;
				} else {
					/* Otherwise, prepare to start tracking notifications */
					currentNotification = [[NSMutableDictionary alloc] init];
				}
			} else {
				/* Process a registration header */
				if ([name caseInsensitiveCompare:@"Application-Name"] == NSOrderedSame) {
					[self setApplicationName:value];
				} else if ([name caseInsensitiveCompare:@"Application-Icon"] == NSOrderedSame) {
					if ([value hasPrefix:@"x-growl-resource://"]) {
						/* Extract the resource ID from the value */
						[self setApplicationIconID:[value substringFromIndex:[@"x-growl-resource://" length]]];
					} else {
						/* If it's not an x-growl-resource, it must be a URL. If value isn't an URL, we'll be setting
						 * iconURL to nil as NSURL returns nil. That's fine fall-through behavior.
						 */
						[self setApplicationIconURL:[NSURL URLWithString:value]];
					}
				} else if ([name caseInsensitiveCompare:@"Notifications-Count"] == NSOrderedSame) {
					numberOfNotifications = [value unsignedIntValue];
				} else if ([name caseInsensitiveCompare:@"X-Application-BundleID"] == NSOrderedSame) {
					[self setApplicationBundleID:value];
				} else if ([name caseInsensitiveCompare:@"Received"] == NSOrderedSame) {
					[self addReceivedHeader:value];
				} else if ([name caseInsensitiveCompare:@"Sent-By"] == NSOrderedSame) {
					[self setSentBy:value];
				}
			}
			break;
		}
		case GrowlRegisterStepNotification:
		{
			/* Process a header for a specific notification */
			if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
				/* Done with this notification; start working on the next or on binary data */
				NSError *anError = nil;
				if ([self validateCurrentNotification:&anError]) {
					[notifications addObject:currentNotification];
					[currentNotification release]; currentNotification = nil;

					if ([notifications count] == numberOfNotifications) {
						directive = GrowlReadDirective_SectionComplete;
					} else {
						currentNotification = [[NSMutableDictionary alloc] init];
					}
					
				} else {
					/* Current notification failed to validate; error. */
					[self setError:anError];
					directive = GrowlReadDirective_Error;
				}
				
			} else {
				if ([name caseInsensitiveCompare:@"Notification-Name"] == NSOrderedSame) {
					[currentNotification setValue:value
										   forKey:GROWL_NOTIFICATION_NAME];
				} else if ([name caseInsensitiveCompare:@"Notification-Display-Name"] == NSOrderedSame) {
					[currentNotification setValue:value
										   forKey:GROWL_NOTIFICATION_HUMAN_READABLE_NAME];
					
				} else if ([name caseInsensitiveCompare:@"Notification-Enabled"] == NSOrderedSame) {
					BOOL enabled = (([value caseInsensitiveCompare:@"Yes"] == NSOrderedSame) ||
									([value caseInsensitiveCompare:@"True"] == NSOrderedSame));
					[currentNotification setValue:[NSNumber numberWithBool:enabled]
										   forKey:GROWL_NOTIFICATION_ENABLED_BY_DEFAULT];
					
				} else if ([name caseInsensitiveCompare:@"Notification-Icon"] == NSOrderedSame) {
					if ([value hasPrefix:@"x-growl-resource://"]) {
						/* Extract the resource ID from the value */
						[currentNotification setValue:[value substringFromIndex:[@"x-growl-resource://" length]]
											   forKey:GROWL_NOTIFICATION_ICON_ID];
						
					} else {
						/* If it's not an x-growl-resource, it must be a URL. If value isn't an URL, we'll be setting
						 * iconURL to nil as NSURL returns nil. That's fine fall-through behavior.
						 */
						[currentNotification setValue:[NSURL URLWithString:value]
											   forKey:GROWL_NOTIFICATION_ICON_URL];
					}
				}
			}	
			break;
		}
	}
	
	return directive;
}

#pragma mark -
/*!
 * @brief Return a Growl registration dictionary
 *
 * Dictionary format as per the documentation for GrowlApplicationBridgeDelegate_InformalProtocol's registrationDictionary
 * found in GrowlApplicationBridge.h.
 */
- (NSDictionary *)growlDictionary
{
	NSMutableDictionary *growlDictionary = [[[super growlDictionary] mutableCopy] autorelease];
	
	[growlDictionary addEntriesFromDictionary:registrationDict];
	[growlDictionary setValue:[self applicationIcon]
					   forKey:GROWL_APP_ICON];

	NSMutableArray *allNotifications = [NSMutableArray array];
	NSMutableArray *defaultNotifications = [NSMutableArray array];
	NSMutableDictionary *humanReadableNames = [NSMutableDictionary dictionary];
	
	NSEnumerator *enumerator = [notifications objectEnumerator];
	NSDictionary *notification;
	while ((notification = [enumerator nextObject])) {
		NSString *notificationName = [notification objectForKey:GROWL_NOTIFICATION_NAME];
		[allNotifications addObject:notificationName];

		if ([[notification objectForKey:GROWL_NOTIFICATION_ENABLED_BY_DEFAULT] boolValue])
			[defaultNotifications addObject:notificationName];
		
		[humanReadableNames setValue:[notification objectForKey:GROWL_NOTIFICATION_HUMAN_READABLE_NAME]
							  forKey:notificationName];

		/* XXX We aren't using GROWL_NOTIFICATION_ICON_ID / GROWL_NOTIFICATION_ICON_URL at all */
	}
	
	[growlDictionary setValue:allNotifications
					   forKey:GROWL_NOTIFICATIONS_ALL];
	[growlDictionary setValue:defaultNotifications
					   forKey:GROWL_NOTIFICATIONS_DEFAULT];
	[growlDictionary setValue:humanReadableNames
					   forKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	
	return growlDictionary;
}

+ (void)getHeaders:(NSArray **)outHeadersArray andBinaryChunks:(NSArray **)outBinaryChunks forRegistrationDict:(NSDictionary *)dict
{
	NSMutableArray *headersArray = [NSMutableArray array];
	NSMutableArray *binaryChunks = [NSMutableArray array];
	
	/* First build the application and number of notifications part */
	if ([dict objectForKey:GROWL_APP_NAME])
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Application-Name" value:[dict objectForKey:GROWL_APP_NAME]]];
	if ([dict objectForKey:GROWL_APP_ICON]) {
		NSData *iconData = [dict objectForKey:GROWL_APP_ICON];
		NSString *identifier = [GrowlGNTPBinaryChunk identifierForBinaryData:iconData];
		
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Application-Icon"
																		value:[NSString stringWithFormat:@"x-growl-resource://%@", identifier]]];
		[binaryChunks addObject:[GrowlGNTPBinaryChunk chunkForData:iconData withIdentifier:identifier]];
	}
	if ([dict objectForKey:GROWL_APP_ID])
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"X-Application-BundleID" value:[dict objectForKey:GROWL_APP_ID]]];
	
	NSArray *allNotifications = [dict objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications = [dict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	NSDictionary *humanReadableNames = [dict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notifications-Count"
																	value:[NSString stringWithFormat:@"%i", [allNotifications count]]]];
	
	/* Now add a section for each individual notification */
	NSString *notificationName;
	NSEnumerator *enumerator = [allNotifications objectEnumerator];
	while ((notificationName = [enumerator nextObject])) {
		[headersArray addObject:[GrowlGNTPHeaderItem separatorHeaderItem]];	
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Name"
																		value:notificationName]];
		if ([humanReadableNames objectForKey:notificationName])
			[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Display-Name"
																			value:[humanReadableNames objectForKey:notificationName]]];			
		
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Enabled"
																		value:([defaultNotifications containsObject:notificationName] ?
																			   @"Yes" :
																			   @"no")]];
		
		/* XXX Could include @"Notification-Icon" if we had per-notification icons */
	}
	
	[self addSentAndReceivedHeadersFromDict:dict toArray:headersArray];
		 
	if (outHeadersArray) *outHeadersArray = headersArray;
	if (outBinaryChunks) *outBinaryChunks = binaryChunks;
}

@end
