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
#import "cdsa.h"
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include "sha2.h"

#ifndef SHA256_DIGEST_LENGTH
# define SHA256_DIGEST_LENGTH	32
#endif
#ifndef MD5_DIGEST_LENGTH
# define MD5_DIGEST_LENGTH		16
#endif

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
- (BOOL) authenticateWithCSSM:(const unsigned char *)packet length:(unsigned)length algorithm:(CSSM_ALGORITHMS)digestAlg digestLength:(unsigned)digestLength {
	unsigned char  *password;
	unsigned       messageLength;
	UInt32         passwordLength;
	OSStatus       status;
	CSSM_DATA      digestData;
	CSSM_RETURN    crtn;
	CSSM_CC_HANDLE ccHandle;
	CSSM_DATA      inData;

	crtn = CSSM_CSP_CreateDigestContext(cspHandle, digestAlg, &ccHandle);
	if (crtn) {
		return NO;
	}

	crtn = CSSM_DigestDataInit(ccHandle);
	if (crtn) {
		CSSM_DeleteContext(ccHandle);
		return NO;
	}

	messageLength = length - digestLength;
	inData.Data = (uint8 *)packet;
	inData.Length = messageLength;
	crtn = CSSM_DigestDataUpdate(ccHandle, &inData, 1U);
	if (crtn) {
		CSSM_DeleteContext(ccHandle);
		return NO;
	}
	
	status = SecKeychainFindGenericPassword(/*keychainOrArray*/ NULL,
											strlen(keychainServiceName), keychainServiceName,
											strlen(keychainAccountName), keychainAccountName,
											&passwordLength, (void **)&password, NULL);

	if (status == noErr) {
		inData.Length = passwordLength;
		inData.Data = password;
		crtn = CSSM_DigestDataUpdate(ccHandle, &inData, 1U);
		SecKeychainItemFreeContent(/*attrList*/ NULL, password);
		if (crtn) {
			CSSM_DeleteContext(ccHandle);
			return NO;
		}
	} else if (status != errSecItemNotFound) {
		NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
	}
	digestData.Data = NULL;
	digestData.Length = 0U;
	crtn = CSSM_DigestDataFinal(ccHandle, &digestData);
	CSSM_DeleteContext(ccHandle);
	if (crtn) {
		return NO;
	}

	BOOL authenticated;
	if (digestData.Length != digestLength) {
		NSLog(@"GrowlUDPPathway: digestData.Length != digestLength (%u != %u)", digestData.Length, digestLength);
		authenticated = NO;
	} else {
		authenticated = !memcmp(digestData.Data, packet+messageLength, digestData.Length);
	}
	free(digestData.Data);

	return authenticated;
}

- (BOOL) authenticatePacketMD5:(const unsigned char *)packet length:(unsigned)length {
	return [self authenticateWithCSSM:packet length:length algorithm:CSSM_ALGID_MD5 digestLength:MD5_DIGEST_LENGTH];
}

- (BOOL) authenticatePacketSHA256:(const unsigned char *)packet length:(unsigned)length {
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
	// CSSM_ALGID_SHA256 is only available on Mac OS X >= 10.4
	return [self authenticateWithCSSM:packet length:length algorithm:CSSM_ALGID_SHA256 digestLength:SHA256_DIGEST_LENGTH];
#else
	unsigned char *password;
	unsigned messageLength;
	UInt32 passwordLength;
	OSStatus status;
	SHA_CTX ctx;
	unsigned char digest[SHA256_DIGEST_LENGTH];

	messageLength = length-sizeof(digest);
	SHA256_Init(&ctx);
	SHA256_Update(&ctx, packet, messageLength);
	status = SecKeychainFindGenericPassword(/*keychainOrArray*/ NULL,
											strlen(keychainServiceName), keychainServiceName,
											strlen(keychainAccountName), keychainAccountName,
											&passwordLength, (void **)&password, NULL);

	if (status == noErr) {
		SHA256_Update(&ctx, password, passwordLength);
		SecKeychainItemFreeContent(/*attrList*/ NULL, password);
	} else if (status != errSecItemNotFound) {
		NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
	}
	SHA256_Final(digest, &ctx);

	return !memcmp(digest, packet+messageLength, sizeof(digest));
#endif
}

