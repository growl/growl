//
//  GrowlPathway.m
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPathway.h"
#import "GrowlApplicationController.h"

@implementation GrowlPathway

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	[[GrowlApplicationController sharedController] registerApplicationWithDictionary:dict];
}

- (void) postNotificationWithDictionary:(NSDictionary *)dict {
	[[GrowlApplicationController sharedController] dispatchNotificationWithDictionary:dict];
}

- (NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}
@end
