//
//  GrowlRendezvousDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlRendezvousDisplay.h"
#import "GrowlRendezvousPrefs.h"
#import "GrowlRendezvousDefines.h"
#import <GrowlNotificationServer.h>
#import <GrowlDefines.h>
#import <sys/socket.h>

static NSString *author = @"Ingmar Stein";
static NSString *name = @"Rendezvous";
static NSString *version = @"0.6";
static NSString *description = @"Send notifications to another Mac on the local network";

@implementation GrowlRendezvousDisplay
- (id)init {
	if( (self = [super init] ) ) {
		prefPane = [[GrowlRendezvousPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlRendezvousPrefs class]]];
	}
	return self;
}

- (void)dealloc {
	[prefPane release];
	[super dealloc];
}

- (NSString *)author
{
	return( author );
}

- (NSString *)name
{
	return( name );
}

- (NSString *)userDescription
{
	return( description );
}

- (NSString *)version
{
	return( version );
}

- (NSDictionary *)pluginInfo
{
	return( [NSDictionary dictionaryWithObjectsAndKeys:
		name,        @"Name",
		author,      @"Author",
		version,     @"Version",
		description, @"Description",
		nil] );
}

- (NSPreferencePane *)preferencePane
{
	return( prefPane );
}

- (void)loadPlugin
{
}

- (void)unloadPlugin
{
}

- (void)displayNotificationWithInfo:(NSDictionary *)noteDict
{
	NSData *destAddress;

	READ_GROWL_PREF_VALUE(GrowlRendezvousRecipientPref, GrowlRendezvousPrefDomain, NSData *, &destAddress);

	NSSocketPort *serverPort = [[NSSocketPort alloc]
        initRemoteWithProtocolFamily:AF_INET
						  socketType:SOCK_STREAM
							protocol:0
							 address:destAddress];

	NSConnection *connection = [[NSConnection alloc] initWithReceivePort:nil sendPort:serverPort];
	NSDistantObject *theProxy = [connection rootProxy];
	[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
	id<GrowlNotificationProtocol> growlProxy = (id)theProxy;
	[growlProxy postNotification:noteDict];
	[serverPort release];
	[connection release];
}
@end
