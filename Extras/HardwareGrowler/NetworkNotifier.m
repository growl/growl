//
//  NetworkNotifier.c
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//  Copyright (C) 2004 Scott Lamb <slamb@slamb.org>
//

#import <Cocoa/Cocoa.h>

#include "NetworkNotifier.h"
#include "AppController.h"
#include <SystemConfiguration/SystemConfiguration.h>

// Media stuff
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

static CFDictionaryRef airportStatus;

/** A reference to the SystemConfiguration dynamic store. */
static SCDynamicStoreRef dynStore;

/** Our run loop source for notification. */
static CFRunLoopSourceRef rlSrc;

static struct ifmedia_description ifm_subtype_ethernet_descriptions[] = IFM_SUBTYPE_ETHERNET_DESCRIPTIONS;
static struct ifmedia_description ifm_shared_option_descriptions[] = IFM_SHARED_OPTION_DESCRIPTIONS;

@implementation NetworkNotifier

- (NSString *)getMediaForInterface:(const char *)interface {
	// This is all made by looking through Darwin's src/network_cmds/ifconfig.tproj.
	// There's no pretty way to get media stuff; I've stripped it down to the essentials
	// for what I'm doing.

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

- (void)linkStatusChange:(NSDictionary *)newValue {
	int active = [[newValue objectForKey:@"Active"] intValue];
	
	if (active) {
		NSString *media = [self getMediaForInterface:"en0"];
		NSString *desc = [NSString stringWithFormat:
						  NSLocalizedString(@"Interface:\ten0\nMedia:\t%@", "The %@ will be replaced by a description of the Ethernet media such as '100BT/full-duplex'"),
						  media];
		AppController_linkUp((CFStringRef)desc);
	} else
		AppController_linkDown((CFStringRef)NSLocalizedString(@"Interface:\ten0", nil));
}

/*
 The following comments are for the benefit of genstrings:
 
 NSLocalizedString(@"Private", "Type of IP address")
 NSLocalizedString(@"Private", "Type of IP address")
 NSLocalizedString(@"Private", "Type of IP address")
 NSLocalizedString(@"Loopback", "Type of IP address")
 NSLocalizedString(@"Link-local", "Type of IP address")
 NSLocalizedString(@"Test", "Type of IP address")
 NSLocalizedString(@"6to4 relay", "Type of IP address")
 NSLocalizedString(@"Benchmark", "Type of IP address")
 NSLocalizedString(@"Reserved", "Type of IP address")
 */	 
- (NSString *)typeOfIP:(CFStringRef)ipString {
	static struct {
		in_addr_t network;
		in_addr_t netmask;
		NSString *type;
	} const types[9] = {
		// RFC 1918 addresses
		{ 0x0A000000, 0xFF000000, @"Private" }, 		// 10.0.0.0/8
		{ 0xAC100000, 0xFFF00000, @"Private" }, 		// 172.16.0.0/12
		{ 0xC0A80000, 0xFFFF0000, @"Private" }, 		// 192.168.0.0/16
		// Other RFC 3330 addresses
		{ 0x7F000000, 0xFF000000, @"Loopback" },		// 127.0.0.0/8
		{ 0xA9FE0000, 0xFFFF0000, @"Link-local" },	// 169.254.0.0/16
		{ 0xC0000200, 0xFFFFFF00, @"Test" },			// 192.0.2.0/24
		{ 0xC0586200, 0xFFFFFF00, @"6to4 relay" },	// 192.88.99.0/24
		{ 0xC6120000, 0xFFFE0000, @"Benchmark" },		// 198.18.0.0/15
		{ 0xF0000000, 0xF0000000, @"Reserved" }		// 240.0.0.0/4
	};
	struct in_addr addr;
	char ip[16];
	CFStringGetCString(ipString, ip, sizeof(ip), kCFStringEncodingASCII);
	if (inet_pton(AF_INET, ip, &addr) > 0) {
		uint32_t a = ntohl(addr.s_addr);
		for (unsigned i=0U; i<9; ++i) {
			if ((a & types[i].netmask) == types[i].network) {
				return [[NSBundle bundleForClass:[self class]] localizedStringForKey:types[i].type
																			  value:types[i].type
																			  table:nil];
			}
		}
	}
	
	return NSLocalizedString(@"Public", "Type of IP address");
}

- (void)ipAddressChange:(NSDictionary *)newValue {
	if (newValue) {
		//Get a key to look up the actual IPv4 info in the dynStore
		NSString *ipv4Key = [NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4",
							 [newValue objectForKey:@"PrimaryInterface"]];
		CFDictionaryRef ipv4Info = SCDynamicStoreCopyValue(dynStore, (CFStringRef)ipv4Key);
		if (ipv4Info) {
			CFArrayRef addrs = CFDictionaryGetValue(ipv4Info, CFSTR("Addresses"));
			if (addrs && CFArrayGetCount(addrs)) {
				CFStringRef ip = CFArrayGetValueAtIndex(addrs, 0);
				AppController_ipAcquired(ip, (CFStringRef)[self typeOfIP:ip]);
			}
			CFRelease(ipv4Info);
		}
	} else
		AppController_ipReleased();
}

- (void)airportStatusChange:(NSDictionary *)newValue {
//	NSLog(CFSTR("AirPort event"));

	CFDataRef newBSSID = NULL;
	if (newValue)
		newBSSID = (CFDataRef)[newValue objectForKey:@"BSSID"];

	CFDataRef oldBSSID = NULL;
	if (airportStatus)
		oldBSSID = CFDictionaryGetValue(airportStatus, CFSTR("BSSID"));

	if (newValue && oldBSSID != newBSSID && !(newBSSID && oldBSSID && CFEqual(oldBSSID, newBSSID))) {
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
			if (status == AIRPORT_DISCONNECTED) {
				CFStringRef networkName = CFDictionaryGetValue(airportStatus, CFSTR("SSID_STR"));
				if (!networkName)
					networkName = CFDictionaryGetValue(airportStatus, CFSTR("SSID"));
				AppController_airportDisconnect(networkName);
			} else {
				NSString *networkName = [newValue objectForKey:@"SSID_STR"];
				if (!networkName)
					networkName = [newValue objectForKey:@"SSID"];
				AppController_airportConnect((CFStringRef)networkName, CFDataGetBytePtr(newBSSID));
			}
		}
	}

	if (airportStatus)
		CFRelease(airportStatus);

	if (newValue)
		airportStatus = CFRetain(newValue);
	else
		airportStatus = NULL;
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	NetworkNotifier *self = info;

	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
		if (CFStringCompare(key,
							CFSTR("State:/Network/Interface/en0/Link"),
							0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			[self linkStatusChange:(NSDictionary *)newValue];
			if (newValue)
				CFRelease(newValue);
		} else if (CFStringCompare(key,
								   CFSTR("State:/Network/Global/IPv4"),
								   0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			[self ipAddressChange:(NSDictionary *)newValue];
			if (newValue)
				CFRelease(newValue);
		} else if (CFStringCompare(key,
								   CFSTR("State:/Network/Interface/en1/AirPort"),
								   0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			[self airportStatusChange:(NSDictionary *)newValue];
			if (newValue)
				CFRelease(newValue);
		}
	}
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};

	dynStore = SCDynamicStoreCreate(kCFAllocatorDefault,
									CFBundleGetIdentifier(CFBundleGetMainBundle()),
									scCallback,
									&context);
	if (!dynStore) {
		NSLog(@"SCDynamicStoreCreate() failed: %s", SCErrorString(SCError()));
		[self release];
		return nil;
	}
	
	const CFStringRef keys[3] = {
		CFSTR("State:/Network/Interface/en0/Link"),
		CFSTR("State:/Network/Global/IPv4"),
		CFSTR("State:/Network/Interface/en1/AirPort")
	};
	CFArrayRef watchedKeys = CFArrayCreate(kCFAllocatorDefault,
										   (const void **)keys,
										   3,
										   &kCFTypeArrayCallBacks);
	if (!SCDynamicStoreSetNotificationKeys(dynStore,
										   watchedKeys,
										   NULL)) {
		CFRelease(watchedKeys);
		NSLog(@"SCDynamicStoreSetNotificationKeys() failed: %s", SCErrorString(SCError()));
		CFRelease(dynStore);
		dynStore = NULL;
		
		[self release];
		return nil;
	}
	CFRelease(watchedKeys);
	
	rlSrc = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynStore, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
	CFRelease(rlSrc);
	
	airportStatus = SCDynamicStoreCopyValue(dynStore, CFSTR("State:/Network/Interface/en1/AirPort"));
	
	return self;
}

- (void)dealloc {
	if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
	if (dynStore)
		CFRelease(dynStore);
	if (airportStatus)
		CFRelease(airportStatus);
	
	[super dealloc];
}

@end
