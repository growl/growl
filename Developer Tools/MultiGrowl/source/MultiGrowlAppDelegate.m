//
//  MultiGrowlAppDelegate.m
//  MultiGrowl
//
//  Created by Rudy Richter on 11/8/11.
//  Copyright 2011 The Growl Project, LLC. All rights reserved.
//

#import "MultiGrowlAppDelegate.h"

#define NotifierUSBConnectionNotification				@"USB Device Connected"
#define NotifierUSBDisconnectionNotification			@"USB Device Disconnected"
#define NotifierVolumeMountedNotification				@"Volume Mounted"
#define NotifierVolumeUnmountedNotification				@"Volume Unmounted"
#define NotifierBluetoothConnectionNotification			@"Bluetooth Device Connected"
#define NotifierBluetoothDisconnectionNotification		@"Bluetooth Device Disconnected"
#define NotifierFireWireConnectionNotification			@"FireWire Device Connected"
#define NotifierFireWireDisconnectionNotification		@"FireWire Device Disconnected"
#define NotifierNetworkLinkUpNotification				@"Network Link Up"
#define NotifierNetworkLinkDownNotification				@"Network Link Down"
#define NotifierNetworkIpAcquiredNotification			@"IP Acquired"
#define NotifierNetworkIpReleasedNotification			@"IP Released"
#define NotifierNetworkAirportConnectNotification		@"AirPort Connected"
#define NotifierNetworkAirportDisconnectNotification	@"AirPort Disconnected"
#define NotifierSyncStartedNotification					@"Sync started"
#define NotifierSyncFinishedNotification				@"Sync finished"
#define NotifierPowerOnACNotification					@"Switched to A/C Power"
#define NotifierPowerOnBatteryNotification				@"Switched to Battery Power"
#define NotifierPowerOnUPSNotification					@"Switched to UPS Power"

#define NotifierUSBConnectionHumanReadableDescription				NSLocalizedString(@"USB Device Connected", "")
#define NotifierUSBDisconnectionHumanReadableDescription			NSLocalizedString(@"USB Device Disconnected", "")
#define NotifierVolumeMountedHumanReadableDescription				NSLocalizedString(@"Volume Mounted", "")
#define NotifierVolumeUnmountedHumanReadableDescription				NSLocalizedString(@"Volume Unmounted", "")
#define NotifierBluetoothConnectionHumanReadableDescription			NSLocalizedString(@"Bluetooth Device Connected", "")
#define NotifierBluetoothDisconnectionHumanReadableDescription		NSLocalizedString(@"Bluetooth Device Disconnected", "")
#define NotifierFireWireConnectionHumanReadableDescription			NSLocalizedString(@"FireWire Device Connected", "")
#define NotifierFireWireDisconnectionHumanReadableDescription		NSLocalizedString(@"FireWire Device Disconnected", "")
#define NotifierNetworkLinkUpHumanReadableDescription				NSLocalizedString(@"Network Link Up", "")
#define NotifierNetworkLinkDownHumanReadableDescription				NSLocalizedString(@"Network Link Down", "")
#define NotifierNetworkIpAcquiredHumanReadableDescription			NSLocalizedString(@"IP Acquired", "")
#define NotifierNetworkIpReleasedHumanReadableDescription			NSLocalizedString(@"IP Released", "")
#define NotifierNetworkAirportConnectHumanReadableDescription		NSLocalizedString(@"AirPort Connected", "")
#define NotifierNetworkAirportDisconnectHumanReadableDescription	NSLocalizedString(@"AirPort Disconnected", "")
#define NotifierSyncStartedHumanReadableDescription					NSLocalizedString(@"Sync started", "")
#define NotifierSyncFinishedHumanReadableDescription				NSLocalizedString(@"Sync finished", "")
#define NotifierPowerOnACHumanReadableDescription					NSLocalizedString(@"Switched to A/C Power", "")
#define NotifierPowerOnBatteryHumanReadableDescription				NSLocalizedString(@"Switched to Battery Power", "")
#define NotifierPowerOnUPSHumanReadableDescription					NSLocalizedString(@"Switched to UPS Power", "")

