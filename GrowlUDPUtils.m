//
//  GrowlUDPUtils.m
//  Growl
//
//  Created by Ingmar Stein on 20.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlUDPUtils.h"
#import "GrowlDefines.h"
#include <openssl/md5.h>

@implementation GrowlUDPUtils
+ (char *) notificationToPacket:(NSDictionary *)aNotification password:(const char *)password packetSize:(unsigned int *)packetSize {
	MD5_CTX ctx;
	struct GrowlNetworkNotification *nn;
	char *data;
	unsigned length;
	unsigned short notificationNameLen, titleLen, descriptionLen, applicationNameLen;

	const char *notificationName = [[aNotification objectForKey:GROWL_NOTIFICATION_NAME] UTF8String];
	const char *applicationName = [[aNotification objectForKey:GROWL_APP_NAME] UTF8String];
	const char *title = [[aNotification objectForKey:GROWL_NOTIFICATION_TITLE] UTF8String];
	const char *description = [[aNotification objectForKey:GROWL_NOTIFICATION_DESCRIPTION] UTF8String];
	NSNumber *priority = [aNotification objectForKey:GROWL_NOTIFICATION_PRIORITY];
	NSNumber *isSticky = [aNotification objectForKey:GROWL_NOTIFICATION_STICKY];
	notificationNameLen = strlen( notificationName );
	applicationNameLen = strlen( applicationName );
	titleLen = strlen( title );
	descriptionLen = strlen( description );
	length = sizeof(*nn) + notificationNameLen + applicationNameLen + titleLen + descriptionLen + MD5_DIGEST_LENGTH;

	nn = (struct GrowlNetworkNotification *)malloc( length );
	nn->common.version = GROWL_PROTOCOL_VERSION;
	nn->common.type = GROWL_TYPE_NOTIFICATION;
	nn->flags.reserved = 0;
	nn->flags.priority = [priority intValue];
	nn->flags.sticky = [isSticky boolValue];
	nn->nameLen = htons( notificationNameLen );
	nn->titleLen = htons( titleLen );
	nn->descriptionLen = htons( descriptionLen );
	nn->appNameLen = htons( applicationNameLen );
	data = nn->data;
	memcpy( data, notificationName, notificationNameLen );
	data += notificationNameLen;
	memcpy( data, title, titleLen );
	data += titleLen;
	memcpy( data, description, descriptionLen );
	data += descriptionLen;
	memcpy( data, applicationName, applicationNameLen );
	data += applicationNameLen;

	// add checksum
	MD5_Init( &ctx );
	MD5_Update( &ctx, (const void *)nn, length-MD5_DIGEST_LENGTH );
	if ( password ) {
		MD5_Update( &ctx, password, strlen( password ) );
	}
	MD5_Final( data, &ctx );

	*packetSize = length;
	
	return (char *)nn;
}

+ (char *) registrationToPacket:(NSDictionary *)aNotification password:(const char *)password packetSize:(unsigned int *)packetSize {
	struct GrowlNetworkRegistration *nr;
	char *data;
	const char *notification;
	unsigned i, length, size, notificationIndex;
	unsigned short applicationNameLen;
	unsigned numAllNotifications, numDefaultNotifications;
	MD5_CTX ctx;
	
	const char *applicationName = [[aNotification objectForKey:GROWL_APP_NAME] UTF8String];
	NSArray *allNotifications = [aNotification objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications = [aNotification objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	applicationNameLen = strlen( applicationName );
	numAllNotifications = [allNotifications count];
	numDefaultNotifications = [defaultNotifications count];

	// compute packet size
	length = sizeof(*nr) + applicationNameLen + MD5_DIGEST_LENGTH;
	for ( i=0; i<numAllNotifications; ++i ) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		length += sizeof(unsigned short) + strlen( notification );
	}
	size = numDefaultNotifications;
	for ( i=0; i<numDefaultNotifications; ++i ) {
		notificationIndex = [allNotifications indexOfObject:[defaultNotifications objectAtIndex:i]];
		if( notificationIndex == NSNotFound ) {
			--size;
			NSLog( @"Warning: defaultNotifications is not a subset of allNotifications" );
		} else {
			++length;
		}
	}

	nr = (struct GrowlNetworkRegistration *)malloc( length );
	nr->common.version = GROWL_PROTOCOL_VERSION;
	nr->common.type = GROWL_TYPE_REGISTRATION;
	nr->appNameLen = htons( applicationNameLen );
	nr->numAllNotifications = (unsigned char)numAllNotifications;
	nr->numDefaultNotifications = (unsigned char)size;
	data = nr->data;
	memcpy( data, applicationName, applicationNameLen );
	data += applicationNameLen;
	for ( i=0; i<numAllNotifications; ++i ) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		size = strlen( notification );
		*(unsigned short *)data = htons( size );
		data += sizeof(unsigned short);
		memcpy( data, notification, size );
		data += size;
	}
	for ( i=0; i<numDefaultNotifications; ++i ) {
		notificationIndex = [allNotifications indexOfObject:[defaultNotifications objectAtIndex:i]];
		if( notificationIndex != NSNotFound ) {
			*data++ = notificationIndex;
		}
	}

	// add checksum
	MD5_Init( &ctx );
	MD5_Update( &ctx, (const void *)nr, length-MD5_DIGEST_LENGTH );
	if ( password ) {
		MD5_Update( &ctx, password, strlen( password ) );
	}
	MD5_Final( data, &ctx );

	*packetSize = length;
	
	return (char *)nr;
}
@end
