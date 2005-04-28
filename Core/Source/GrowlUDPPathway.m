//
//  GrowlUDPServer.m
//  Growl
//
//  Created by Ingmar Stein on 18.11.04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlUDPPathway.h"
#import "NSGrowlAdditions.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlPreferences.h"
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <openssl/md5.h>

#define keychainServiceName "Growl"
#define keychainAccountName "Growl"

@implementation GrowlUDPPathway

- (id) init {
	struct sockaddr_in addr;
	NSData *addrData;

	if ((self = [super init])) {
		short port = [[GrowlPreferences preferences] integerForKey:GrowlUDPPortKey];
		addr.sin_len = sizeof(addr);
		addr.sin_family = AF_INET;
		addr.sin_port = htons(port);
		addr.sin_addr.s_addr = INADDR_ANY;
		memset(&addr.sin_zero, 0, sizeof(addr.sin_zero));
		addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
		sock = [[NSSocketPort alloc] initWithProtocolFamily:AF_INET
												 socketType:SOCK_DGRAM
												   protocol:IPPROTO_UDP
													address:addrData];

		if (!sock) {
			NSLog(@"GrowlUDPPathway: could not create socket.");
			[self release];
			return nil;
		}

		fh = [[NSFileHandle alloc] initWithFileDescriptor:[sock socket]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fileHandleRead:)
													 name:NSFileHandleReadCompletionNotification
												   object:fh];
		[fh readInBackgroundAndNotify];
		notificationIcon = [[NSImage alloc] initWithContentsOfFile:
			@"/System/Library/CoreServices/SystemIcons.bundle/Contents/Resources/GenericNetworkIcon.icns"];
		if (!notificationIcon) {
			// the icon has moved on 10.4
			notificationIcon = [[NSImage alloc] initWithContentsOfFile:
				@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericNetworkIcon.icns"];
		}
	}

	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadCompletionNotification
												  object:nil];
	[notificationIcon release];
	[fh release];
	[sock release];

	[super dealloc];
}

#pragma mark -

+ (BOOL) authenticatePacket:(const unsigned char *)packet length:(unsigned)length {
	char *password;
	unsigned messageLength;
	UInt32 passwordLength;
	OSStatus status;
	MD5_CTX ctx;
	unsigned char digest[MD5_DIGEST_LENGTH];

	messageLength = length-MD5_DIGEST_LENGTH;
	MD5_Init(&ctx);
	MD5_Update(&ctx, packet, messageLength);
	status = SecKeychainFindGenericPassword(/*keychainOrArray*/ NULL,
											strlen(keychainServiceName), keychainServiceName,
											strlen(keychainAccountName), keychainAccountName,
											&passwordLength, (void **)&password, NULL);

	if (status == noErr) {
		MD5_Update(&ctx, password, passwordLength);
		SecKeychainItemFreeContent(/*attrList*/ NULL, password);
	} else if (status != errSecItemNotFound) {
		NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
	}
	MD5_Final(digest, &ctx);

	return !memcmp(digest, packet+messageLength, sizeof(digest));
}

#pragma mark -