@implementation MultiGrowlAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Insert code here to initialize your application 

	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *path = [[mainBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl"];
	if(NSAppKitVersionNumber >= 1038)
		path = [path stringByAppendingPathComponent:@"1.3"];
	else
		path = [path stringByAppendingPathComponent:@"1.2.3"];
	
	path = [path stringByAppendingPathComponent:@"Growl.framework"];
	NSLog(@"path: %@", path);
	NSBundle *growlFramework = [NSBundle bundleWithPath:path];
	if([growlFramework load])
	{
		NSDictionary *infoDictionary = [growlFramework infoDictionary];
		NSLog(@"Using Growl.framework %@ (%@)",
			  [infoDictionary objectForKey:@"CFBundleShortVersionString"],
			  [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]);
	
		Class GAB = NSClassFromString(@"GrowlApplicationBridge");
		if([GAB respondsToSelector:@selector(setGrowlDelegate:)])
			[GAB performSelector:@selector(setGrowlDelegate:) withObject:self];
	}
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSDictionary *notificationsWithDescriptions = [NSDictionary dictionaryWithObjectsAndKeys:
												   NotifierUSBConnectionHumanReadableDescription, NotifierUSBConnectionNotification,			
												   NotifierUSBDisconnectionHumanReadableDescription, NotifierUSBDisconnectionNotification,		
												   NotifierVolumeMountedHumanReadableDescription, NotifierVolumeMountedNotification,			
												   NotifierVolumeUnmountedHumanReadableDescription, NotifierVolumeUnmountedNotification,			
												   NotifierBluetoothConnectionHumanReadableDescription, NotifierBluetoothConnectionNotification,		
												   NotifierBluetoothDisconnectionHumanReadableDescription, NotifierBluetoothDisconnectionNotification,	
												   NotifierFireWireConnectionHumanReadableDescription, NotifierFireWireConnectionNotification,		
												   NotifierFireWireDisconnectionHumanReadableDescription, NotifierFireWireDisconnectionNotification,	
												   NotifierNetworkLinkUpHumanReadableDescription, NotifierNetworkLinkUpNotification,			
												   NotifierNetworkLinkDownHumanReadableDescription, NotifierNetworkLinkDownNotification,			
												   NotifierNetworkIpAcquiredHumanReadableDescription, NotifierNetworkIpAcquiredNotification,		
												   NotifierNetworkIpReleasedHumanReadableDescription, NotifierNetworkIpReleasedNotification,		
												   NotifierNetworkAirportConnectHumanReadableDescription, NotifierNetworkAirportConnectNotification,	
												   NotifierNetworkAirportDisconnectHumanReadableDescription, NotifierNetworkAirportDisconnectNotification,
												   NotifierSyncStartedHumanReadableDescription, NotifierSyncStartedNotification,				
												   NotifierSyncFinishedHumanReadableDescription, NotifierSyncFinishedNotification,			
												   NotifierPowerOnACHumanReadableDescription, NotifierPowerOnACNotification,				
												   NotifierPowerOnBatteryHumanReadableDescription, NotifierPowerOnBatteryNotification,			
												   NotifierPowerOnUPSHumanReadableDescription, NotifierPowerOnUPSNotification,				
												   nil];
	
	NSArray *allNotifications = [notificationsWithDescriptions allKeys];
	
	//Don't turn the sync notiifications on by default; they're noisy and not all that interesting.
	NSMutableArray *defaultNotifications = [allNotifications mutableCopy];
	[defaultNotifications removeObject:NotifierSyncStartedNotification];
	[defaultNotifications removeObject:NotifierSyncFinishedNotification];
	
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"MultiGrowlExample", GROWL_APP_NAME,
							 allNotifications, GROWL_NOTIFICATIONS_ALL,
							 defaultNotifications,	GROWL_NOTIFICATIONS_DEFAULT,
							 notificationsWithDescriptions,	GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
							 nil];
	
	[defaultNotifications release];
	
	return regDict;
}

static NSData* firewireLogo(void)
{
	static NSData* firewireLogoData = nil;
	
	if (!firewireLogoData) {
		NSString *path = [[NSBundle mainBundle] pathForImageResource:@"FireWireLogo"];
		if(path)
			firewireLogoData = [[NSData alloc] initWithContentsOfFile:path];
	}
	
	return firewireLogoData;
}

- (IBAction)notify:(id)sender
{
	Class GAB = NSClassFromString(@"GrowlApplicationBridge");
	if([GAB respondsToSelector:@selector(notifyWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:identifier:)])
		[GAB notifyWithTitle:@"Firewire Disconnected"
								description:@"Rudy's HD"
						   notificationName:(NSString *)NotifierFireWireDisconnectionNotification
								   iconData:(NSData *)firewireLogo()
								   priority:0
								   isSticky:NO
							   clickContext:nil
								 identifier:@"Rudy's HD"];
	
}

@end
