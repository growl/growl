//
//  GrowlNetworkObserver.m
//  Growl
//
//  Created by Daniel Siemer on 12/13/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlNetworkObserver.h"

#import "NSStringAdditions.h"
#import "GrowlNetworkUtilities.h"

#import <SystemConfiguration/SystemConfiguration.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

/** A reference to the SystemConfiguration dynamic store. */
static SCDynamicStoreRef dynStore = NULL;

/** Our run loop source for notification. */
static CFRunLoopSourceRef rlSrc = NULL;

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

@implementation GrowlNetworkObserver

@synthesize primaryIP;
@synthesize routableArray;
@synthesize routableCombined;

+(GrowlNetworkObserver*)sharedObserver 
{
   static GrowlNetworkObserver *_sharedObserver;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      _sharedObserver = [[self alloc] init];
   });
   return _sharedObserver;
}

-(id)init 
{
   if((self = [super init])) {
      self.primaryIP = nil;
      self.routableArray = nil;
      self.routableCombined = nil;
      [self startObserving];
      [self updateAddresses];
   }
   return self;
}

-(void)setupDynamicStore
{
   if(dynStore != NULL)
      return;
   
   SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};
   
	dynStore = SCDynamicStoreCreate(kCFAllocatorDefault,
                                   CFBundleGetIdentifier(CFBundleGetMainBundle()),
                                   scCallback,
                                   &context);
	if (!dynStore) {
		NSLog(@"SCDynamicStoreCreate() failed: %s", SCErrorString(SCError()));
	}
   
   rlSrc = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynStore, 0);
	CFRunLoopAddSource(CFRunLoopGetMain(), rlSrc, kCFRunLoopDefaultMode);
   CFRelease(rlSrc);
}

-(void)startObserving
{
   [self setupDynamicStore];
      
   const CFStringRef keys[1] = {
		CFSTR("State:/Network/Interface/*"),
	};
	CFArrayRef watchedKeys = CFArrayCreate(kCFAllocatorDefault,
                                          (const void **)keys,
                                          1,
                                          &kCFTypeArrayCallBacks);
	if (!SCDynamicStoreSetNotificationKeys(dynStore,
                                          NULL,
                                          watchedKeys)) 
   {
		NSLog(@"SCDynamicStoreSetNotificationKeys() failed: %s", SCErrorString(SCError()));
		CFRelease(dynStore);
		dynStore = NULL;
	}
	CFRelease(watchedKeys);
}

-(void)stopObserving
{
   if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetMain(), rlSrc, kCFRunLoopDefaultMode);
   if (dynStore)
		CFRelease(dynStore);
   
   self.primaryIP = nil;
   self.routableArray = nil;
   self.routableCombined = nil;
}

-(void)updateAddresses
{   
	NSArray *routable = [GrowlNetworkUtilities routableIPAddresses];
	NSString *newString = [routable componentsJoinedByString:@"\n"];
	if([newString isEqualToString:@""])
		newString = nil;
	
   if(newString){
		self.routableArray = routable;
      self.routableCombined = newString;
   }else{
      self.routableCombined = nil;
      self.routableArray = nil;
   }
   
   [[NSNotificationCenter defaultCenter] postNotificationName:IPAddressesUpdateNotification object:self];
   
   NSString *ipv4Primary = [GrowlNetworkUtilities getPrimaryIPOfType:@"IPv4" fromStore:dynStore];
   NSString *ipv6Primary = [GrowlNetworkUtilities getPrimaryIPOfType:@"IPv6" fromStore:dynStore];
   if(ipv4Primary || ipv6Primary){
      NSString *newPrimary;
      if(ipv4Primary)
         newPrimary = ipv4Primary;
      else
         newPrimary = ipv6Primary;
      if(![self.primaryIP caseInsensitiveCompare:newPrimary] == NSOrderedSame){
         //We have changed primary IP for some reason or another
         [[NSNotificationCenter defaultCenter] postNotificationName:PrimaryIPChangeNotification object:self];
         NSLog(@"Primary IP changed");
      }
   }else {
      //If primary IP is already nil, no need to inform the observers
      if(primaryIP){
         self.primaryIP = nil;
         [[NSNotificationCenter defaultCenter] postNotificationName:PrimaryIPChangeNotification object:self];
         NSLog(@"No primary IP, not connected");
      }
   }
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	GrowlNetworkObserver *observer = info;
	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
      if (CFStringCompare(key, CFSTR("State:/Network/Interface"), 0) == kCFCompareEqualTo) {
			[observer updateAddresses];
		}
	}
}

@end
