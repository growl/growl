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
	char *icon;
	unsigned int notificationNameLen, titleLen, descriptionLen, priority, applicationNameLen;
	unsigned int iconLen, length;
	BOOL isSticky;

	NSDictionary *userInfo = [aNotification userInfo];
	NSNumber *error = (NSNumber *)[userInfo objectForKey:@"NSFileHandleError"];
	
	if ( ![error intValue] ) {
		NSData *data = (NSData *)[userInfo objectForKey:@"NSFileHandleNotificationDataItem"];
		length = [data length];
		
		if ( length >= sizeof(struct GrowlNetworkPacket) ) {
			struct GrowlNetworkPacket *packet = (struct GrowlNetworkPacket *)[data bytes];
			
			switch( packet->type ) {
				case GROWL_TYPE_REGISTRATION:
					if ( length >= sizeof(struct GrowlNetworkRegistration) ) {
						BOOL enabled = [[[GrowlPreferences preferences] objectForKey:GrowlRemoteRegistrationKey] boolValue];
						
						if ( enabled ) {
							struct GrowlNetworkRegistration *nr = (struct GrowlNetworkRegistration *)packet;
							// TODO
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
						notificationNameLen = ntohl( nn->nameLen );
						title = notificationName + notificationNameLen;
						titleLen = ntohl( nn->titleLen );
						description = title + titleLen;
						descriptionLen = ntohl( nn->descriptionLen );
						applicationName = description + descriptionLen;
						applicationNameLen = ntohl( nn->appNameLen );
						icon = applicationName + applicationNameLen;
						iconLen = ntohl( nn->iconLen );
						// TODO: icon

						if ( length >= sizeof(struct GrowlNetworkNotification) + notificationNameLen
								+ titleLen + descriptionLen + applicationNameLen ) {
							NSDictionary *notificationInfo;
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
			NSLog( @"GrowlUDPServer: received runt packet." );
		}
	} else {
		NSLog( @"GrowlUDPServer: error %@.", error );
	}

	[fh readInBackgroundAndNotify];
}

@end
