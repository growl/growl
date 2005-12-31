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
		properties = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, (CFDictionaryRef)dict);
	}

	return self;
}

- (id) initWithComputerName:(NSString *)name netService:(NSNetService *)service {
	if ((self = [super init])) {
		properties = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(properties, CFSTR("computer"), name);
		CFDictionarySetValue(properties, CFSTR("netservice"), service);
		CFDictionarySetValue(properties, CFSTR("use"), kCFBooleanFalse);
		CFDictionarySetValue(properties, CFSTR("active"), kCFBooleanTrue);
	}

	return self;
}

- (BOOL) use {
	return getBooleanForKey((NSDictionary *)properties, @"use");
}

- (void) setUse:(BOOL)flag {
	setBooleanForKey((NSMutableDictionary *)properties, @"use", flag);
	[owner writeForwardDestinations];
}

- (BOOL) active {
	return getBooleanForKey((NSDictionary *)properties, @"active");
}

- (void) setActive:(BOOL)flag {
	setBooleanForKey((NSMutableDictionary *)properties, @"active", flag);
	[owner writeForwardDestinations];
}

- (NSString *) computerName {
	return (NSString *)CFDictionaryGetValue(properties, CFSTR("computer"));
}

- (void) setComputerName:(NSString *)name {
	CFDictionarySetValue(properties, CFSTR("computer"), name);
	[owner writeForwardDestinations];
}

- (NSNetService *) netService {
	return (NSNetService *)CFDictionaryGetValue(properties, CFSTR("netservice"));
}

- (void) setNetService:(NSNetService *)service {
	CFDictionarySetValue(properties, service, CFSTR("netservice"));
}

- (NSString *) password {
	return (NSString *)CFDictionaryGetValue(properties, CFSTR("password"));
}

- (void) setPassword:(NSString *)password {
	if (password)
		CFDictionarySetValue(properties, CFSTR("password"), password);
	else
		CFDictionaryRemoveValue(properties, CFSTR("password"));
	[owner writeForwardDestinations];
}

- (void) setAddress:(NSData *)address {
	CFDictionarySetValue(properties, CFSTR("address"), address);
	CFDictionaryRemoveValue(properties, CFSTR("netservice"));
	[owner writeForwardDestinations];
}

- (void) setOwner:(GrowlPreferencePane *)pref {
	owner = pref;
}

- (NSDictionary *) properties {
	return (NSDictionary *)properties;
}

- (void) dealloc {
	CFRelease(properties);
	[super dealloc];
}

@end
