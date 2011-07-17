//
//  GrowlApplicationBridgeNotificationAttempt.m
//  Growl
//
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridgeNotificationAttempt.h"

@implementation GrowlApplicationBridgeNotificationAttempt

+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeNotify;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSConnectionDidDieNotification
												  object:growlConnection];
	[growlConnection release];
	[growlProxy release];

	[super dealloc];
}

//When a connection dies, release our reference to its proxy
- (void) connectionDidDie:(NSNotification *)notification {
	if ([notification object] == growlConnection) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSConnectionDidDieNotification
													  object:growlConnection];
		[growlProxy release]; growlProxy = nil;
		[growlConnection release]; growlConnection = nil;
	}
}

- (NSProxy<GrowlNotificationProtocol> *) growlProxy {
	if (!growlProxy) {
		NSConnection *connection = [NSConnection connectionWithRegisteredName:@"GrowlApplicationBridgePathway" host:nil];
		if (connection) {
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(connectionDidDie:)
														 name:NSConnectionDidDieNotification
													   object:connection];
			
			@try {
				NSDistantObject *theProxy = [connection rootProxy];
				if ([theProxy respondsToSelector:@selector(registerApplicationWithDictionary:)]) {
					[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
					growlProxy = [(NSProxy<GrowlNotificationProtocol> *)theProxy retain];
					growlConnection = [connection retain];
				} else {
					NSLog(@"Received a fake GrowlApplicationBridgePathway object. Some other application is interfering with Growl, or something went horribly wrong. Please file a bug report.");
					growlProxy = nil;
				}
			}
			@catch(NSException *localException) {
				NSLog(@"GrowlApplicationBridge: exception while sending notification: %@", localException);
				growlProxy = nil;
			}
		}
	}
	
	return growlProxy;
}

#pragma mark -

- (void) begin {
	NSProxy<GrowlNotificationProtocol> *currentGrowlProxy = [self growlProxy];

	if (currentGrowlProxy) {
		//Post to Growl via GrowlApplicationBridgePathway
		@try {
			[currentGrowlProxy postNotificationWithDictionary:self.dictionary];
		}
		@catch(NSException *localException) {
			NSLog(@"GrowlApplicationBridge: exception while sending notification: %@", localException);
			[self failed];
		}
	}
}

@end
