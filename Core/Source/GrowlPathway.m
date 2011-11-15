//
//  GrowlPathway.m
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPathway.h"
#import "GrowlApplicationController.h"

@implementation GrowlPathway

- (id) init {
	if ((self = [super init])) {
        
	}
	return self;
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
