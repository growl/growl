//
//  GrowlRegisterGNTPPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import "GrowlRegisterGNTPPacket.h"
#import "GrowlGNTPHeaderItem.h"
#import "GrowlGNTPBinaryChunk.h"
#import "NSStringAdditions.h"
#import "GrowlDefines.h"
#import "GrowlImageAdditions.h"

#define GROWL_NOTIFICATION_HUMAN_READABLE_NAME		@"HumanReadableName"
#define GROWL_NOTIFICATION_ENABLED_BY_DEFAULT		@"EnabledByDefault"

#define GROWL_NOTIFICATION_ICON_ID					@"NotificationIconID"
#define GROWL_NOTIFICATION_ICON_URL					@"NotificationIconURL"

/*
 * XXX Growl doesn't currently have a per-notification icon mechanism which can be 'registered'
 */
@implementation GrowlRegisterGNTPPacket

@synthesize applicationIconURL = mApplicationIconURL;

- (id)init
{
	if ((self = [super init])) {
		registrationDict = [[NSMutableDictionary alloc] init];
		notifications = [[NSMutableArray alloc] init];
		numberOfNotifications = -1;
	}
	
	return self;
}

- (void)dealloc
{
	[registrationDict release];
	[notifications release];
	[currentNotification release];
	
	[applicationIconID release];
	[mApplicationIconURL release];
	
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
	
	if (!pendingBinaryIdentifiers) pendingBinaryIdentifiers = [[NSMutableSet alloc] init];
	[pendingBinaryIdentifiers addObject:applicationIconID];
}
- (NSString *)applicationIconID
{
	return applicationIconID;
}
- (void)setApplicationIconURL:(NSURL *)url
{
	[mApplicationIconURL autorelease];
	mApplicationIconURL = [url retain];
	
	/* XXX Start loading the URL in the background? */
}

- (NSURL *)applicationIconURL
{
	return mApplicationIconURL;
}

- (NSData *)applicationIconData
{
	NSData *data = nil;
	if (applicationIconID) {
		data = [binaryDataByIdentifier objectForKey:applicationIconID];
	} else if (mApplicationIconURL) {
		/* XXX Blocking */
		data = [NSData dataWithContentsOfURL:mApplicationIconURL];
	} else {
      data = [[NSImage imageNamed:NSImageNameNetwork] PNGRepresentation];
   }

	return data;
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
		[currentNotification setValue:[currentNotification valueForKey:GROWL_NOTIFICATION_NAME] forKey:GROWL_NOTIFICATION_HUMAN_READABLE_NAME];

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
				} else if (numberOfNotifications == -1) {
					errorString = @"Notifications-Count	is a required header for registration";
				}

				if (errorString) {
					[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
													   code:GrowlGNTPRegistrationPacketError
												   userInfo:[NSDictionary dictionaryWithObject:errorString
																						forKey:NSLocalizedFailureReasonErrorKey]]];
					directive = GrowlReadDirective_Error;
				} else {
					if (numberOfNotifications > 0) {
						/* Prepare to start tracking notifications */
						currentNotification = [[NSMutableDictionary alloc] init];
					} else {
						/* Unless we registered 0 notifications */
						if ([pendingBinaryIdentifiers count] == 0)
							directive = GrowlReadDirective_PacketComplete;
						else
							directive = GrowlReadDirective_SectionComplete;
					}
				}
			} else {
				/* Process a registration header */
				if ([name caseInsensitiveCompare:@"Application-Name"] == NSOrderedSame) {
					[self setApplicationName:value];
				} else if ([name caseInsensitiveCompare:@"Application-Icon"] == NSOrderedSame) {
					if ([value rangeOfString:@"x-growl-resource://" options:(NSLiteralSearch | NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound) {
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
				} else if ([name rangeOfString:@"X-" options:(NSLiteralSearch | NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound) {
					[self addCustomHeader:headerItem];
				}
			}
			break;
		}
		case GrowlRegisterStepNotification:
		{
			/* Process a header for a specific notification */
			if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
				/* Done with this notification; start working on the next or on binary data if needed */
				NSError *anError = nil;
				if ([self validateCurrentNotification:&anError]) {
					[notifications addObject:currentNotification];
					[currentNotification release]; currentNotification = nil;

					if ((int)[notifications count] == numberOfNotifications) {
						if ([pendingBinaryIdentifiers count] == 0)
							directive = GrowlReadDirective_PacketComplete;
						else
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
					if ([value rangeOfString:@"x-growl-resource://" options:(NSLiteralSearch | NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound) {
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
	[growlDictionary setValue:[self applicationIconData]
					   forKey:GROWL_APP_ICON_DATA];

	NSMutableArray *allNotifications = [NSMutableArray array];
	NSMutableArray *defaultNotifications = [NSMutableArray array];
	NSMutableDictionary *humanReadableNames = [NSMutableDictionary dictionary];
	
	for (NSDictionary *notification in notifications) {
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
	[growlDictionary setValue:host
					   forKey:GROWL_UDP_REMOTE_ADDRESS];
	
	return growlDictionary;
}

+ (void)getHeaders:(NSArray **)outHeadersArray andBinaryChunks:(NSArray **)outBinaryChunks forRegistrationDict:(NSDictionary *)dict
{
	NSMutableArray *headersArray = [NSMutableArray array];
	NSMutableArray *binaryChunks = [NSMutableArray array];
	
	/* First build the application and number of notifications part */
	if ([dict objectForKey:GROWL_APP_NAME])
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Application-Name" value:[dict objectForKey:GROWL_APP_NAME]]];
	if ([dict objectForKey:GROWL_APP_ICON_DATA]) {
		NSData *iconData = [dict objectForKey:GROWL_APP_ICON_DATA];
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
	[self addSentAndReceivedHeadersFromDict:dict toArray:headersArray];

	/* Now add a section for each individual notification */
	for (NSString *notificationName in allNotifications) {
		[headersArray addObject:[GrowlGNTPHeaderItem separatorHeaderItem]];	
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Name"
																		value:notificationName]];
		if ([humanReadableNames objectForKey:notificationName]) {
			[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Display-Name"
																			value:[humanReadableNames objectForKey:notificationName]]];			
		} else {
			[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Display-Name"
                                                                   value:notificationName]];			
		}
      
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Enabled"
																		value:([defaultNotifications containsObject:notificationName] ?
																			   @"Yes" :
																			   @"no")]];
		
		/* XXX Could include @"Notification-Icon" if we had per-notification icons */
	}
		 
	if (outHeadersArray) *outHeadersArray = headersArray;
	if (outBinaryChunks) *outBinaryChunks = binaryChunks;
}

@end
