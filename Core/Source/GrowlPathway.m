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
		dispatch_async(dispatch_get_main_queue(), ^{
			[[GrowlApplicationController sharedController] registerApplicationWithDictionary:dict];
		});
    }
	return YES;
}

- (oneway void) postNotificationWithDictionary:(bycopy NSDictionary *)dict {
	@autoreleasepool {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[GrowlApplicationController sharedController] dispatchNotificationWithDictionary:dict];
		});
	}
}

- (GrowlNotificationResult)resultOfPostNotificationWithDictionary:(bycopy NSDictionary *)notification {
	__block GrowlNotificationResult result = GrowlNotificationResultNotRegistered;
	@autoreleasepool {
		dispatch_sync(dispatch_get_main_queue(), ^{
			result = [[GrowlApplicationController sharedController] dispatchNotificationWithDictionary:notification];
		});
	}
	return result;
}

- (bycopy NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}
@end
