//
//  GrowlSMSPrefs.m
//  Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005-2006 The Growl Project All rights reserved.
//

#import "GrowlSMSPrefs.h"
#import "GrowlDefinesInternal.h"
#import "NSStringAdditions.h"
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>

#define GrowlSMSPrefDomain		@"com.Growl.SMS"
#define accountNameKey			@"SMS - Account Name"
#define accountAPIIDKey			@"SMS - Account API ID"
#define destinationNumberKey	@"SMS - Destination Number"

#define keychainServiceName "GrowlSMS"
#define keychainAccountName "SMSWebServicePassword"


@implementation GrowlSMSPrefs

- (NSString *) mainNibName {
	return @"GrowlSMSPrefs";
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -

- (NSString *) getAccountName {
	NSString *value = nil;
	READ_GROWL_PREF_VALUE(accountNameKey, GrowlSMSPrefDomain, NSString *, &value);
	if(value)
		CFMakeCollectable(value);
	return [value autorelease];
}

- (void) setAccountName:(NSString *)value {
	if (!value)
		value = @"";
	WRITE_GROWL_PREF_VALUE(accountNameKey, value, GrowlSMSPrefDomain);
	UPDATE_GROWL_PREFS();
}


- (NSString *) getAccountAPIID {
	NSString *value = nil;
	READ_GROWL_PREF_VALUE(accountAPIIDKey, GrowlSMSPrefDomain, NSString *, &value);
	if(value)
		CFMakeCollectable(value);
	return [value autorelease];
}

- (void) setAccountAPIID:(NSString *)value {
	if (!value)
		value = @"";
	WRITE_GROWL_PREF_VALUE(accountAPIIDKey, value, GrowlSMSPrefDomain);
	UPDATE_GROWL_PREFS();
}


- (NSString *) getDestinationNumber {
	NSString *value = nil;
	READ_GROWL_PREF_VALUE(destinationNumberKey, GrowlSMSPrefDomain, NSString *, &value);
	if(value)
		CFMakeCollectable(value);
	return [value autorelease];
}

- (void) setDestinationNumber:(NSString *)value {
	if (!value)
		value = @"";
	WRITE_GROWL_PREF_VALUE(destinationNumberKey, value, GrowlSMSPrefDomain);
	UPDATE_GROWL_PREFS();
}


- (NSString *) accountPassword {
	unsigned char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword( NULL,
											 (UInt32)strlen(keychainServiceName), keychainServiceName,
											 (UInt32)strlen(keychainAccountName), keychainAccountName,
											 &passwordLength, (void **)&password, NULL );

	NSString *passwordString;
	if (status == noErr) {
		passwordString = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault, password, passwordLength, kCFStringEncodingUTF8, false);
		if(passwordString)
			CFMakeCollectable(passwordString);		
		[passwordString autorelease];
		SecKeychainItemFreeContent(NULL, password);
	} else {
		if (status != errSecItemNotFound)
			NSLog(@"Failed to retrieve SMS Account password from keychain. Error: %d", (int)status);
		passwordString = @"";
	}

	return passwordString;
}

- (void) setAccountPassword:(NSString *)value {
	const char *password = value ? [value UTF8String] : "";
	UInt32 length = (UInt32)strlen(password);
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword( NULL,
											 (UInt32)strlen(keychainServiceName), keychainServiceName,
											 (UInt32)strlen(keychainAccountName), keychainAccountName,
											 NULL, NULL, &itemRef );
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword( NULL,
												(UInt32)strlen(keychainServiceName), keychainServiceName,
												(UInt32)strlen(keychainAccountName), keychainAccountName,
												length, password, NULL );
		if (status)
			NSLog(@"Failed to add SMS Account password to keychain.");
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
			{ kSecAccountItemAttr, (UInt32)strlen(keychainAccountName), (char *)keychainAccountName },
			{ kSecServiceItemAttr, (UInt32)strlen(keychainServiceName), (char *)keychainServiceName }
		};
		const SecKeychainAttributeList attributes = { (UInt32)sizeof(attrs) / (UInt32)sizeof(attrs[0]), attrs };
		status = SecKeychainItemModifyAttributesAndData( itemRef,		// the item reference
														 &attributes,	// no change to attributes
														 length,		// length of password
														 password		// pointer to password data
														 );
		if (itemRef)
			CFRelease(itemRef);
		if (status)
			NSLog(@"Failed to change SMS password in keychain.");
	}
}

@end
