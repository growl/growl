//
//  GrowlUDPServer.m
//  Growl
//
//  Created by Ingmar Stein on 18.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlUDPServer.h"
#import "GrowlController.h"
#import "NSGrowlAdditions.h"
#import "GrowlDefines.h"
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>

@implementation GrowlUDPServer

- (id) init {
	struct sockaddr_in addr;
	NSData *addrData;
	
	if ( (self = [super init]) ) {
		addr.sin_addr.s_addr = INADDR_ANY;
		addr.sin_port = htons( GROWL_UDP_PORT );
		addr.sin_family = AF_INET;
		addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
		sock = [[NSSocketPort alloc] initWithProtocolFamily:AF_INET
												 socketType:SOCK_DGRAM
												   protocol:IPPROTO_UDP
													address:addrData];
		
		fh = [[NSFileHandle alloc] initWithFileDescriptor:[sock socket] closeOnDealloc:YES];
		[fh readInBackgroundAndNotify];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fileHandleRead:)
													 name:NSFileHandleReadCompletionNotification
												   object:fh];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadToEndOfFileCompletionNotification
												  object:nil];
	[fh release];
	[sock release];
}

#pragma mark -

- (void) fileHandleRead:(NSNotification *)aNotification {
	char *notificationName;
	char *title;
	char *description;
	char *applicationName;
	char *notification;
	char *password;
	unsigned int notificationNameLen, titleLen, descriptionLen, priority, applicationNameLen;
	unsigned int length, num, i, size, passwordLen;
	BOOL isSticky;

	NSDictionary *userInfo = [aNotification userInfo];
	NSNumber *error = (NSNumber *)[userInfo objectForKey:@"NSFileHandleError"];
	
	if ( ![error intValue] ) {
		NSData *data = (NSData *)[userInfo objectForKey:@"NSFileHandleNotificationDataItem"];
		length = [data length];

		if ( length >= sizeof(struct GrowlNetworkPacket) ) {
			struct GrowlNetworkPacket *packet = (struct GrowlNetworkPacket *)[data bytes];
			if( packet->version == GROWL_PROTOCOL_VERSION ) {
				switch( packet->type ) {
					case GROWL_TYPE_REGISTRATION:
						if ( length >= sizeof(struct GrowlNetworkRegistration) ) {
							BOOL enabled = [[[GrowlPreferences preferences] objectForKey:GrowlRemoteRegistrationKey] boolValue];

							if ( enabled ) {
								struct GrowlNetworkRegistration *nr = (struct GrowlNetworkRegistration *)packet;
								applicationName = nr->data;
								applicationNameLen = ntohs( nr->appNameLen );

								// all notifications
								num = nr->numAllNotifications;
								notification = applicationName + applicationNameLen;
								NSMutableArray *allNotifications = [[NSMutableArray alloc] initWithCapacity:num];
								for( i=0; i<num; ++i ) {
									size = ntohs( *(unsigned short *)notification );
									notification += sizeof(unsigned short);
									[allNotifications addObject:[NSString stringWithUTF8String:notification length:size]];
									notification += size;
								}

								// default notifications
								num = nr->numDefaultNotifications;
								NSMutableArray *defaultNotifications = [[NSMutableArray alloc] initWithCapacity:num];
								for( i=0; i<num; ++i ) {
									size = ntohs( *(unsigned short *)notification );
									notification += sizeof(unsigned short);
									[defaultNotifications addObject:[NSString stringWithUTF8String:notification length:size]];
									notification += size;
								}

								password = notification;
								passwordLen = ntohs( nr->common.passwordLen );
								NSData *remotePwd = [[GrowlPreferences preferences] objectForKey:GrowlRemotePasswordKey];
								NSData *pwdData = [[NSData alloc] initWithBytes:password length:passwordLen];
								if( !(remotePwd || passwordLen) || [pwdData isEqual:remotePwd] ) {
									// TODO: generic icon
									NSDictionary *registerInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSString stringWithUTF8String:applicationName length:applicationNameLen], GROWL_APP_NAME,
										allNotifications, GROWL_NOTIFICATIONS_ALL,
										defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
										nil];

									[[GrowlController singleton] _registerApplicationWithDictionary:registerInfo];
								} else {
									NSLog( @"GrowlUDPServer: invalid password" );
								}
								[pwdData release];
							}
						} else {
							NSLog( @"GrowlUDPServer: received runt registration packet." );
						}
						break;
					case GROWL_TYPE_NOTIFICATION:
						if ( length >= sizeof(struct GrowlNetworkNotification) ) {
							struct GrowlNetworkNotification *nn = (struct GrowlNetworkNotification *)packet;

							priority = nn->flags.priority;
							isSticky = nn->flags.sticky;
							notificationName = nn->data;
							notificationNameLen = ntohs( nn->nameLen );
							title = notificationName + notificationNameLen;
							titleLen = ntohs( nn->titleLen );
							description = title + titleLen;
							descriptionLen = ntohs( nn->descriptionLen );
							applicationName = description + descriptionLen;
							applicationNameLen = ntohs( nn->appNameLen );
							password = applicationName + applicationNameLen;
							passwordLen = ntohs( nn->common.passwordLen );

							if ( length == sizeof(struct GrowlNetworkNotification) + notificationNameLen
									+ titleLen + descriptionLen + applicationNameLen + passwordLen ) {
								NSData *remotePwd = [[GrowlPreferences preferences] objectForKey:GrowlRemotePasswordKey];
								NSData *pwdData = [[NSData alloc] initWithBytes:password length:passwordLen];
								if( !(remotePwd || passwordLen) || [pwdData isEqual:remotePwd] ) {
									NSDictionary *notificationInfo;
									// TODO: generic icon
									notificationInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSString stringWithUTF8String:notificationName length:notificationNameLen], GROWL_NOTIFICATION_NAME,
										[NSString stringWithUTF8String:applicationName length:applicationNameLen], GROWL_APP_NAME,
										[NSString stringWithUTF8String:title length:titleLen], GROWL_NOTIFICATION_TITLE,
										[NSString stringWithUTF8String:description length:descriptionLen], GROWL_NOTIFICATION_DESCRIPTION,
										[NSNumber numberWithInt:priority], GROWL_NOTIFICATION_PRIORITY,
										[NSNumber numberWithBool:isSticky], GROWL_NOTIFICATION_STICKY,
										nil];

									[[GrowlController singleton] dispatchNotificationWithDictionary:notificationInfo];
								} else {
									NSLog( @"GrowlUDPServer: invalid password" );
								}
								[pwdData release];
							} else {
								NSLog( @"GrowlUDPServer: received invalid notification packet." );
							}
						} else {
							NSLog( @"GrowlUDPServer: received runt notification packet." );
						}
						break;
					default:
						NSLog( @"GrowlUDPServer: received packet of invalid type." );
						break;
				}
			} else {
				NSLog( @"GrowlUDPServer: unknown version %d, expected %d", packet->version, GROWL_PROTOCOL_VERSION );
			}
		} else {
			NSLog( @"GrowlUDPServer: received runt packet." );
		}
	} else {
		NSLog( @"GrowlUDPServer: error %@.", error );
	}

	[fh readInBackgroundAndNotify];
}

@end
