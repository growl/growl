//
//  NetworkNotifier.m
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//  Copyright (C) 2004 Scott Lamb <slamb@slamb.org>
//

#include "NetworkNotifier.h"
#include <SystemConfiguration/SystemConfiguration.h>

// Media stuff
#include <sys/socket.h>
#include <sys/sockio.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <net/if_media.h>
#include <unistd.h>

extern void NSLog(CFStringRef format, ...);

/* @"Link Status" == 1 seems to mean disconnected */
#define AIRPORT_DISCONNECTED 1

static CFDictionaryRef airportStatus;

/** A reference to the SystemConfiguration dynamic store. */
static SCDynamicStoreRef dynStore;

/** Our run loop source for notification. */
static CFRunLoopSourceRef rlSrc;

static struct NetworkNotifierCallbacks callbacks;

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
	for (desc = ifm_subtype_ethernet_descriptions; desc->ifmt_string; desc++) {
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
										 0,
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
	CFNumberRef num = CFDictionaryGetValue(newValue, CFSTR("Active"));
	if (num)
		CFNumberGetValue(num, kCFNumberIntType, &active);
	else
		active = 0;

	if (active) {
		CFStringRef media = getMediaForInterface("en0");
		CFStringRef desc = CFStringCreateWithFormat(kCFAllocatorDefault,
													0,
													CFSTR("Interface:\ten0\nMedia:\t%@"),
													media);
		CFRelease(media);
		NSLog(CFSTR("Ethernet cable plugged"));
		if (callbacks.linkUp)
			callbacks.linkUp(desc);
		CFRelease(desc);
	} else if (callbacks.linkDown) {
		callbacks.linkDown(CFSTR("Interface:\ten0"));
	}
}

static void ipAddressChange(CFDictionaryRef newValue) {
	if (newValue) {
		NSLog(CFSTR("IP address acquired"));
		CFStringRef ipv4Key = CFStringCreateWithFormat(kCFAllocatorDefault,
													   0,
													   CFSTR("State:/Network/Interface/%@/IPv4"),
													   CFDictionaryGetValue(newValue, CFSTR("PrimaryInterface")));
		CFDictionaryRef ipv4Info = SCDynamicStoreCopyValue(dynStore, ipv4Key);
		CFRelease(ipv4Key);
		CFArrayRef addrs = CFDictionaryGetValue(ipv4Info, CFSTR("Addresses"));
		if (CFArrayGetCount(addrs)) {
			if (callbacks.ipAcquired)
				callbacks.ipAcquired(CFArrayGetValueAtIndex(addrs, 0));
		} else {
			NSLog(CFSTR("Empty address array"));
		}
		CFRelease(ipv4Info);
	} else if (callbacks.ipReleased) {
		callbacks.ipReleased();
	}
}

static void airportStatusChange(CFDictionaryRef newValue) {
	NSLog(CFSTR("AirPort event"));
	if (!CFEqual(CFDictionaryGetValue(airportStatus, CFSTR("BSSID")), CFDictionaryGetValue(newValue, CFSTR("BSSID")))) {
		int status;
		CFNumberRef linkStatus = CFDictionaryGetValue(newValue, CFSTR("Link Status"));
		if (linkStatus) {
			CFNumberGetValue(linkStatus, kCFNumberIntType, &status);
			if (status == AIRPORT_DISCONNECTED) {
				if (callbacks.airportDisconnect) {
					CFStringRef desc = CFStringCreateWithFormat(kCFAllocatorDefault,
																0,
																CFSTR("Left network %@."),
																CFDictionaryGetValue(airportStatus, CFSTR("SSID")));
					callbacks.airportDisconnect(desc);
					CFRelease(desc);
				}
			} else if (callbacks.airportConnect) {
				const unsigned char *bssidBytes = CFDataGetBytePtr(CFDictionaryGetValue(newValue, CFSTR("BSSID")));
				CFStringRef desc = CFStringCreateWithFormat(kCFAllocatorDefault,
															0,
															CFSTR("Joined network.\nSSID:\t\t%@\nBSSID:\t%02X:%02X:%02X:%02X:%02X:%02X"),
															CFDictionaryGetValue(newValue, CFSTR("SSID")),
															bssidBytes[0],
															bssidBytes[1],
															bssidBytes[2],
															bssidBytes[3],
															bssidBytes[4],
															bssidBytes[5]);
				callbacks.airportConnect(desc);
				CFRelease(desc);
			}
		}
	}
	airportStatus = CFRetain(newValue);
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
#pragma unused(info)
	CFIndex count = CFArrayGetCount(changedKeys);
	for (int i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
		if (CFStringCompare(key,
							CFSTR("State:/Network/Interface/en0/Link"),
							0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			linkStatusChange(newValue);
			CFRelease(newValue);
		} else if (CFStringCompare(key,
								   CFSTR("State:/Network/Global/IPv4"),
								   0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			ipAddressChange(newValue);
			CFRelease(newValue);
		} else if (CFStringCompare(key,
								   CFSTR("State:/Network/Interface/en1/AirPort"),
								   0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			airportStatusChange(newValue);
			CFRelease(newValue);
		}
	}
}

void NetworkNotifier_init(const struct NetworkNotifierCallbacks *c) {
	callbacks = *c;

	SCDynamicStoreContext context = {
		.version			= 0,
		.info				= NULL,
		.retain				= NULL,
		.release			= NULL,
		.copyDescription	= NULL
	};

	dynStore = SCDynamicStoreCreate(kCFAllocatorDefault,
									CFBundleGetIdentifier(CFBundleGetMainBundle()),
									scCallback,
									&context);
	rlSrc = SCDynamicStoreCreateRunLoopSource(NULL, dynStore, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopCommonModes);
	CFStringRef keys[3] = {
		CFSTR("State:/Network/Interface/en0/Link"),
		CFSTR("State:/Network/Global/IPv4"),
		CFSTR("State:/Network/Interface/en1/AirPort")
	};
	CFArrayRef watchedKeys = CFArrayCreate(kCFAllocatorDefault,
										   (const void **)keys,
										   3,
										   &kCFTypeArrayCallBacks);
	SCDynamicStoreSetNotificationKeys(dynStore,
									  watchedKeys,
									  NULL);
	CFRelease(watchedKeys);
	airportStatus = SCDynamicStoreCopyValue(dynStore, CFSTR("State:/Network/Interface/en1/AirPort"));
}

void NetworkNotifier_dealloc(void) {
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopCommonModes);	
	CFRelease(rlSrc);
	CFRelease(dynStore);
	CFRelease(airportStatus);
}
