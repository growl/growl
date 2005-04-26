//
//  MD5Authenticator.m
//  Growl
//
//  Created by Ingmar Stein on 24.04.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "MD5Authenticator.h"
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>
#include <openssl/md5.h>

#define keychainServiceName "Growl"
#define keychainAccountName "Growl"

@implementation MD5Authenticator
- (id) initWithPassword:(NSString *)pwd {
	if ((self = [super init])) {
		password = [pwd copy];
	}
	return self;
}

- (void) dealloc {
	[password release];
	[super dealloc];
}

- (NSData *) authenticationDataForComponents:(NSArray *)components {
	MD5_CTX ctx;
	NSEnumerator *e;
	unsigned char checksum[MD5_DIGEST_LENGTH];
	OSStatus status;
	char *passwordBytes;
	UInt32 passwordLength;

	MD5_Init(&ctx);
	e = [components objectEnumerator];
	id item;
	while ((item = [e nextObject])) {
		if ([item isKindOfClass:[NSData class]]) {
			MD5_Update(&ctx, [item bytes], [item length]);
		}
	}

	if (password) {
		passwordBytes = (char *)[password UTF8String];
		passwordLength = strlen(passwordBytes);
		MD5_Update(&ctx, passwordBytes, passwordLength);
	} else {
		status = SecKeychainFindGenericPassword( /*keychainOrArray*/ NULL,
												 strlen(keychainServiceName), keychainServiceName,
												 strlen(keychainAccountName), keychainAccountName,
												 &passwordLength, (void **)&passwordBytes,
												 NULL);
		if (status == noErr) {
			MD5_Update(&ctx, passwordBytes, passwordLength);
			SecKeychainItemFreeContent(/*attrList*/ NULL, passwordBytes);
		} else if (status != errSecItemNotFound) {
			NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
		}
	}

	MD5_Final(checksum, &ctx);

	return [NSData dataWithBytes:&checksum length:sizeof(checksum)];
}

- (BOOL) authenticateComponents:(NSArray *)components withData:(NSData *)signature {
	NSData *recomputedSignature = [self authenticationDataForComponents:components];

	// If the two NSDatas are not equal, authentication failure!
	if (![recomputedSignature isEqual:signature]) {
		NSLog(@"authentication failure: received signature doesn't match computed signature");
		return NO;
	}
	return YES;
}

@end
