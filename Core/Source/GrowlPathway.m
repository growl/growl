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

static GrowlApplicationController *applicationController;
static IMP registerApplicationWithDictionaryIMP;
static IMP dispatchNotificationWithDictionaryIMP;

- (id) init {
	if ((self = [super init])) {
		if (!applicationController) {
			applicationController = [GrowlApplicationController sharedInstance];
			registerApplicationWithDictionaryIMP = [applicationController methodForSelector:@selector(registerApplicationWithDictionary:)];
			dispatchNotificationWithDictionaryIMP = [applicationController methodForSelector:@selector(dispatchNotificationWithDictionary:)];
		}
	}
	return self;
}

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	//[[GrowlApplicationController sharedInstance] registerApplicationWithDictionary:dict];
	registerApplicationWithDictionaryIMP(applicationController, @selector(registerApplicationWithDictionary:), dict);
}

- (void) postNotificationWithDictionary:(NSDictionary *)dict {
	//[[GrowlApplicationController sharedInstance] dispatchNotificationWithDictionary:dict];
	dispatchNotificationWithDictionaryIMP(applicationController, @selector(dispatchNotificationWithDictionary:), dict);
}

- (NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}
@end
