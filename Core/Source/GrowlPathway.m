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

static GrowlApplicationController *applicationController = nil;

- (id) init {
	if ((self = [super init])) {
		if (!applicationController) {
			applicationController = [GrowlApplicationController sharedInstance];
		}
	}
	return self;
}

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	[NSApplication detachDrawingThread:@selector(registerApplicationWithDictionary:)
							  toTarget:applicationController
							withObject:dict];
}

- (void) postNotificationWithDictionary:(NSDictionary *)dict {
	[NSApplication detachDrawingThread:@selector(dispatchNotificationWithDictionary:)
							  toTarget:applicationController
							withObject:dict];
}

- (NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}
@end
