//
//  GrowlUDPUtils.m
//  Growl
//
//  Created by Ingmar Stein on 20.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlUDPUtils.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#include <openssl/md5.h>
#include "sha2.h"

@implementation GrowlUDPUtils
+ (unsigned char *) notificationToPacket:(NSDictionary *)aNotification digest:(enum GrowlAuthenticationMethod)authMethod password:(const char *)password packetSize:(unsigned int *)packetSize {
	MD5_CTX md5_ctx;
	SHA_CTX sha_ctx;
	struct GrowlNetworkNotification *nn;
	unsigned char *data;
	size_t length;
	unsigned short notificationNameLen, titleLen, descriptionLen, applicationNameLen;
	unsigned int digestLength;

	const char *notificationName = [[aNotification objectForKey:GROWL_NOTIFICATION_NAME] UTF8String];
	const char *applicationName  = [[aNotification objectForKey:GROWL_APP_NAME] UTF8String];
	const char *title            = [[aNotification objectForKey:GROWL_NOTIFICATION_TITLE] UTF8String];
	const char *description      = [[aNotification objectForKey:GROWL_NOTIFICATION_DESCRIPTION] UTF8String];
	notificationNameLen = strlen(notificationName);
	applicationNameLen  = strlen(applicationName);
	titleLen            = strlen(title);
	descriptionLen      = strlen(description);

	NSNumber *priority = [aNotification objectForKey:GROWL_NOTIFICATION_PRIORITY];
	NSNumber *isSticky = [aNotification objectForKey:GROWL_NOTIFICATION_STICKY];

	switch (authMethod) {
		case GROWL_AUTH_NONE:
			digestLength = 0U;
			break;
		default:
		case GROWL_AUTH_MD5:
			digestLength = MD5_DIGEST_LENGTH;
			break;
		case GROWL_AUTH_SHA256:
			digestLength = SHA256_DIGEST_LENGTH;
			break;
	}
	length = sizeof(*nn) + notificationNameLen + applicationNameLen + titleLen + descriptionLen + digestLength;

	nn = (struct GrowlNetworkNotification *)malloc(length);
	nn->common.version = GROWL_PROTOCOL_VERSION;
	switch (authMethod) {
		default:
		case GROWL_AUTH_MD5:
			nn->common.type     = GROWL_TYPE_NOTIFICATION;
			break;
		case GROWL_AUTH_SHA256:
			nn->common.type     = GROWL_TYPE_NOTIFICATION_SHA256;
			break;
		case GROWL_AUTH_NONE:
			nn->common.type     = GROWL_TYPE_NOTIFICATION_NOAUTH;
			break;
	}
	nn->flags.reserved = 0;
	nn->flags.priority = [priority intValue];
	nn->flags.sticky   = [isSticky boolValue];
	nn->nameLen        = htons(notificationNameLen);
	nn->titleLen       = htons(titleLen);
	nn->descriptionLen = htons(descriptionLen);
	nn->appNameLen     = htons(applicationNameLen);
	data = nn->data;
	memcpy(data, notificationName, notificationNameLen);
	data += notificationNameLen;
	memcpy(data, title, titleLen);
	data += titleLen;
	memcpy(data, description, descriptionLen);
	data += descriptionLen;
	memcpy(data, applicationName, applicationNameLen);
	data += applicationNameLen;

	// add checksum
	switch (authMethod) {
		default:
		case GROWL_AUTH_MD5:
			MD5_Init(&md5_ctx);
			MD5_Update(&md5_ctx, (const void *)nn, length-MD5_DIGEST_LENGTH);
			if (password) {
				MD5_Update(&md5_ctx, password, strlen(password));
			}
			MD5_Final(data, &md5_ctx);
			break;
		case GROWL_AUTH_SHA256:
			SHA256_Init(&sha_ctx);
			SHA256_Update(&sha_ctx, (const void *)nn, length-SHA256_DIGEST_LENGTH);
			if (password) {
				SHA256_Update(&sha_ctx, (const unsigned char *)password, strlen(password));
			}
			SHA256_Final(data, &sha_ctx);
			break;
		case GROWL_AUTH_NONE:
			break;
	}

	*packetSize = length;

	return (unsigned char *)nn;
}

#warning we need a way to handle the unlikely but fully-possible case wherein the dictionary contains more All notifications than the 8-bit Default indices can hold (Zero-One-Infinity) - first stage would be to try moving all the default notifications to the lower indices of the All array, second stage would be to create multiple packets

