//
//  GrowlApplicationBridgePathway.h
//  Growl
//
//  Created by Karl Adam on 3/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlPathway.h"

@interface GrowlApplicationBridgePathway : GrowlPathway {
	NSConnection *connection;
}

+ (GrowlApplicationBridgePathway *) standardPathway;

@end
