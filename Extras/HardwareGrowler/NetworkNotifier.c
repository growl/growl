//
//  NetworkNotifier.c
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//  Copyright (C) 2004 Scott Lamb <slamb@slamb.org>
//

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

extern void NSLog(CFStringRef format, ...);

/* @"Link Status" == 1 seems to mean disconnected */
#define AIRPORT_DISCONNECTED 1

static CFDictionaryRef airportStatus;

/** A reference to the SystemConfiguration dynamic store. */
static SCDynamicStoreRef dynStore;

/** Our run loop source for notification. */
static CFRunLoopSourceRef rlSrc;

static struct ifmedia_description ifm_subtype_ethernet_descriptions[] = IFM_SUBTYPE_ETHERNET_DESCRIPTIONS;
static struct ifmedia_description ifm_shared_option_descriptions[] = IFM_SHARED_OPTION_DESCRIPTIONS;

static CFStringRef getMediaForInterface(const char *interface) {
	// This is all made by looking through Darwin's src/network_cmds/ifconfig.tproj.
	// There's no pretty way to get media stuff; I've stripped it down to the essentials
	// for what I'm doing.

	unsigned length = strlen(interface);
	if (length >= IFNAMSIZ)
		NSLog(CFSTR("Interface name too long"));

	int s = socket(AF_INET, SOCK_DGRAM, 0);
	if (s < 0) {
		NSLog(CFSTR("Can't open datagram socket"));
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

	CFMutableStringRef options = nil;

	// And fill in the duplex settings.
	for (desc = ifm_shared_option_descriptions; desc->ifmt_string; desc++) {
		if (ifmr.ifm_active & desc->ifmt_word) {
			if (options) {
				CFStringAppend(options, CFSTR(","));
				CFStringAppendCString(options, desc->ifmt_string, kCFStringEncodingASCII);
			} else {
				options = CFStringCreateMutable(kCFAllocatorDefault, 0);
				CFStringAppendCString(options, desc->ifmt_string, kCFStringEncodingASCII);
			}
		}
	}

	CFStringRef media;
	if (options) {
		media = CFStringCreateWithFormat(kCFAllocatorDefault,
										 NULL,
										 CFSTR("%s <%@>"),
										 type,
										 options);
		CFRelease(options);
	} else {
		media = CFStringCreateWithCString(kCFAllocatorDefault,
										  type,
										  kCFStringEncodingASCII);
	}

	return media;
}

static void linkStatusChange(CFDictionaryRef newValue) {
	int active;
	if (newValue) {
		CFNumberRef num = CFDictionaryGetValue(newValue, CFSTR("Active"));
		if (num)
			CFNumberGetValue(num, kCFNumberIntType, &active);
		else
			active = 0;
	} else
		active = 0;

	if (active) {
		CFStringRef media = getMediaForInterface("en0");
		CFStringRef desc = CFStringCreateWithFormat(kCFAllocatorDefault,
													NULL,
													CFSTR("Interface:\ten0\nMedia:\t%@"),
													media);
		if (media)
			CFRelease(media);
		AppController_linkUp(desc);
		CFRelease(desc);
	} else
		AppController_linkDown(CFSTR("Interface:\ten0"));
}

static CFStringRef typeOfIP(CFStringRef ipString) {
	static struct {
		in_addr_t network;
		in_addr_t netmask;
		CFStringRef type;
	} const types[9] = {
		// RFC 1918 addresses
		{ 0x0A000000, 0xFF000000, CFSTR("Private") }, 		// 10.0.0.0/8
		{ 0xAC100000, 0xFFF00000, CFSTR("Private") }, 		// 172.16.0.0/12
		{ 0xC0A80000, 0xFFFF0000, CFSTR("Private") }, 		// 192.168.0.0/16
		// Other RFC 3330 addresses
		{ 0x7F000000, 0xFF000000, CFSTR("Loopback") },		// 127.0.0.0/8
		{ 0xA9FE0000, 0xFFFF0000, CFSTR("Link-local") },	// 169.254.0.0/16
		{ 0xC0000200, 0xFFFFFF00, CFSTR("Test") },			// 192.0.2.0/24
		{ 0xC0586200, 0xFFFFFF00, CFSTR("6to4 relay") },	// 192.88.99.0/24
		{ 0xC6120000, 0xFFFE0000, CFSTR("Benchmark") },		// 198.18.0.0/15
		{ 0xF0000000, 0xF0000000, CFSTR("Reserved") }		// 240.0.0.0/4
	};
	struct in_addr addr;
	char ip[16];
	CFStringGetCString(ipString, ip, sizeof(ip), kCFStringEncodingASCII);
	if (inet_pton(AF_INET, ip, &addr) > 0)
		for (unsigned i=0U; i<9; ++i)
			if ((addr.s_addr & types[i].netmask) == types[i].network)
				return types[i].type;
	return CFSTR("Public");
}

static void ipAddressChange(CFDictionaryRef newValue) {
	if (newValue) {
//		NSLog(CFSTR("IP address acquired"));
		CFStringRef ipv4Key = CFStringCreateWithFormat(kCFAllocatorDefault,
													   NULL,
													   CFSTR("State:/Network/Interface/%@/IPv4"),
													   CFDictionaryGetValue(newValue, CFSTR("PrimaryInterface")));
		CFDictionaryRef ipv4Info = SCDynamicStoreCopyValue(dynStore, ipv4Key);
		CFRelease(ipv4Key);
		if (ipv4Info) {
			CFArrayRef addrs = CFDictionaryGetValue(ipv4Info, CFSTR("Addresses"));
			if (addrs && CFArrayGetCount(addrs)) {
				CFStringRef ip = CFArrayGetValueAtIndex(addrs, 0);
				AppController_ipAcquired(ip, typeOfIP(ip));
			}
			CFRelease(ipv4Info);
		}
	} else
		AppController_ipReleased();
}

static void airportStatusChange(CFDictionaryRef newValue) {
//	NSLog(CFSTR("AirPort event"));
	CFDataRef newBSSID = CFDictionaryGetValue(newValue, CFSTR("BSSID"));
	if (!(airportStatus && CFEqual(CFDictionaryGetValue(airportStatus, CFSTR("BSSID")), newBSSID))) {
		int status;
		CFNumberRef linkStatus = CFDictionaryGetValue(newValue, CFSTR("Link Status"));
		if (linkStatus) {
			CFNumberGetValue(linkStatus, kCFNumberIntType, &status);
			if (status == AIRPORT_DISCONNECTED)
				AppController_airportDisconnect(CFDictionaryGetValue(airportStatus, CFSTR("SSID")));
			else
				AppController_airportConnect(CFDictionaryGetValue(newValue, CFSTR("SSID")), CFDataGetBytePtr(newBSSID));
		}
	}
	if (airportStatus)
		CFRelease(airportStatus);
	airportStatus = CFRetain(newValue);
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
#pragma unused(info)
	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
		if (CFStringCompare(key,
							CFSTR("State:/Network/Interface/en0/Link"),
							0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			linkStatusChange(newValue);
			if (newValue)
				CFRelease(newValue);
		} else if (CFStringCompare(key,
								   CFSTR("State:/Network/Global/IPv4"),
								   0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			ipAddressChange(newValue);
			if (newValue)
				CFRelease(newValue);
		} else if (CFStringCompare(key,
								   CFSTR("State:/Network/Interface/en1/AirPort"),
								   0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			airportStatusChange(newValue);
			if (newValue)
				CFRelease(newValue);
		}
	}
}

void NetworkNotifier_init(void) {
	dynStore = SCDynamicStoreCreate(kCFAllocatorDefault,
									CFBundleGetIdentifier(CFBundleGetMainBundle()),
									scCallback,
									/*context*/ NULL);
	if (!dynStore) {
		NSLog(CFSTR("SCDynamicStoreCreate() failed: %s"),
			  SCErrorString(SCError()));
		return;
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
		NSLog(CFSTR("SCDynamicStoreSetNotificationKeys() failed: %s"),
			  SCErrorString(SCError()));
		CFRelease(dynStore);
	}
	CFRelease(watchedKeys);

	rlSrc = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynStore, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
	CFRelease(rlSrc);

	airportStatus = SCDynamicStoreCopyValue(dynStore, CFSTR("State:/Network/Interface/en1/AirPort"));
}

void NetworkNotifier_dealloc(void) {
	if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
	if (dynStore)
		CFRelease(dynStore);
	if (airportStatus)
		CFRelease(airportStatus);
}