+ (unsigned char *) registrationToPacket:(NSDictionary *)aNotification digest:(enum GrowlAuthenticationMethod)authMethod password:(const char *)password packetSize:(unsigned int *)packetSize {
	struct GrowlNetworkRegistration *nr;
	unsigned char *data;
	const char *notification;
	unsigned i, size, notificationIndex, digestLength;
	size_t length;
	unsigned short applicationNameLen;
	unsigned numAllNotifications, numDefaultNotifications;
	MD5_CTX md5_ctx;
	SHA_CTX sha_ctx;
	Class NSNumberClass = [NSNumber class];

	const char *applicationName   = [[aNotification objectForKey:GROWL_APP_NAME] UTF8String];
	NSArray *allNotifications     = [aNotification objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications = [aNotification objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	applicationNameLen            = strlen(applicationName);
	numAllNotifications           = [allNotifications count];
	numDefaultNotifications       = [defaultNotifications count];

	// compute packet size
	switch (authMethod) {
		case GROWL_AUTH_NONE:
			digestLength = 0U;
			break;
		default:
		case GROWL_AUTH_MD5:
			digestLength = MD5_DIGEST_LENGTH;
			break;
		case GROWL_AUTH_SHA256:
			digestLength = SHA256_DIGEST_LENGTH;
			break;
	}
	length = sizeof(*nr) + applicationNameLen + digestLength;
	for (i = 0; i < numAllNotifications; ++i) {
		notification  = [[allNotifications objectAtIndex:i] UTF8String];
		length       += sizeof(unsigned short) + strlen(notification);
	}
	size = numDefaultNotifications;
	for (i = 0; i < numDefaultNotifications; ++i) {
		NSNumber *num = [defaultNotifications objectAtIndex:i];
		if ([num isKindOfClass:NSNumberClass]) {
			notificationIndex = [num unsignedIntValue];
			if (notificationIndex >= numAllNotifications) {
				NSLog(@"Warning: index %u found in defaultNotifications is not within the range (%u) of the notifications array", notificationIndex, numAllNotifications);
				--size;
			} else if (notificationIndex > UCHAR_MAX) {
				NSLog(@"Warning: index %u found in defaultNotifications is not within the range (%u) of an 8-bit unsigned number", notificationIndex);
				--size;
			} else {
				++length;
			}
		} else {
			notificationIndex = [allNotifications indexOfObject:num];
			if (notificationIndex == NSNotFound) {
				NSLog(@"Warning: defaultNotifications is not a subset of allNotifications (object found in defaultNotifications that is not in allNotifications; description of object is %@)", num);
				--size;
			} else {
				++length;
			}
		}
	}

	nr = (struct GrowlNetworkRegistration *)malloc(length);
	nr->common.version          = GROWL_PROTOCOL_VERSION;
	switch (authMethod) {
		default:
		case GROWL_AUTH_MD5:
			nr->common.type     = GROWL_TYPE_REGISTRATION;
			break;
		case GROWL_AUTH_SHA256:
			nr->common.type     = GROWL_TYPE_REGISTRATION_SHA256;
			break;
		case GROWL_AUTH_NONE:
			nr->common.type     = GROWL_TYPE_REGISTRATION_NOAUTH;
			break;
	}
	nr->appNameLen              = htons(applicationNameLen);
	nr->numAllNotifications     = (unsigned char)numAllNotifications;
	nr->numDefaultNotifications = (unsigned char)size;
	data = nr->data;
	memcpy(data, applicationName, applicationNameLen);
	data += applicationNameLen;
	for (i = 0; i < numAllNotifications; ++i) {
		notification = [[allNotifications objectAtIndex:i] UTF8String];
		size = strlen(notification);
		*(unsigned short *)data = htons(size);
		data += sizeof(unsigned short);
		memcpy(data, notification, size);
		data += size;
	}
	for (i = 0; i < numDefaultNotifications; ++i) {
		NSNumber *num = [defaultNotifications objectAtIndex:i];
		if ([num isKindOfClass:NSNumberClass]) {
			notificationIndex = [num unsignedIntValue];
			if ((notificationIndex <  numAllNotifications)
			&& (notificationIndex <= UCHAR_MAX)) {
				*data++ = notificationIndex;
			}
		} else {
			notificationIndex = [allNotifications indexOfObject:num];
			if ((notificationIndex <  numAllNotifications)
			&& (notificationIndex <= UCHAR_MAX)
			&& (notificationIndex != NSNotFound)) {
				*data++ = notificationIndex;
			}
		}
	}

	// add checksum
	switch (authMethod) {
		default:
		case GROWL_AUTH_MD5:
			MD5_Init(&md5_ctx);
			MD5_Update(&md5_ctx, (const void *)nr, length-MD5_DIGEST_LENGTH);
			if (password) {
				MD5_Update(&md5_ctx, password, strlen(password));
			}
			MD5_Final(data, &md5_ctx);
			break;
		case GROWL_AUTH_SHA256:
			SHA256_Init(&sha_ctx);
			SHA256_Update(&sha_ctx, (const void *)nr, length-SHA256_DIGEST_LENGTH);
			if (password) {
				SHA256_Update(&sha_ctx, (const unsigned char *)password, strlen(password));
			}
			SHA256_Final(data, &sha_ctx);
			break;
		case GROWL_AUTH_NONE:
			break;
	}

	*packetSize = length;

	return (unsigned char *)nr;
}
@end
