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

#include <sys/socket.h>
#include <sys/sockio.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <net/if_media.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

/* @"Link Status" == 1 seems to mean disconnected */
#define AIRPORT_DISCONNECTED 1

static struct ifmedia_description ifm_subtype_ethernet_descriptions[] = IFM_SUBTYPE_ETHERNET_DESCRIPTIONS;
static struct ifmedia_description ifm_shared_option_descriptions[] = IFM_SHARED_OPTION_DESCRIPTIONS;

typedef enum {
	HWGAirPortInterface,
	HWGEthernetInterface,
} NetworkInterfaceType;

@interface HWGrowlNetworkInterfaceStatus : NSObject;

@property (nonatomic, retain) NSString *interface;
@property (nonatomic, retain) NSDictionary *status;
@property (nonatomic, assign) NetworkInterfaceType type;

-(id)initForInterface:(NSString*)anInterface ofType:(NetworkInterfaceType)aType withStatus:(NSDictionary*)theStatus;

@end

@implementation HWGrowlNetworkInterfaceStatus

@synthesize interface;
@synthesize status;
@synthesize type;

-(id)initForInterface:(NSString *)anInterface 
					ofType:(NetworkInterfaceType)aType 
			  withStatus:(NSDictionary *)theStatus 
{
	if((self = [super init])){
		self.interface = anInterface;
		self.type = aType;
		self.status = theStatus;
	}
	return self;
}

- (void)dealloc
{
    [interface release];
    interface = nil;
    
    [status release];
    status = nil;
    
    [super dealloc];
}

@end

@interface HWGrowlNetworkMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;

@property (nonatomic, assign) SCDynamicStoreRef dynStore;
@property (nonatomic, assign) CFRunLoopSourceRef rlSrc;

@property (nonatomic, retain) NSMutableDictionary *networkInterfaceStates;
@property (nonatomic, retain) NSString *previousIPCombined;

@end

@implementation HWGrowlNetworkMonitor

@synthesize delegate;
@synthesize rlSrc;
@synthesize dynStore;
@synthesize networkInterfaceStates;
@synthesize previousIPCombined;

-(id)init {
	if((self = [super init])){
		self.previousIPCombined = nil;
		self.networkInterfaceStates = [NSMutableDictionary dictionary];
		[self startObserving];
	}
	return self;
}

-(void)dealloc {
	if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetMain(), rlSrc, kCFRunLoopDefaultMode);
   if (dynStore)
		CFRelease(dynStore);
	
	[networkInterfaceStates release];
    networkInterfaceStates = nil;
    
    [previousIPCombined release];
    previousIPCombined = nil;
    
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
	CFDictionaryRef interfaces = SCDynamicStoreCopyValue(dynStore, CFSTR("State:/Network/Interface"));
	NSArray *interfaceNames = [(NSDictionary*)interfaces objectForKey:@"Interfaces"];
	[interfaceNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if (![obj hasPrefix:@"en"] || [obj length] < 3 || !isdigit([obj characterAtIndex:2])) {
			return;
		}
		
		//Check against airport first
		NSString *key = [NSString stringWithFormat:@"State:/Network/Interface/%@/AirPort", obj];
		CFDictionaryRef status = SCDynamicStoreCopyValue(dynStore, (CFStringRef)key);
		if(status) {
			//NSLog(@"%@ is an AirPort link", obj);
			[self updateInterface:obj forType:HWGAirPortInterface withStatus:(NSDictionary*)status];			
			CFRelease(status);
			return;
		}
		
		key = [NSString stringWithFormat:@"State:/Network/Interface/%@/Link", obj];
		status = SCDynamicStoreCopyValue(dynStore, (CFStringRef)key);
		if(status) {
			//NSLog(@"%@ is an Ethernet link", obj);
			[self updateInterface:obj forType:HWGEthernetInterface withStatus:(NSDictionary*)status];			
			CFRelease(status);
			return;
		}
	}];
	CFRelease(interfaces);
}

-(void)updateInterface:(NSString*)interface forType:(NetworkInterfaceType)type withStatus:(NSDictionary*)status {
	HWGrowlNetworkInterfaceStatus *new = [[[HWGrowlNetworkInterfaceStatus alloc] initForInterface:interface
																														ofType:type
																												  withStatus:status] autorelease];	
	if(type == HWGAirPortInterface)
		[self updateAirportWithInterface:new];
	else if(type == HWGEthernetInterface)
		[self updateLinkWithInterface:new];
	
	[networkInterfaceStates setObject:new forKey:interface];
}

