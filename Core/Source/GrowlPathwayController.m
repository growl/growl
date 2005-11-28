//
//	GrowlPathwayController.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-08-08.
//	Copyright 2005 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details

#import "GrowlPathwayController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPluginController.h"

static GrowlPathwayController *sharedController;

@implementation GrowlPathwayController

+ (GrowlPathwayController *) sharedController {
	if (!sharedController)
		sharedController = [[GrowlPathwayController alloc] init];

	return sharedController;
}

- (id) init {
	if ((self = [super init])) {
		pathways = [[NSMutableSet alloc] initWithCapacity:4U];

		GrowlPathway *pw = [[GrowlDistributedNotificationPathway alloc] init];
		[self installPathway:pw];
		[pw release];

		[self installPathway:[GrowlApplicationBridgePathway standardPathway]];

		if (isGrowlServerEnabled)
			[self startServer];
	}

	return self;
}

- (void) dealloc {
	/*releasing pathways first, and setting it to nil, means that the
	 *	-removeObject: calls that we get to from -stopServer will be no-ops.
	 */
	[pathways release];
	 pathways = nil;

	[self stopServer];

	[super dealloc];
}

#pragma mark -
#pragma mark Adding and removing pathways

- (void) installPathway:(GrowlPathway *)newPathway {
	[pathways addObject:newPathway];
}

- (void) uninstallPathway:(GrowlPathway *)newPathway {
	[pathways removeObject:newPathway];
}

#pragma mark -
#pragma mark Remote pathways

- (void) netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
#pragma unused(sender)
	NSLog(@"WARNING: could not publish Growl service. Error: %@", errorDict);
}

- (BOOL) connection:(NSConnection *)ancestor shouldMakeNewConnection:(NSConnection *)conn {
	[conn setDelegate:[ancestor delegate]];
	return YES;
}

- (NSData *) authenticationDataForComponents:(NSArray *)components {
	return [authenticator authenticationDataForComponents:components];
}

- (BOOL) authenticateComponents:(NSArray *)components withData:(NSData *)signature {
	return [authenticator authenticateComponents:components withData:signature];
}

- (void) startServer {
	socketPort = [[NSSocketPort alloc] initWithTCPPort:GROWL_TCP_PORT];
	serverConnection = [[NSConnection alloc] initWithReceivePort:socketPort sendPort:nil];
	vendedPathway = [[GrowlRemotePathway alloc] init];
	[serverConnection setRootObject:server];
	[serverConnection setDelegate:self];

	// register with the default NSPortNameServer on the local host
	if (![serverConnection registerName:@"GrowlServer"])
		NSLog(@"WARNING: could not register Growl server.");

	[self installPathway:vendedPathway];

	// configure and publish the Bonjour service
	NSString *serviceName = (NSString *)SCDynamicStoreCopyComputerName(/*store*/ NULL,
																	   /*nameEncoding*/ NULL);
	service = [[NSNetService alloc] initWithDomain:@""	// use local registration domain
											  type:@"_growl._tcp."
											  name:serviceName
											  port:GROWL_TCP_PORT];
	[serviceName release];
	[service setDelegate:self];
	[service publish];

	// start UDP service
	UDPPathway = [[GrowlUDPPathway alloc] init];
	[self installPathway:UDPPathway];
}

- (void) stopServer {
	[pathways removeObject:UDPPathway];
	[UDPPathway        release];

	[pathways removeObject:vendedPathway];

	[serverConnection registerName:nil];	// unregister
	[serverConnection invalidate];
	[serverConnection release];

	[socketPort       invalidate];
	[socketPort       release];

	[server           release];

	[service          stop];
	[service          release];
	 service = nil;
}

- (void) startStopServer {
	BOOL enabled = [[GrowlPreferencesController sharedController] boolForKey:GrowlStartServerKey];

	// Setup notification server
	if (enabled && !service)
		[self startServer];
	else if (!enabled && service)
		[self stopServer];
}

@end
