//
//  GrowlUDPUtils.m
//  Growl
//
//  Created by Ingmar Stein on 20.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlUDPUtils.h"
#import "GrowlDefines.h"

@implementation GrowlUDPUtils
+ (char *) notificationToPacket:(NSDictionary *)aNotification packetSize:(unsigned int *)packetSize {
	struct GrowlNetworkNotification *nn;
	char *data;
	unsigned int length;
	unsigned int notificationNameLen, titleLen, descriptionLen, applicationNameLen, iconLen;
	
	const char *notificationName = [[aNotification objectForKey:GROWL_NOTIFICATION_NAME] UTF8String];
	const char *applicationName = [[aNotification objectForKey:GROWL_APP_NAME] UTF8String];
	const char *title = [[aNotification objectForKey:GROWL_NOTIFICATION_TITLE] UTF8String];
	const char *description = [[aNotification objectForKey:GROWL_NOTIFICATION_DESCRIPTION] UTF8String];
	NSNumber *priority = [aNotification objectForKey:GROWL_NOTIFICATION_PRIORITY];
	NSNumber *isSticky = [aNotification objectForKey:GROWL_NOTIFICATION_STICKY];
	NSData *icon = [aNotification objectForKey:GROWL_NOTIFICATION_ICON];
	// TODO: disable icon data as it results in packets that are too large
	icon = nil;
	notificationNameLen = strlen( notificationName );
	applicationNameLen = strlen( applicationName );
	titleLen = strlen( title );
	descriptionLen = strlen( description );
	iconLen = [icon length];
	length = sizeof(*nn) + notificationNameLen + applicationNameLen + titleLen + descriptionLen + iconLen;

	nn = (struct GrowlNetworkNotification *)malloc( length );
	nn->common.version = GROWL_PROTOCOL_VERSION;
	nn->common.type = GROWL_TYPE_NOTIFICATION;
	nn->flags.reserved = 0;
	nn->flags.priority = [priority intValue];
	nn->flags.sticky = [isSticky boolValue];
	nn->nameLen = htonl( notificationNameLen );
	nn->titleLen = htonl( titleLen );
	nn->descriptionLen = htonl( descriptionLen );
	nn->appNameLen = htonl( applicationNameLen );
	nn->iconLen = htonl( iconLen );
	data = nn->data;
	memcpy( data, notificationName, notificationNameLen );
	data += notificationNameLen;
	memcpy( data, title, titleLen );
	data += titleLen;
	memcpy( data, description, descriptionLen );
	data += descriptionLen;
	memcpy( data, applicationName, applicationNameLen );
	data += applicationNameLen;
	[icon getBytes:data];

	*packetSize = length;
	
	return (char *)nn;
}

+ (char *) registrationToPacket:(NSDictionary *)aNotification packetSize:(unsigned int *)packetSize {
	struct GrowlNetworkRegistration *nr;
	char *data;
	const char *notification;
	unsigned int i, length, size;
	unsigned int applicationNameLen;
	unsigned int numAllNotifications, numDefaultNotifications, iconLen;
	
	const char *applicationName = [[aNotification objectForKey:GROWL_APP_NAME] UTF8String];
	NSArray *allNotifications = [aNotification objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications = [aNotification objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	NSData *icon = [aNotification objectForKey:GROWL_APP_ICON];
	// TODO: disable icon data as it results in packets that are too large
	icon = nil;
	applicationNameLen = strlen( applicationName );
	numAllNotifications = [allNotifications count];
	numDefaultNotifications = [allNotifications count];
	iconLen = [icon length];

	// compute packet size
	length = sizeof(*nr) + applicationNameLen + iconLen;
	for ( i=0; i<numAllNotifications; ++i ) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		length += sizeof(unsigned int) + strlen( notification );
	}
	for ( i=0; i<numAllNotifications; ++i ) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		length += sizeof(unsigned int) + strlen( notification );
	}
	
	nr = (struct GrowlNetworkRegistration *)malloc( length );
	nr->common.version = GROWL_PROTOCOL_VERSION;
	nr->common.type = GROWL_TYPE_REGISTRATION;
	nr->appNameLen = htonl( applicationNameLen );
	nr->numAllNotifications = htonl( numAllNotifications );
	nr->numDefaultNotifications = htonl( numDefaultNotifications );
	nr->appIconLen = htonl( iconLen );
	data = nr->data;
	memcpy( data, applicationName, applicationNameLen );
	data += applicationNameLen;
	for ( i=0; i<numAllNotifications; ++i ) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		size = strlen( notification );
		*(unsigned int *)data = htonl( size );
		data += sizeof(unsigned int);
		memcpy( data, notification, size );
		data += size;
	}
	for ( i=0; i<numDefaultNotifications; ++i ) {
		notification = [[defaultNotifications objectAtIndex:i] UTF8String];
		size = strlen( notification );
		*(unsigned int *)data = htonl( size );
		data += sizeof(unsigned int);
		memcpy( data, notification, size );
		data += size;
	}
	[icon getBytes:data];
	
	*packetSize = length;
	
	return (char *)nr;
}
@end
