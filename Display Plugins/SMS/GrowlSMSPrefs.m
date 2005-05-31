//
//  GrowlSMSPrefs.m
//  Display Plugins
//
//  Copyright 2005 Diggory Laycock All rights reserved.
//

#import "GrowlSMSPrefs.h"
#import <GrowlDefinesInternal.h>
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>



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
	READ_GROWL_PREF_VALUE(accountNameKey, @"com.Growl.SMS", NSString *, &value);
	return [value autorelease];
}

- (void) setAccountName:(NSString *)value {
	if (!value) {
		value = @"";
	}
	WRITE_GROWL_PREF_VALUE(accountNameKey, value, @"com.Growl.SMS");
	UPDATE_GROWL_PREFS();
}


- (NSString *) getAccountAPIID {
	NSString *value = nil;
	READ_GROWL_PREF_VALUE(accountAPIIDKey, @"com.Growl.SMS", NSString *, &value);
	return [value autorelease];
}

- (void) setAccountAPIID:(NSString *)value {
	if (!value) {
		value = @"";
	}
	WRITE_GROWL_PREF_VALUE(accountAPIIDKey, value, @"com.Growl.SMS");
	UPDATE_GROWL_PREFS();
}


- (NSString *) getDestinationNumber {
	NSString *value = nil;
	READ_GROWL_PREF_VALUE(destinationNumberKey, @"com.Growl.SMS", NSString *, &value);
	return [value autorelease];
}

- (void) setDestinationNumber:(NSString *)value {
	if (!value) {
		value = @"";
	}
	WRITE_GROWL_PREF_VALUE(destinationNumberKey, value, @"com.Growl.SMS");
	UPDATE_GROWL_PREFS();
}






- (NSString *) accountPassword {
	char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword( NULL,
											 strlen(keychainServiceName), keychainServiceName,
											 strlen(keychainAccountName), keychainAccountName,
											 &passwordLength, (void **)&password, NULL );
	
	NSString *passwordString;
	if (status == noErr) {
		passwordString = [NSString stringWithUTF8String:password length:passwordLength];
		SecKeychainItemFreeContent(NULL, password);
	} else {
		if (status != errSecItemNotFound)
			NSLog(@"Failed to retrieve SMS Account password from keychain. Error: %d", status);
		passwordString = @"";
	}
	
	return passwordString;
}

- (void) setAccountPassword:(NSString *)value {
	const char *password = value ? [value UTF8String] : "";
	unsigned length = strlen(password);
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword( NULL,
											 strlen(keychainServiceName), keychainServiceName,
											 strlen(keychainAccountName), keychainAccountName,
											 NULL, NULL, &itemRef );
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword( NULL,
												strlen(keychainServiceName), keychainServiceName,
												strlen(keychainAccountName), keychainAccountName,
												length, password, NULL );
		if (status)
			NSLog(@"Failed to add SMS Account password to keychain.");
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
		{ kSecAccountItemAttr, strlen(keychainAccountName), (char *)keychainAccountName },
		{ kSecServiceItemAttr, strlen(keychainServiceName), (char *)keychainServiceName }
		};
		const SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
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
