//
//  GrowlRemotePathway.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-03-12.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"


@implementation GrowlRemotePathway

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	if ([[GrowlPreferencesController sharedController] boolForKey:GrowlRemoteRegistrationKey])
		[super registerApplicationWithDictionary:dict];
}

@end
