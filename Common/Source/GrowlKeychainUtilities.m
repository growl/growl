//
//  GrowlKeychainUtilities.m
//  Growl
//
//  Created by Daniel Siemer on 11/17/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlKeychainUtilities.h"
#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>

@implementation GrowlKeychainUtilities

+(NSString*)passwordForServiceName:(NSString*)service accountName:(NSString*)account {
   if(service == nil || account == nil)
      return nil;
   
   char *password;
   const char *serviceUTF8 = [service UTF8String];
   const char *accountUTF8 = [account UTF8String];
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword(NULL,
                                           (UInt32)strlen(serviceUTF8), serviceUTF8,
                                           (UInt32)strlen(accountUTF8), accountUTF8,
                                           &passwordLength, (void **)&password, NULL);
   
	NSString *passwordString = nil;
	if (status == noErr && password != NULL) {
		passwordString = [NSString stringWithUTF8String:password];
		if(passwordString) {
			SecKeychainItemFreeContent(NULL, password);
		}
	} else {
		if (status != errSecItemNotFound)
			NSLog(@"Failed to retrieve password for service: %@ with account: %@ from keychain. Error: %d", service, account, (int)status);
	}
   
	return passwordString;
}

+(BOOL)setPassword:(NSString*)password forService:(NSString*)service accountName:(NSString*)account {
   if(service == nil || account == nil)
      return NO;
   
   const char *passwordUTF8 = password ? [password UTF8String] : "";
   const char *serviceUTF8 = [service UTF8String];
   const char *accountUTF8 = [account UTF8String];

	size_t length = strlen(passwordUTF8);
	OSStatus status;
   BOOL result = NO;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword(NULL,
                                           (UInt32)strlen(serviceUTF8), serviceUTF8,
                                           (UInt32)strlen(accountUTF8), accountUTF8,
                                           NULL, NULL, &itemRef);
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword(NULL,
                                             (UInt32)strlen(serviceUTF8), serviceUTF8,
                                             (UInt32)strlen(accountUTF8), accountUTF8,
                                             (UInt32)length, password, NULL);
		if (status == noErr) {
         result = YES;
      }else{
			NSLog(@"Failed to add password to keychain, Error code: %d", (int)status);
      }
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
			{ kSecAccountItemAttr, (UInt32)strlen(accountUTF8), (char *)accountUTF8 },
			{ kSecServiceItemAttr, (UInt32)strlen(serviceUTF8), (char *)serviceUTF8 }
		};
		const SecKeychainAttributeList attributes = { (UInt32)sizeof(attrs) / (UInt32)sizeof(attrs[0]), attrs };
		status = SecKeychainItemModifyAttributesAndData(itemRef,		// the item reference
                                                      &attributes,	// no change to attributes
                                                      (UInt32)length,			// length of password
                                                      passwordUTF8		// pointer to password data
                                                      );
		if (itemRef)
			CFRelease(itemRef);
		if (status == noErr){
         result = YES;
      }else
			NSLog(@"Failed to change password in keychain, %d", (int)status);
	}
   return result;
}

+(BOOL)removePasswordForService:(NSString*)service accountName:(NSString*)account {
   OSStatus status;
   BOOL result = NO;
	SecKeychainItemRef itemRef = nil;
   const char *serviceUTF8 = [service UTF8String];
   const char *accountUTF8 = [account UTF8String];
	status = SecKeychainFindGenericPassword(NULL,
                                           (UInt32)strlen(serviceUTF8), serviceUTF8,
                                           (UInt32)strlen(accountUTF8), accountUTF8,
                                           NULL, NULL, &itemRef);
   if (status == errSecItemNotFound) {
      // Do nothing, we cant find it
      result = YES;
	} else {
		status = SecKeychainItemDelete(itemRef);
      if(status != noErr){
         NSLog(@"Error deleting the password for service: %@ account: %@; %@", service, account, [(NSString*)SecCopyErrorMessageString(status, NULL) autorelease]);
      }else{
         result = YES;
      }
      if(itemRef)
         CFRelease(itemRef);
   }
   return result;
}

@end
