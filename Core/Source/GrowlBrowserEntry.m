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
@synthesize computerName = _name;
@synthesize uuid = _uuid;
@synthesize use = _use;
@synthesize active = _active;

- (id) init {
	
	if ((self = [super init])) {
		[self addObserver:self forKeyPath:@"use" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"active" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"computerName" options:NSKeyValueObservingOptionNew context:self];
	}
	return self;
}

- (id) initWithDictionary:(NSDictionary *)dict {
	if ((self = [self init])) {
		NSString *uuid = [dict valueForKey:@"uuid"];
		if(!uuid)
		{
			CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
			if(newUUID)
			{
				CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault, newUUID);
				[self setUuid:(NSString*)UUIDString];
				CFRelease(newUUID);
				CFRelease(UUIDString);
			}
		}
		else
			[self setUuid:uuid];
		[self setComputerName:[dict valueForKey:@"computer"]];
		[self setUse:[[dict valueForKey:@"use"] boolValue]];
		[self setActive:[[dict valueForKey:@"active"] boolValue]];
	}

	return self;
}

- (id) initWithComputerName:(NSString *)name {
	if ((self = [self init])) {		
		CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
		if(newUUID)
		{
			CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault, newUUID);
			[self setUuid:(NSString*)UUIDString];
			CFRelease(newUUID);
			CFRelease(UUIDString);
		}
		[self setComputerName:name];
		[self setUse:FALSE];
		[self setActive:TRUE];
	}

	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if(([keyPath isEqualToString:@"use"] || 
		[keyPath isEqualToString:@"active"] || 
		[keyPath isEqualToString:@"computerName"]) && context == self) 
	{
		[owner writeForwardDestinations];
	}
}

- (NSString *) password {
	if (!didPasswordLookup && [self computerName]) {
		unsigned char *passwordChars;
		UInt32 passwordLength;
		OSStatus status;
		const char *computerNameChars = [[self computerName] UTF8String];
		status = SecKeychainFindGenericPassword(NULL,
												(UInt32)strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
												(UInt32)strlen(computerNameChars), computerNameChars,
												&passwordLength, (void **)&passwordChars, NULL);		
		if (status == noErr) {
			password = [[NSString alloc] initWithBytes:passwordChars
												length:passwordLength
											  encoding:NSUTF8StringEncoding];
			SecKeychainItemFreeContent(NULL, passwordChars);
		} else {
			if (status != errSecItemNotFound)
				NSLog(@"Failed to retrieve password for %@ from keychain. Error: %d", [self computerName], status);
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
											(UInt32)strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
											(UInt32)strlen(computerNameChars), computerNameChars,
											NULL, NULL, &itemRef);
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword(NULL,
											   (UInt32)strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
											   (UInt32)strlen(computerNameChars), computerNameChars,
											   (UInt32)strlen(passwordChars), passwordChars, NULL);
		if (status)
			NSLog(@"Failed to add password to keychain.");
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
			{ kSecAccountItemAttr, (UInt32)strlen(computerNameChars), (char *)computerNameChars },
			{ kSecServiceItemAttr, (UInt32)strlen(GrowlBrowserEntryKeychainServiceName), (char *)GrowlBrowserEntryKeychainServiceName }
		};
		const SecKeychainAttributeList attributes = { (UInt32)sizeof(attrs) / (UInt32)sizeof(attrs[0]), attrs };
		status = SecKeychainItemModifyAttributesAndData(itemRef,		// the item reference
														&attributes,	// no change to attributes
														(UInt32)strlen(passwordChars),			// length of password
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

- (NSMutableDictionary *) properties {
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:[self uuid], @"uuid", [self computerName], @"computer", [NSNumber numberWithBool:[self use]], @"use", [NSNumber numberWithBool:[self active]], @"active", nil];
}

- (void) dealloc {
	
	[self removeObserver:self forKeyPath:@"use"];
	[self removeObserver:self forKeyPath:@"active"];
	[self removeObserver:self forKeyPath:@"computerName"];
	
	[password release];
	[_name release];
	[_uuid release];
	
	[super dealloc];
}

@end
