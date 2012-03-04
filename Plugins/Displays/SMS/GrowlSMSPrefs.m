//
//  GrowlSMSPrefs.m
//  Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005–2011 The Growl Project All rights reserved.
//

#import "GrowlSMSPrefs.h"
#import "GrowlSMSDisplay.h"
#import "GrowlDefinesInternal.h"
#import "NSStringAdditions.h"
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>

@implementation GrowlSMSPrefs

@synthesize smsNotifications;
@synthesize accountRequiredLabel;
@synthesize instructions;
@synthesize accountLabel;
@synthesize passwordLabel;
@synthesize apiIDLabel;
@synthesize destinationLabel;

- (id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.smsNotifications = NSLocalizedString(@"SMS Notifications", @"Title for SMS plugin");
      self.accountRequiredLabel = NSLocalizedString(@"(Clickatell.com account required.)", @"Warning that a clickatell.com account is required");
      self.instructions = NSLocalizedString(@"To register:\nhttp://www.clickatell.com/brochure/products/api_xml.php\n\nFor rates see:\nhttp://www.clickatell.com/brochure/pricing.php", @"Instructions for clickatell");
      self.accountLabel = NSLocalizedString(@"Account:", @"Label for account field");
      self.passwordLabel = NSLocalizedString(@"Password:", @"Label for password field");
      self.apiIDLabel = NSLocalizedString(@"API ID:", @"label for API ID field");
      self.destinationLabel = NSLocalizedString(@"Destination Number:", @"label for destination number field");
   }
   return self;
}

- (void)dealloc {
   [smsNotifications release];
   [accountRequiredLabel release];
   [instructions release];
   [accountLabel release];
   [passwordLabel release];
   [apiIDLabel release];
   [destinationLabel release];
   [super dealloc];
}

- (NSString *) mainNibName {
	return @"GrowlSMSPrefs";
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"accountName",
				  @"accountAPIID",
				  @"destinationNumber",
				  @"accountPassword", nil];
	});
	return keys;
}

#pragma mark -

- (NSString *) getAccountName {
	return [self.configuration valueForKey:accountNameKey];
}

- (void) setAccountName:(NSString *)value {
	if (!value)
		value = @"";
	[self setConfigurationValue:value forKey:accountNameKey];
}


- (NSString *) getAccountAPIID {
	return [self.configuration valueForKey:accountAPIIDKey];
}

- (void) setAccountAPIID:(NSString *)value {
	if (!value)
		value = @"";
	[self setConfigurationValue:value forKey:accountAPIIDKey];
}


- (NSString *) getDestinationNumber {
	return [self.configuration valueForKey:destinationNumberKey];
}

- (void) setDestinationNumber:(NSString *)value {
	if (!value)
		value = @"";
	[self setConfigurationValue:value forKey:destinationNumberKey];
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
