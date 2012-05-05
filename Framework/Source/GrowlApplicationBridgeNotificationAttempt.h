//
//  GrowlApplicationBridgeNotificationAttempt.h
//  Growl
//
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlCommunicationAttempt.h"

#import "GrowlPathway.h"

@interface GrowlApplicationBridgeNotificationAttempt : GrowlCommunicationAttempt
{
	NSConnection *growlConnection;
	NSProxy<GrowlNotificationProtocol> *growlProxy;
}

@end
