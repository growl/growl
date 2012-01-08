//
//  GrowlApplicationBridgePathway.m
//  Growl
//
//  Created by Karl Adam on 3/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridgePathway.h"

#import "GrowlApplicationController.h"

static GrowlApplicationBridgePathway *theOneTrueGrowlApplicationBridgePathway;

@implementation GrowlApplicationBridgePathway

+ (GrowlApplicationBridgePathway *) standardPathway {
	if (!theOneTrueGrowlApplicationBridgePathway)
		theOneTrueGrowlApplicationBridgePathway = [[GrowlApplicationBridgePathway alloc] init];

	return theOneTrueGrowlApplicationBridgePathway;
}

- (id) init {
	if (theOneTrueGrowlApplicationBridgePathway) {
		[self release];
		return theOneTrueGrowlApplicationBridgePathway;
	}

	if ((self = [super init])) {


	}

	return self;
}

- (void) dealloc {
    [self closePathway];
	[super dealloc];
}


- (void) openPathway {
    //We create our own connection, rather than use defaultConnection, because an input manager such as the one in Logitech Control Center may also use defaultConnection, and would thereby steal it away from us.
    connection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
    [connection setRootObject:self];
    
    if (![connection registerName:@"GrowlApplicationBridgePathway"]) {
        NSLog(@"WARNING: Could not register connection for GrowlApplicationBridgePathway");
    }
    
    theOneTrueGrowlApplicationBridgePathway = self;
    
    //Watch a new run loop for incoming messages
    [connection runInNewThread];
    //Stop watching the current (main) run loop
    [connection removeRunLoop:[NSRunLoop currentRunLoop]];
}

- (void)closePathway {
    [connection release];
}

- (BOOL) registerApplicationWithDictionary:(bycopy NSDictionary *)dict {
    @autoreleasepool {
        [[GrowlApplicationController sharedController] performSelectorOnMainThread:@selector(registerApplicationWithDictionary:)
                                                                        withObject:dict
                                                                     waitUntilDone:NO];
    }
    return YES;
}

- (oneway void) postNotificationWithDictionary:(bycopy NSDictionary *)dict {
    @autoreleasepool {
        [[GrowlApplicationController sharedController] performSelectorOnMainThread:@selector(dispatchNotificationWithDictionary:)
                                                                        withObject:dict
                                                                     waitUntilDone:NO];
    }
}

- (bycopy NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}


@end
