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
// TODO: icon
+ (char *) notificationToPacket:(NSDictionary *)aNotification packetSize:(unsigned int *)packetSize {
	struct GrowlNetworkNotification *nn;
	char *data;
	unsigned int length;
	unsigned int notificationNameLen, titleLen, descriptionLen, applicationNameLen;
	
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
	length = sizeof(*nn) + notificationNameLen + applicationNameLen + titleLen + descriptionLen;
	
	nn = (struct GrowlNetworkNotification *)malloc( length );
	nn->common.type = htonl( GROWL_TYPE_NOTIFICATION );
	nn->flags.reserved = 0;
	nn->flags.hasIcon = 0;
	nn->flags.iconType = 0;
	nn->flags.priority = [priority intValue];
	nn->flags.sticky = [isSticky boolValue];
	nn->nameLen = htonl( notificationNameLen );
	nn->titleLen = htonl( titleLen );
	nn->descriptionLen = htonl( descriptionLen );
	nn->appNameLen = htonl( applicationNameLen );
	nn->iconLen = htonl( 0 );
	data = nn->data;
	memcpy( data, notificationName, notificationNameLen );
	data += notificationNameLen;
	memcpy( data, title, titleLen );
	data += titleLen;
	memcpy( data, description, descriptionLen );
	data += descriptionLen;
	memcpy( data, applicationName, applicationNameLen );
	data += applicationNameLen;
	
	*packetSize = length;
	
	return (char *)nn;
}

// TODO: icon
+ (char *) registrationToPacket:(NSDictionary *)aNotification packetSize:(unsigned int *)packetSize {
	struct GrowlNetworkRegistration *nr;
	char *data;
	const char *notification;
	unsigned int i, length, size;
	unsigned int applicationNameLen;
	unsigned int numAllNotifications, numDefaultNotifications;
	
	const char *applicationName = [[aNotification objectForKey:GROWL_APP_NAME] UTF8String];
	NSArray *allNotifications = [aNotification objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications = [aNotification objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	applicationNameLen = strlen( applicationName );
	numAllNotifications = [allNotifications count];
	numDefaultNotifications = [allNotifications count];

	// compute packet size
	length = sizeof(*nr) + applicationNameLen;
	for ( i=0; i<numAllNotifications; ++i ) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		length += sizeof(unsigned int) + strlen( notification );
	}
	for ( i=0; i<numAllNotifications; ++i ) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		length += sizeof(unsigned int) + strlen( notification );
	}
	
	nr = (struct GrowlNetworkRegistration *)malloc( length );
	nr->common.type = htonl( GROWL_TYPE_REGISTRATION );
	nr->flags.reserved = 0;
	nr->flags.hasIcon = 0;
	nr->appNameLen = htonl( applicationNameLen );
	nr->numAllNotifications = htonl( numAllNotifications );
	nr->numDefaultNotifications = htonl( numDefaultNotifications );
	nr->appIconLen = htonl( 0 );
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
	
	*packetSize = length;
	
	return (char *)nr;
}
@end
