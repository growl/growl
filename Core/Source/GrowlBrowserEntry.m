//
//  GrowlBrowserEntry.m
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlBrowserEntry.h"
#import "GNTPForwarder.h"
#import "NSStringAdditions.h"
#import "GNTPKey.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@implementation GrowlBrowserEntry
@synthesize computerName = _name;
@synthesize uuid = _uuid;
@synthesize use = _use;
@synthesize active = _active;
@synthesize manualEntry = _manualEntry;
@synthesize domain = _domain;
@synthesize key = _key;
@synthesize lastKnownAddress = _lastKnownAddress;

- (id) init {
	
	if ((self = [super init])) {
		[self addObserver:self forKeyPath:@"use" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"active" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"computerName" options:NSKeyValueObservingOptionNew context:self];
      [self setUuid:[[NSProcessInfo processInfo] globallyUniqueString]];
      didPasswordLookup = NO;
      
      self.lastKnownAddress = nil;
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
      if(_manualEntry)
         self.active = YES;
      [self setDomain:[dict valueForKey:@"domain"]];
      [self updateKey];
   }

	return self;
}

- (id) initWithComputerName:(NSString *)name {
	if ((self = [self init])) {		
        [self setUuid:[[NSProcessInfo processInfo] globallyUniqueString]];
		[self setComputerName:name];
		[self setUse:NO];
		[self setActive:YES];
      [self setManualEntry:NO];
      [self setDomain:@"local."];
      [self updateKey];
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

- (void)updateKey {
   if(![self password] || [[self password] isEqualToString:@""])
      self.key = [[[GNTPKey alloc] initWithPassword:@"" hashAlgorithm:GNTPNoHash encryptionAlgorithm:GNTPNone] autorelease];
   else
      self.key = [[[GNTPKey alloc] initWithPassword:[self password] hashAlgorithm:GNTPSHA512 encryptionAlgorithm:GNTPNone] autorelease];
}

- (NSString *) password {
	if (!didPasswordLookup && [self uuid]) {
      password = [[GrowlKeychainUtilities passwordForServiceName:GrowlOutgoingNetworkPassword accountName:[self uuid]] retain];
		
		didPasswordLookup = YES;
	}
	return password;
}

- (void) setPassword:(NSString *)inPassword {
	if (password != inPassword) {
		[password release];
		password = [inPassword copy];
	}else{
      //No need to write out forward destinations or reset password if its the same string as already;
      return;
   }
   
   [self updateKey];
   [GrowlKeychainUtilities setPassword:password forService:GrowlOutgoingNetworkPassword accountName:[self uuid]];
	
	[owner writeForwardDestinations];
}

-(void)setComputerName:(NSString *)name
{
   if(_name)
      [_name release];
   _name = [name retain];
   
   self.lastKnownAddress = nil;
}

- (void) setOwner:(GNTPForwarder *)pref {
	owner = pref;
}

- (void) setLastKnownAddress:(NSData *)address {
   //If someone is trying to set the address data and we aren't allowed to do caching at the moment, nil it
   if(![[GrowlPreferencesController sharedController] boolForKey:@"AddressCachingEnabled"] && address)
      address = nil;
   if(_lastKnownAddress)
      [_lastKnownAddress release];
   _lastKnownAddress = [address retain];
}

- (void)setActive:(BOOL)active {
   _active = active;
   //If we are a bonjour entry, nil out address data on inactivate/reactivate to ensure we check again
   //Same if we are a domain name based manual entry
   if(!_manualEntry || [_name Growl_isLikelyDomainName])
      self.lastKnownAddress = nil;
}

- (void)setUse:(BOOL)use {
   _use = use;
   //If we are a bonjour entry, nil out address data on set of use to ensure we check again
   //Same if we are a domain name based manual entry
   if(!_manualEntry || ![_name Growl_isLikelyIPAddress])
      self.lastKnownAddress = nil;
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
   [_key release];
   [_domain release];
	
	[super dealloc];
}

@end