-(void)updateAirportWithInterface:(HWGrowlNetworkInterfaceStatus*)interface {
	NSString *interfaceString = [interface interface];
	NSDictionary *newValue = [interface status];
	NSDictionary *existing = [(HWGrowlNetworkInterfaceStatus*)[networkInterfaceStates objectForKey:interfaceString] status];
	//	NSLog(CFSTR("AirPort event"));
	
	NSData *newBSSID = nil;
	if (newValue)
		newBSSID = [newValue objectForKey:@"BSSID"];
	
	NSData *oldBSSID = nil;
	if (existing)
		oldBSSID = [existing objectForKey:@"BSSID"];
		
	if (newValue && ![oldBSSID isEqualToData:newBSSID] && !(newBSSID && oldBSSID && CFEqual(oldBSSID, newBSSID))) {
		NSNumber *linkStatus = [newValue objectForKey:@"Link Status"];
		NSNumber *powerStatus = [newValue objectForKey:@"Power Status"];
		if (linkStatus || powerStatus) {
			int status = 0;
			if (linkStatus) {
				status = [linkStatus intValue];
			} else if (powerStatus) {
				status = [powerStatus intValue];
				status = !status;
			}
			NSString *networkName = nil;
			if (status == AIRPORT_DISCONNECTED) {
				networkName = [existing objectForKey:@"SSID_STR"];
				if (!networkName)
					networkName = [existing objectForKey:@"SSID"];
				[self airportDisconnected:networkName];
			} else {
				networkName = [newValue objectForKey:@"SSID_STR"];
				if (!networkName)
					networkName = [newValue objectForKey:@"SSID"];
				if(networkName && newBSSID){
					[self airportConnected:networkName bssid:newBSSID];
				}
			}
		}
	}
}

-(void)airportDisconnected:(NSString*)networkName {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"Network-Wifi-Off" ofType:@"tif"];
    NSData *iconData = [NSData dataWithContentsOfFile:imagePath];
    [delegate notifyWithName:@"AirportDisconnected"
							 title:NSLocalizedString(@"AirPort Disconnected", @"")
					 description:[NSString stringWithFormat:NSLocalizedString(@"Left network %@.", @""), networkName]
							  icon:iconData
			  identifierString:@"HWGrowlAirPort"
				  contextString:nil 
							plugin:self];
}

-(void)airportConnected:(NSString*)name bssid:(NSData*)data {
	const unsigned char *bssidBytes = [data bytes];
	
	NSString *bssid = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
							 bssidBytes[0],
							 bssidBytes[1],
							 bssidBytes[2],
							 bssidBytes[3],
							 bssidBytes[4],
							 bssidBytes[5]];
	NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Joined network.\nSSID:\t\t%@\nBSSID:\t%@", ""),
									 name,
									 bssid];
	
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"Network-Wifi-4" ofType:@"tif"];
    NSData *iconData = [NSData dataWithContentsOfFile:imagePath];

	[delegate notifyWithName:@"AirportConnected"
							 title:NSLocalizedString(@"AirPort Connected", @"")
					 description:description
							  icon:iconData
			  identifierString:@"HWGrowlAirPort"
				  contextString:nil
							plugin:self];
}

-(void)updateLinkWithInterface:(HWGrowlNetworkInterfaceStatus*)interface {
	NSString *interfaceString = [interface interface];
	NSDictionary *newValue = [interface status];
	NSDictionary *existing = [(HWGrowlNetworkInterfaceStatus*)[networkInterfaceStates objectForKey:interfaceString] status];
	int newActive = [[newValue objectForKey:@"Active"] intValue];
	int oldActive = [[existing objectForKey:@"Active"] intValue];
	
	NSString *noteName = nil;
	NSString *noteTitle = nil;
	NSString *noteDescription = nil;
	NSString *imageName = nil;
	if (newActive && !oldActive) {
		noteName = @"NetworkLinkUp";
		noteTitle = NSLocalizedString(@"Network Link Up", @"");
		noteDescription = [NSString stringWithFormat:
								 NSLocalizedString(@"Interface:\t%@\nMedia:\t%@", "The first %@ will be replaced with the interface (en0, en1, etc) second %@ will be replaced by a description of the Ethernet media such as '100BT/full-duplex'"),
								 interfaceString,
								 [self getMediaForInterface:interfaceString]];
		imageName = @"Network-Ethernet-On";
	} else if (!newActive && oldActive) {
		noteName = @"NetworkLinkDown";
		noteTitle = NSLocalizedString(@"Network Link Down", @"");
		noteDescription = [NSString stringWithFormat:NSLocalizedString(@"Interface:\t%@", nil), interfaceString];
		imageName = @"Network-Ethernet-Off";
	}
	
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    NSData *iconData = [NSData dataWithContentsOfFile:imagePath];
   
	if(noteName){
		[delegate notifyWithName:noteName
								 title:noteTitle
						 description:noteDescription
								  icon:iconData
				  identifierString:@"HWGrowlNetworkLink"
					  contextString:nil
								plugin:self];
	}
}

