//
//  GrowlNetworkObserver.m
//  Growl
//
//  Created by Daniel Siemer on 12/13/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlNetworkObserver.h"

#import "NSStringAdditions.h"

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

-(NSString*)getPrimaryIPOfType:(NSString*)type
{
   NSString *returnIP = nil;
   NSString *primaryKey = [NSString stringWithFormat:@"State:/Network/Global/%@", type];
   CFDictionaryRef newValue = SCDynamicStoreCopyValue(dynStore, (CFStringRef)primaryKey);
   if (newValue) {
		//Get a key to look up the actual IPv4 info in the dynStore
		NSString *ipKey = [NSString stringWithFormat:@"State:/Network/Interface/%@/%@",
                           [(NSDictionary*)newValue objectForKey:@"PrimaryInterface"], type];
		CFDictionaryRef ipInfo = SCDynamicStoreCopyValue(dynStore, (CFStringRef)ipKey);
		if (ipInfo) {
			CFArrayRef addrs = CFDictionaryGetValue(ipInfo, CFSTR("Addresses"));
			if (addrs && CFArrayGetCount(addrs)) {
				CFStringRef ip = CFArrayGetValueAtIndex(addrs, 0);
				returnIP = [NSString stringWithString:(NSString*)ip];
			}
			CFRelease(ipInfo);
		}
	}   
   if (newValue)
      CFRelease(newValue);
   return returnIP;
}

-(void)updateAddresses
{
   NSMutableString *newString = nil;
   struct ifaddrs *interfaces = NULL;
   struct ifaddrs *current = NULL;
   
   if(getifaddrs(&interfaces) == 0)
   {
      current = interfaces;
      while (current != NULL) {
         NSString *currentString = nil;
         
         NSString *interface = [NSString stringWithUTF8String:current->ifa_name];
         
         if(![interface isEqualToString:@"lo0"] && ![interface isEqualToString:@"utun0"])
         {
            if (current->ifa_addr->sa_family == AF_INET) {
               char stringBuffer[INET_ADDRSTRLEN];
               struct sockaddr_in *ipv4 = (struct sockaddr_in *)current->ifa_addr;
               if (inet_ntop(AF_INET, &(ipv4->sin_addr), stringBuffer, INET_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            } else if (current->ifa_addr->sa_family == AF_INET6) {
               char stringBuffer[INET6_ADDRSTRLEN];
               struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)current->ifa_addr;
               if (inet_ntop(AF_INET6, &(ipv6->sin6_addr), stringBuffer, INET6_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            }          
            
            if(currentString && ![currentString isLocalHost]){
               if(!newString){
                  newString = [[currentString mutableCopy] autorelease];
               }else{
                  if(!routableArray)
                     self.routableArray = [NSMutableArray array];
                  [routableArray addObject:currentString];
                  [newString appendFormat:@"\n%@", currentString];
               }
            }
         }
         
         current = current->ifa_next;
      }
   }
   if(newString){
      self.routableCombined = newString;
   }else{
      self.routableCombined = nil;
      self.routableArray = nil;
   }
   freeifaddrs(interfaces);
   
   [[NSNotificationCenter defaultCenter] postNotificationName:IPAddressesUpdateNotification object:self];
   
   NSString *ipv4Primary = [self getPrimaryIPOfType:@"IPv4"];
   NSString *ipv6Primary = [self getPrimaryIPOfType:@"IPv6"];
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
