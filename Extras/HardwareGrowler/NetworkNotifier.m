//
//  NetworkNotifier.m
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//  Copyright (C) 2004 Scott Lamb <slamb@slamb.org>
//

#import "NetworkNotifier.h"
#import "SCDynamicStore.h"
#import <Growl/Growl.h>

// Media stuff
#import <sys/socket.h>
#import <sys/sockio.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <net/if_media.h>
#import <unistd.h>

/* @"Link Status" == 1 seems to mean disconnected */
#define AIRPORT_DISCONNECTED 1

NSString *NotifierNetworkLinkUpNotification				= @"Link-Up";
NSString *NotifierNetworkLinkDownNotification			= @"Link-Down";
NSString *NotifierNetworkIpAcquiredNotification			= @"IP-Acquired";
NSString *NotifierNetworkIpReleasedNotification			= @"IP-Released";
NSString *NotifierNetworkAirportConnectNotification		= @"AirPort-Connect";
NSString *NotifierNetworkAirportDisconnectNotification	= @"AirPort-Disconnect";

static struct ifmedia_description ifm_subtype_ethernet_descriptions[] = IFM_SUBTYPE_ETHERNET_DESCRIPTIONS;
static struct ifmedia_description ifm_shared_option_descriptions[] = IFM_SHARED_OPTION_DESCRIPTIONS;

@interface NetworkNotifier (PRIVATE)
- (void)linkStatusChange:(NSDictionary*)newValue;
- (void)ipAddressChange:(NSDictionary*)newValue;
- (void)airportStatusChange:(NSDictionary*)newValue;
- (NSString *)getMediaForInterface:(NSString*)anInterface;
@end

@implementation NetworkNotifier
- (id)init
{
	if ( (self = [super init]) ) {
		airportStatus = nil;

		scNotificationManager = [[SCDynamicStore alloc] init];
		[scNotificationManager addObserver:self
								  selector:@selector(linkStatusChange:)
									forKey:@"State:/Network/Interface/en0/Link"];
		[scNotificationManager addObserver:self
								  selector:@selector(ipAddressChange:)
									forKey:@"State:/Network/Global/IPv4"];
		[scNotificationManager addObserver:self
								  selector:@selector(airportStatusChange:)
									forKey:@"State:/Network/Interface/en1/AirPort"];
		airportStatus = [[scNotificationManager valueForKey:@"State:/Network/Interface/en1/AirPort"] retain];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:nil
												  object:scNotificationManager];
	[airportStatus release];
	[scNotificationManager release];
	[super dealloc];
}

- (void)linkStatusChange:(NSDictionary*)newValue
{
	BOOL active = [[newValue objectForKey:@"Active"] boolValue];

	if (active) {
		NSString *media = [self getMediaForInterface:@"en0"];
		NSString *desc = [NSString stringWithFormat:@"Interface:\ten0\nMedia:\t%@", media];
		NSLog(@"Ethernet cable plugged");
		[[NSNotificationCenter defaultCenter] postNotificationName:NotifierNetworkLinkUpNotification
															object:desc];
	} else {
		NSString *desc = @"Interface:\ten0";
		[[NSNotificationCenter defaultCenter] postNotificationName:NotifierNetworkLinkDownNotification
															object:desc];
	}		
}

- (void)ipAddressChange:(NSDictionary*)newValue
{
	if (newValue) {
		NSLog(@"IP address acquired");
		NSString *ipv4Key = [NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4",
			[newValue valueForKey:@"PrimaryInterface"]];
		NSDictionary *ipv4Info = [scNotificationManager valueForKey:ipv4Key];
		NSArray *addrs = [ipv4Info valueForKey:@"Addresses"];
		NSAssert([addrs count] > 0, @"Empty address array");
		[[NSNotificationCenter defaultCenter] postNotificationName:NotifierNetworkIpAcquiredNotification
															object:[addrs objectAtIndex:0]];
	} else {
		NSLog(@"No primary interface");
		[[NSNotificationCenter defaultCenter] postNotificationName:NotifierNetworkIpReleasedNotification
															object:nil];
	}
}

- (void)airportStatusChange:(NSDictionary*)newValue
{
	NSLog(@"AirPort event");
	if (![[airportStatus objectForKey:@"BSSID"] isEqualToData:[newValue objectForKey:@"BSSID"]]) {
		if ([[newValue objectForKey:@"Link Status"] intValue] == AIRPORT_DISCONNECTED) {
			NSString *desc = [NSString stringWithFormat:@"Left network %@.",
				[airportStatus objectForKey:@"SSID"]];
			[[NSNotificationCenter defaultCenter] postNotificationName:NotifierNetworkAirportDisconnectNotification
																object:desc];
		} else {
			const unsigned char *bssidBytes = [[newValue objectForKey:@"BSSID"] bytes];
			NSString *bssid = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
				bssidBytes[0],
				bssidBytes[1],
				bssidBytes[2],
				bssidBytes[3],
				bssidBytes[4],
				bssidBytes[5]];
			NSString *desc = [NSString stringWithFormat:@"Joined network.\nSSID:\t\t%@\nBSSID:\t%@",
				[newValue objectForKey:@"SSID"],
				bssid];
			[[NSNotificationCenter defaultCenter] postNotificationName:NotifierNetworkAirportConnectNotification
																object:desc];
		}
	}
	airportStatus = [newValue retain];
}

- (NSString *)getMediaForInterface:(NSString *)anInterface {
	// This is all made by looking through Darwin's src/network_cmds/ifconfig.tproj.
	// There's no pretty way to get media stuff; I've stripped it down to the essentials
	// for what I'm doing.
	
	NSAssert([anInterface cStringLength] < IFNAMSIZ, @"Interface name too long");

	int s = socket(AF_INET, SOCK_DGRAM, 0);
	NSAssert(s >= 0, @"Can't open datagram socket");
	struct ifmediareq ifmr;
	memset(&ifmr, 0, sizeof(ifmr));
	strncpy(ifmr.ifm_name, [anInterface cString], [anInterface cStringLength]);
	
	if (ioctl(s, SIOCGIFMEDIA, (caddr_t)&ifmr) < 0) {
		// Media not supported.
		close(s);
		return nil;
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
	
	NSString *options = nil;
	
	// And fill in the duplex settings.
	for (desc = ifm_shared_option_descriptions; desc->ifmt_string; desc++) {
		if (ifmr.ifm_active & desc->ifmt_word) {
			if (options) {
				options = [NSString stringWithFormat:@"%@,%s", options, desc->ifmt_string];
			} else {
				options = [NSString stringWithCString:desc->ifmt_string];
			}
		}
	}

	return (options) ? [NSString stringWithFormat:@"%s <%@>", type, options] : [NSString stringWithCString:type];
}

@end