/* TO DO: REWRITE ME WITH BETTER METHODS OF GETTING INFO */
- (NSString *)getMediaForInterface:(NSString*)interfaceString {
	// This is all made by looking through Darwin's src/network_cmds/ifconfig.tproj.
	// There's no pretty way to get media stuff; I've stripped it down to the essentials
	// for what I'm doing.
	
	const char *interface = [interfaceString UTF8String];
	size_t length = strlen(interface);
	if (length >= IFNAMSIZ)
		NSLog(@"Interface name too long");
	
	int s = socket(AF_INET, SOCK_DGRAM, 0);
	if (s < 0) {
		NSLog(@"Can't open datagram socket");
		return NULL;
	}
	struct ifmediareq ifmr;
	memset(&ifmr, 0, sizeof(ifmr));
	strncpy(ifmr.ifm_name, interface, sizeof(ifmr.ifm_name));
	
	if (ioctl(s, SIOCGIFMEDIA, (caddr_t)&ifmr) < 0) {
		// Media not supported.
		close(s);
		return NULL;
	}
	
	close(s);
	
	// Now ifmr.ifm_current holds the selected type (probably auto-select)
	// ifmr.ifm_active holds details (100baseT <full-duplex> or similar)
	// We only want the ifm_active bit.
	
	const char *type = "Unknown";
	
	// We'll only look in the Ethernet list. I don't care about anything else.
	struct ifmedia_description *desc;
	for (desc = ifm_subtype_ethernet_descriptions; desc->ifmt_string; ++desc) {
		if (IFM_SUBTYPE(ifmr.ifm_active) == desc->ifmt_word) {
			type = desc->ifmt_string;
			break;
		}
	}
	
	NSMutableString *options = nil;
	
	// And fill in the duplex settings.
	for (desc = ifm_shared_option_descriptions; desc->ifmt_string; desc++) {
		if (ifmr.ifm_active & desc->ifmt_word) {
			if (options) {
				[options appendFormat:@",%s", desc->ifmt_string];
			} else {
				options = [NSMutableString stringWithUTF8String:desc->ifmt_string];
			}
		}
	}
	
	NSString *media;
	if (options) {
		media = [NSString stringWithFormat:@"%s <%@>",
					type,
					options];
	} else {
		media = [NSString stringWithUTF8String:type];
	}
	
	return media;
}

-(void)updateIP {
	NSArray *routable = [GrowlNetworkUtilities routableIPAddresses];
	NSString *combined = [routable componentsJoinedByString:@"\n"];
	if([combined isEqualToString:previousIPCombined])
		return;
		
	NSString *imageName = nil;
	if([combined isEqualToString:@""]) {
		combined = nil;
		imageName = @"Network-Generic-Off";
	}else{
		imageName = @"Network-Generic-On";
	}

    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    NSData *iconData = [NSData dataWithContentsOfFile:imagePath];
	[delegate notifyWithName:@"IPAddressChange"
							 title:NSLocalizedString(@"IP Addresses Updated", @"")
					 description:combined ? combined : NSLocalizedString(@"No routable IP addresses", @"")
							  icon:iconData
			  identifierString:@"HWGrowlIPAddressChange"
				  contextString:nil
							plugin:self];
	
	self.previousIPCombined = combined;
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
	return NSLocalizedString(@"Network Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsNetwork"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"IPAddressChange", @"NetworkLinkUp", @"NetworkLinkDown", @"AirportConnected", @"AirportDisconnected", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"IP Address Changed", @""), @"IPAddressChange",
			  NSLocalizedString(@"Network Link Up", @""), @"NetworkLinkUp",
			  NSLocalizedString(@"Network Link Down", @""), @"NetworkLinkDown", 
			  NSLocalizedString(@"AirPort Connected", @""), @"AirportConnected", 
			  NSLocalizedString(@"AirPort Disconnected", @""), @"AirportDisconnected", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sent when the systems IP address changes", @""), @"IPAddressChange", 
			  NSLocalizedString(@"Sent when an Ethernet link starts", @""), @"NetworkLinkUp",
			  NSLocalizedString(@"Sent when an Ethernet link goes down", @""), @"NetworkLinkDown", 
			  NSLocalizedString(@"Sent when AirPort connects to a network", @""), @"AirportConnected", 
			  NSLocalizedString(@"Sent when AirPort disconnects from a network", @""), @"AirportDisconnected", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"IPAddressChange", @"NetworkLinkUp", @"NetworkLinkDown", @"AirportConnected", @"AirportDisconnected", nil];
}

@end
