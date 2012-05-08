//
//  HWGrowlNetworkMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlNetworkMonitor.h"
#import "GrowlNetworkUtilities.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface HWGrowlNetworkMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;

@property (nonatomic, assign) SCDynamicStoreRef dynStore;
@property (nonatomic, assign) CFRunLoopSourceRef rlSrc;

@end

@implementation HWGrowlNetworkMonitor

@synthesize delegate;
@synthesize rlSrc;
@synthesize dynStore;

-(id)init {
	if((self = [super init])){
		[self startObserving];
	}
	return self;
}

-(void)dealloc {
	if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetMain(), rlSrc, kCFRunLoopDefaultMode);
   if (dynStore)
		CFRelease(dynStore);
	[super dealloc];
}

-(void)fireOnLaunchNotes {
	[self networkChanged];
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

-(void)networkChanged {
	[self updateInterfaces];
	[self updateIP];
}

-(void)updateInterfaces {
	
}

-(void)updateIP {
	NSArray *routable = [GrowlNetworkUtilities routableIPAddresses];
	NSString *combined = [routable componentsJoinedByString:@"\n"];
	if([combined isEqualToString:@""])
		combined = nil;
	
	[delegate notifyWithName:@"IPAddressChange"
							 title:@"IP Addresses Updated"
					 description:combined ? combined : @"No routable IP addresses"
							  icon:nil
			  identifierString:@"HWGrowlIPAddressChange"
				  contextString:nil
							plugin:self];
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	HWGrowlNetworkMonitor *observer = info;
	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
      if (CFStringCompare(key, CFSTR("State:/Network/Interface"), 0) == kCFCompareEqualTo) {
			[observer networkChanged];
		}
	}
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return @"Network Monitor";
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObject:@"IPAddressChange"];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObject:@"IP Address Changed" forKey:@"IPAddressChange"];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObject:@"Sent when the systems IP address changes" forKey:@"IPAddressChange"];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObject:@"IPAddressChange"];
}

@end
