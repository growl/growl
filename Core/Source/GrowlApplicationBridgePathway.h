//
//  GrowlApplicationBridgePathway.h
//  Growl
//
//  Created by Karl Adam on 3/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlPathway.h"

@interface GrowlApplicationBridgePathway : NSObject<GrowlPathway> {
	NSConnection *connection;
}

+ (GrowlApplicationBridgePathway *) standardPathway;

- (BOOL) registerApplicationWithDictionary:(bycopy NSDictionary *)dict;
- (oneway void) postNotificationWithDictionary:(bycopy NSDictionary *)notification;
- (bycopy NSString *) growlVersion;


@end
