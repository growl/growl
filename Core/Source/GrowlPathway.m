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

static IMP registerApplicationWithDictionaryIMP = NULL;
static IMP dispatchNotificationWithDictionaryIMP = NULL;

+ (void) initialize {
	registerApplicationWithDictionaryIMP = [GrowlApplicationController instanceMethodForSelector:@selector(registerApplicationWithDictionary:)];
	dispatchNotificationWithDictionaryIMP = [GrowlApplicationController instanceMethodForSelector:@selector(dispatchNotificationWithDictionary:)];
}

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	//[[GrowlApplicationController sharedInstance] registerApplicationWithDictionary:dict];
	registerApplicationWithDictionaryIMP([GrowlApplicationController sharedInstance], @selector(registerApplicationWithDictionary:), dict);
}

- (void) postNotificationWithDictionary:(NSDictionary *)dict {
	//[[GrowlApplicationController sharedInstance] dispatchNotificationWithDictionary:dict];
	dispatchNotificationWithDictionaryIMP([GrowlApplicationController sharedInstance], @selector(dispatchNotificationWithDictionary:), dict);
}

- (NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}
@end
