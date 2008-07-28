//
//  GrowlBrowserEntry.m
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlBrowserEntry.h"
#import "GrowlPreferencePane.h"
#include "CFDictionaryAdditions.h"
#include "CFMutableDictionaryAdditions.h"
#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>

#define GrowlBrowserEntryKeychainServiceName "GrowlOutgoingNetworkConnection"

@implementation GrowlBrowserEntry

- (id) initWithDictionary:(NSDictionary *)dict {
	if ((self = [self init])) {
		properties = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, (CFDictionaryRef)dict);
	}

	return self;
}

- (id) initWithComputerName:(NSString *)name {
	if ((self = [self init])) {
		properties = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(properties, CFSTR("computer"), name);
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

- (NSString *) password {
	if (!didPasswordLookup) {
		unsigned char *passwordChars;
		UInt32 passwordLength;
		OSStatus status;
		const char *computerNameChars = [[self computerName] UTF8String];
		status = SecKeychainFindGenericPassword(NULL,
												strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
												strlen(computerNameChars), computerNameChars,
												&passwordLength, (void **)&passwordChars, NULL);		
		if (status == noErr) {
			password = [[NSString alloc] initWithBytes:passwordChars
												length:passwordLength
											  encoding:NSUTF8StringEncoding];
			SecKeychainItemFreeContent(NULL, password);
		} else {
			if (status != errSecItemNotFound)
				NSLog(@"Failed to retrieve password for %@ from keychain. Error: %d", status);
			password = nil;
		}
		
		didPasswordLookup = YES;
	}

	
	return password;
}

- (void) setPassword:(NSString *)inPassword {
	if (password != inPassword) {
		[password release];
		password = [inPassword copy];
	}

	// Store the password to the keychain
	// XXX TODO Use AIKeychain
	const char *passwordChars = password ? [password UTF8String] : "";
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	const char *computerNameChars = [[self computerName] UTF8String];
	status = SecKeychainFindGenericPassword(NULL,
											strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
											strlen(computerNameChars), computerNameChars,
											NULL, NULL, &itemRef);
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword(NULL,
											   strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
											   strlen(computerNameChars), computerNameChars,
											   strlen(passwordChars), passwordChars, NULL);
		if (status)
			NSLog(@"Failed to add password to keychain.");
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
			{ kSecAccountItemAttr, strlen(computerNameChars), (char *)computerNameChars },
			{ kSecServiceItemAttr, strlen(GrowlBrowserEntryKeychainServiceName), (char *)GrowlBrowserEntryKeychainServiceName }
		};
		const SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
		status = SecKeychainItemModifyAttributesAndData(itemRef,		// the item reference
														&attributes,	// no change to attributes
														strlen(passwordChars),			// length of password
														passwordChars		// pointer to password data
														);
		if (itemRef)
			CFRelease(itemRef);
		if (status)
			NSLog(@"Failed to change password in keychain.");
	}
	
	[owner writeForwardDestinations];
}

- (void) setOwner:(GrowlPreferencePane *)pref {
	owner = pref;
}

- (NSDictionary *) properties {
	return (NSDictionary *)properties;
}

- (void) dealloc {
	[password release];

	CFRelease(properties);
	[super dealloc];
}

@end