- (BOOL) authenticatePacketNONE:(const unsigned char *)packet length:(unsigned)length {
#pragma unused(packet,length)
	unsigned char *password;
	OSStatus status;
	UInt32 passwordLength = 0U;

	status = SecKeychainFindGenericPassword(/*keychainOrArray*/ NULL,
											strlen(keychainServiceName), keychainServiceName,
											strlen(keychainAccountName), keychainAccountName,
											&passwordLength, (void **)&password, NULL);

	if (status == noErr) {
		SecKeychainItemFreeContent(/*attrList*/ NULL, password);
	} else if (status != errSecItemNotFound) {
		NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
	}

	return !passwordLength;
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
	unsigned digestLength;
	int error;
	BOOL isSticky, authenticated;

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
					case GROWL_TYPE_REGISTRATION_SHA256:
					case GROWL_TYPE_REGISTRATION_NOAUTH:
						if (length >= sizeof(struct GrowlNetworkRegistration)) {
							BOOL enabled = [[GrowlPreferences preferences] boolForKey:GrowlRemoteRegistrationKey];

							if (enabled) {
								BOOL valid = YES;
								struct GrowlNetworkRegistration *nr = (struct GrowlNetworkRegistration *)packet;
								applicationName = (char *)nr->data;
								applicationNameLen = ntohs(nr->appNameLen);

								// check packet size
								switch (packet->type) {
									default:
									case GROWL_TYPE_REGISTRATION:
										digestLength = MD5_DIGEST_LENGTH;
										break;
									case GROWL_TYPE_REGISTRATION_SHA256:
										digestLength = SHA256_DIGEST_LENGTH;
										break;
									case GROWL_TYPE_REGISTRATION_NOAUTH:
										digestLength = 0U;
										break;
								}
								packetSize = sizeof(*nr) + nr->numDefaultNotifications + applicationNameLen + digestLength;
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

									switch (packet->type) {
										default:
										case GROWL_TYPE_REGISTRATION:
											authenticated = [self authenticatePacketMD5:(const unsigned char *)nr length:length];
											break;
										case GROWL_TYPE_REGISTRATION_SHA256:
											authenticated = [self authenticatePacketSHA256:(const unsigned char *)nr length:length];
											break;
										case GROWL_TYPE_REGISTRATION_NOAUTH:
											authenticated = [self authenticatePacketNONE:(const unsigned char *)nr length:length];
											break;
									}
									if (authenticated) {
										NSString *appName = [[NSString alloc] initWithUTF8String:applicationName length:applicationNameLen];
										NSDictionary *registerInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
											appName,              GROWL_APP_NAME,
											allNotifications,     GROWL_NOTIFICATIONS_ALL,
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
					case GROWL_TYPE_NOTIFICATION_SHA256:
					case GROWL_TYPE_NOTIFICATION_NOAUTH:
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
							switch (packet->type) {
								default:
								case GROWL_TYPE_NOTIFICATION:
									digestLength = MD5_DIGEST_LENGTH;
									break;
								case GROWL_TYPE_NOTIFICATION_SHA256:
									digestLength = SHA256_DIGEST_LENGTH;
									break;
								case GROWL_TYPE_NOTIFICATION_NOAUTH:
									digestLength = 0U;
									break;
							}
							packetSize = sizeof(*nn) + notificationNameLen + titleLen + descriptionLen + applicationNameLen + digestLength;

							if (length == packetSize) {
								switch (packet->type) {
									default:
									case GROWL_TYPE_NOTIFICATION:
										authenticated = [self authenticatePacketMD5:(const unsigned char *)nn length:length];
										break;
									case GROWL_TYPE_NOTIFICATION_SHA256:
										authenticated = [self authenticatePacketSHA256:(const unsigned char *)nn length:length];
										break;
									case GROWL_TYPE_NOTIFICATION_NOAUTH:
										authenticated = [self authenticatePacketNONE:(const unsigned char *)nn length:length];
										break;
								}
								if (authenticated) {
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
										notificationIcon,          GROWL_NOTIFICATION_ICON,
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
