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

static GrowlApplicationController *_sharedApplicationController = nil;
static SEL registerApplicationWithDictionarySEL = NULL;
static IMP registerApplicationWithDictionaryIMP = NULL;
static SEL dispatchNotificationWithDictionarySEL = NULL;
static IMP dispatchNotificationWithDictionaryIMP = NULL;

+ (void) initialize {
	_sharedApplicationController = [GrowlApplicationController sharedInstance];
	registerApplicationWithDictionarySEL = @selector(registerApplicationWithDictionary:);
	registerApplicationWithDictionaryIMP = [_sharedApplicationController methodForSelector:registerApplicationWithDictionarySEL];
	dispatchNotificationWithDictionarySEL = @selector(dispatchNotificationWithDictionary:);
	dispatchNotificationWithDictionaryIMP = [_sharedApplicationController methodForSelector:dispatchNotificationWithDictionarySEL];
}

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	//[_sharedApplicationController registerApplicationWithDictionary:dict];
	registerApplicationWithDictionaryIMP(_sharedApplicationController, registerApplicationWithDictionarySEL, dict);
}

- (void) postNotificationWithDictionary:(NSDictionary *)dict {
	//[_sharedApplicationController dispatchNotificationWithDictionary:dict];
	dispatchNotificationWithDictionaryIMP(_sharedApplicationController, dispatchNotificationWithDictionarySEL, dict);
}

- (NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}
@end
