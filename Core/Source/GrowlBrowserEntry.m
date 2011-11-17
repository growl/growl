//
//  GrowlBrowserEntry.m
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlBrowserEntry.h"
#import "GrowlPreferencePane.h"
#import "NSStringAdditions.h"
#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>

#define GrowlBrowserEntryKeychainServiceName "GrowlOutgoingNetworkConnection"

@interface GNTPHostAvailableColorTransformer : NSValueTransformer
@end

@implementation GNTPHostAvailableColorTransformer

+ (void)load
{
   if (self == [GNTPHostAvailableColorTransformer class]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self setValueTransformer:[[[self alloc] init] autorelease]
                        forName:@"GNTPHostAvailableColorTransformer"];
      [pool release];
   }
}

+ (Class)transformedValueClass 
{ 
   return [NSColor class];
}
+ (BOOL)allowsReverseTransformation
{
   return NO;
}
- (id)transformedValue:(id)value
{
   return [value boolValue] ? [NSColor blackColor] : [NSColor redColor];
}

@end

@implementation GrowlBrowserEntry
@synthesize computerName = _name;
@synthesize uuid = _uuid;
@synthesize use = _use;
@synthesize active = _active;
@synthesize manualEntry = _manualEntry;
@synthesize domain = _domain;

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
			uuid = [[NSProcessInfo processInfo] globallyUniqueString];        
        [self setUuid:uuid];
		[self setComputerName:[dict valueForKey:@"computer"]];
		[self setUse:[[dict valueForKey:@"use"] boolValue]];
		[self setActive:[[dict valueForKey:@"active"] boolValue]];
        [self setManualEntry:[[dict valueForKey:@"manualEntry"] boolValue]];
        [self setDomain:[dict valueForKey:@"domain"]];

	}

	return self;
}

- (id) initWithComputerName:(NSString *)name {
	if ((self = [self init])) {		
        [self setUuid:[[NSProcessInfo processInfo] globallyUniqueString]];
		[self setComputerName:name];
		[self setUse:FALSE];
		[self setActive:TRUE];
        [self setManualEntry:NO];
        [self setDomain:@"local."];
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
		const char *uuidChars = [[self uuid] UTF8String];
		status = SecKeychainFindGenericPassword(NULL,
												(UInt32)strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
												(UInt32)strlen(uuidChars), uuidChars,
												&passwordLength, (void **)&passwordChars, NULL);		
		if (status == noErr) {
			password = [[NSString alloc] initWithBytes:passwordChars
												length:passwordLength
											  encoding:NSUTF8StringEncoding];
			SecKeychainItemFreeContent(NULL, passwordChars);
		} else {
			if (status != errSecItemNotFound)
				NSLog(@"Failed to retrieve password for %@ from keychain. Error: %d", [self computerName], (int)status);
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
	const char *uuidChars = [[self uuid] UTF8String];
	status = SecKeychainFindGenericPassword(NULL,
											(UInt32)strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
											(UInt32)strlen(uuidChars), uuidChars,
											NULL, NULL, &itemRef);
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword(NULL,
											   (UInt32)strlen(GrowlBrowserEntryKeychainServiceName), GrowlBrowserEntryKeychainServiceName,
											   (UInt32)strlen(uuidChars), uuidChars,
											   (UInt32)strlen(passwordChars), passwordChars, NULL);
		if (status)
			NSLog(@"Failed to add password to keychain.");
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
			{ kSecAccountItemAttr, (UInt32)strlen(uuidChars), (char *)uuidChars },
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
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:[self uuid], @"uuid",
                                                             [self computerName], @"computer", 
                                                             [NSNumber numberWithBool:[self use]], @"use",
                                                             [NSNumber numberWithBool:[self active]], @"active",
                                                             [NSNumber numberWithBool:[self manualEntry]], @"manualEntry",
                                                             [self domain], @"domain", nil];
}

-(BOOL)validateValue:(id *)ioValue forKey:(NSString *)inKey error:(NSError **)outError
{
    if(![inKey isEqualToString:@"computerName"])
        return [super validateValue:ioValue forKey:inKey error:outError];
    
    NSString *newString = (NSString*)*ioValue;
    if(([newString Growl_isLikelyIPAddress] || [newString Growl_isLikelyDomainName]) && 
       ![newString isLocalHost]){
        return YES;
    }
    
    NSString *description;
    if([newString isLocalHost]){
        NSLog(@"Error, don't enter localhost in any of its forms");
        description = NSLocalizedString(@"Please do not enter localhost, Growl does not support forwarding to itself.", @"Localhost in a forwarding destination is not allowed");
    }else{
        NSLog(@"Error, enter a valid host name or IP");
        description = NSLocalizedString(@"Please enter a valid IPv4 or IPv6 address, or a valid domain name", @"A valid IP or domain is needed to forward to");
    }
    
    NSDictionary *eDict = [NSDictionary dictionaryWithObject:description
                                                      forKey:NSLocalizedDescriptionKey];
    if(outError != NULL)
        *outError = [[[NSError alloc] initWithDomain:@"GrowlNetworking" code:2 userInfo:eDict] autorelease];
    return NO;
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
