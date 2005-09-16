//
//  GrowlBrowserEntry.m
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlBrowserEntry.h"
#import "GrowlPreferencePane.h"
#include "CFDictionaryAdditions.h"
#include "CFMutableDictionaryAdditions.h"

@implementation GrowlBrowserEntry

- (id) initWithDictionary:(NSDictionary *)dict {
	if ((self = [super init])) {
		properties = [dict mutableCopy];
	}

	return self;
}

- (id) initWithComputerName:(NSString *)name netService:(NSNetService *)service {
	if ((self = [super init])) {
		NSNumber *useValue = [[NSNumber alloc] initWithBool:NO];
		properties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			name,     @"computer",
			service,  @"netservice",
			useValue, @"use",
			nil];
		[useValue release];
	}

	return self;
}

- (BOOL) use {
	return getBooleanForKey(properties, @"use");
}

- (void) setUse:(BOOL)flag {
	setBooleanForKey(properties, @"use", flag);
	[owner writeForwardDestinations];
}

- (NSString *) computerName {
	return getObjectForKey(properties, @"computer");
}

- (void) setComputerName:(NSString *)name {
	setObjectForKey(properties, @"computer", name);
	[owner writeForwardDestinations];
}

- (NSNetService *) netService {
	return getObjectForKey(properties, @"netservice");
}

- (void) setNetService:(NSNetService *)service {
	setObjectForKey(properties, @"netservice", service);
}

- (NSString *) password {
	return getObjectForKey(properties, @"password");
}

- (void) setPassword:(NSString *)password {
	if (password)
		setObjectForKey(properties, password, @"password");
	else
		[properties removeObjectForKey:@"password"];
	[owner writeForwardDestinations];
}

- (void) setAddress:(NSData *)address {
	setObjectForKey(properties, @"address", address);
	[properties removeObjectForKey:@"netservice"];
	[owner writeForwardDestinations];
}

- (void) setOwner:(GrowlPreferencePane *)pref {
	owner = pref;
}

- (NSDictionary *) properties {
	return properties;
}

- (void) dealloc {
	[properties release];
	[super dealloc];
}

@end