- (void) fileHandleRead:(NSNotification *)aNotification {
	char *notificationName;
	char *title;
	char *description;
	char *applicationName;
	char *notification;
	unsigned notificationNameLen, titleLen, descriptionLen, priority, applicationNameLen;
	unsigned length, num, i, size, packetSize, notificationIndex;
	int error;
	BOOL isSticky;

	NSDictionary *userInfo = [aNotification userInfo];
	error = [[userInfo objectForKey:@"NSFileHandleError"] intValue];

	if (!error) {
		NSData *data = [userInfo objectForKey:NSFileHandleNotificationDataItem];
		length = [data length];

		if (length >= sizeof(struct GrowlNetworkPacket)) {
			struct GrowlNetworkPacket *packet = (struct GrowlNetworkPacket *)[data bytes];

			if (packet->version == GROWL_PROTOCOL_VERSION) {
				switch (packet->type) {
					case GROWL_TYPE_REGISTRATION:
						if (length >= sizeof(struct GrowlNetworkRegistration)) {
							BOOL enabled = [[GrowlPreferences preferences] boolForKey:GrowlRemoteRegistrationKey];

							if (enabled) {
								BOOL valid = YES;
								struct GrowlNetworkRegistration *nr = (struct GrowlNetworkRegistration *)packet;
								applicationName = (char *)nr->data;
								applicationNameLen = ntohs(nr->appNameLen);

								// check packet size
								packetSize = sizeof(*nr) + nr->numDefaultNotifications + applicationNameLen + MD5_DIGEST_LENGTH;
								if (packetSize > length) {
									valid = NO;
								} else {
									num = nr->numAllNotifications;
									notification = applicationName + applicationNameLen;
									for (i = 0U; i < num; ++i) {
										if (packetSize >= length) {
											valid = NO;
											break;
										}
										size = ntohs(*(unsigned short *)notification) + sizeof(unsigned short);
										notification += size;
										packetSize += size;
									}
									if (packetSize != length) {
										valid = NO;
									}
								}

								if (valid) {
									// all notifications
									num = nr->numAllNotifications;
									notification = applicationName + applicationNameLen;
									NSMutableArray *allNotifications = [[NSMutableArray alloc] initWithCapacity:num];
									for (i = 0U; i < num; ++i) {
										size = ntohs(*(unsigned short *)notification);
										notification += sizeof(unsigned short);
										NSString *n = [[NSString alloc] initWithUTF8String:notification length:size];
										[allNotifications addObject:n];
										[n release];
										notification += size;
									}

									// default notifications
									num = nr->numDefaultNotifications;
									NSMutableArray *defaultNotifications = [[NSMutableArray alloc] initWithCapacity:num];
									for (i = 0U; i < num; ++i) {
										notificationIndex = *notification++;
										if (notificationIndex < nr->numAllNotifications) {
											[defaultNotifications addObject:[allNotifications objectAtIndex: notificationIndex]];
										} else {
											NSLog(@"GrowlUDPServer: Bad notification index: %u", notificationIndex);
										}
									}

									if ([GrowlUDPPathway authenticatePacket:(const unsigned char *)nr length:length]) {
										NSString *appName = [[NSString alloc] initWithUTF8String:applicationName length:applicationNameLen];
										NSDictionary *registerInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
											appName, GROWL_APP_NAME,
											allNotifications, GROWL_NOTIFICATIONS_ALL,
											defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
											nil];
										[appName release];
										[self registerApplicationWithDictionary:registerInfo];
										[registerInfo release];
									} else {
										NSLog(@"GrowlUDPServer: authentication failed.");
									}

									[allNotifications     release];
									[defaultNotifications release];
								} else {
									NSLog(@"GrowlUDPServer: received invalid registration packet.");
								}
							}
						} else {
							NSLog(@"GrowlUDPServer: received runt registration packet.");
						}
						break;
					case GROWL_TYPE_NOTIFICATION:
						if (length >= sizeof(struct GrowlNetworkNotification)) {
							struct GrowlNetworkNotification *nn = (struct GrowlNetworkNotification *)packet;

							priority = nn->flags.priority;
							isSticky = nn->flags.sticky;
							notificationName = (char *)nn->data;
							notificationNameLen = ntohs(nn->nameLen);
							title = notificationName + notificationNameLen;
							titleLen = ntohs(nn->titleLen);
							description = title + titleLen;
							descriptionLen = ntohs(nn->descriptionLen);
							applicationName = description + descriptionLen;
							applicationNameLen = ntohs(nn->appNameLen);
							packetSize = sizeof(*nn) + notificationNameLen + titleLen + descriptionLen + applicationNameLen + MD5_DIGEST_LENGTH;

							if (length == packetSize) {
								if ([GrowlUDPPathway authenticatePacket:(const unsigned char *)nn length:length]) {
									NSString *growlNotificationName = [[NSString alloc] initWithUTF8String:notificationName length:notificationNameLen];
									NSString *growlAppName = [[NSString alloc] initWithUTF8String:applicationName length:applicationNameLen];
									NSString *growlNotificationTitle = [[NSString alloc] initWithUTF8String:title length:titleLen];
									NSString *growlNotificationDesc = [[NSString alloc] initWithUTF8String:description length:descriptionLen];
									NSNumber *growlNotificationPriority = [[NSNumber alloc] initWithInt:priority];
									NSNumber *growlNotificationSticky = [[NSNumber alloc] initWithBool:isSticky];
									NSDictionary *notificationInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
										growlNotificationName,     GROWL_NOTIFICATION_NAME,
										growlAppName,              GROWL_APP_NAME,
										growlNotificationTitle,    GROWL_NOTIFICATION_TITLE,
										growlNotificationDesc,     GROWL_NOTIFICATION_DESCRIPTION,
										growlNotificationPriority, GROWL_NOTIFICATION_PRIORITY,
										growlNotificationSticky,   GROWL_NOTIFICATION_STICKY,
										[notificationIcon TIFFRepresentation], GROWL_NOTIFICATION_ICON,
										nil];
									[growlNotificationName     release];
									[growlAppName              release];
									[growlNotificationTitle    release];
									[growlNotificationDesc     release];
									[growlNotificationPriority release];
									[growlNotificationSticky   release];
									[self postNotificationWithDictionary:notificationInfo];
									[notificationInfo release];
								} else {
									NSLog(@"GrowlUDPServer: authentication failed.");
								}
							} else {
								NSLog(@"GrowlUDPServer: received invalid notification packet.");
							}
						} else {
							NSLog(@"GrowlUDPServer: received runt notification packet.");
						}
						break;
					default:
						NSLog(@"GrowlUDPServer: received packet of invalid type.");
						break;
				}
			} else {
				NSLog(@"GrowlUDPServer: unknown version %u, expected %d", packet->version, GROWL_PROTOCOL_VERSION);
			}
		} else {
			NSLog(@"GrowlUDPServer: received runt packet.");
		}
	} else {
		NSLog(@"GrowlUDPServer: error %d.", error);
	}

	[fh readInBackgroundAndNotify];
}

@end
