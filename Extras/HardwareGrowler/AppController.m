#import <Growl/Growl.h>
#import "AppController.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include "FireWireNotifier.h"
#include "USBNotifier.h"
#include "BluetoothNotifier.h"
#include "VolumeNotifier.h"
#include "NetworkNotifier.h"
#include "SyncNotifier.h"

#define NotifierUSBConnectionNotification				@"USB Device Connected"
#define NotifierUSBDisconnectionNotification			@"USB Device Disconnected"
#define NotifierVolumeMountedNotification				@"Volume Mounted"
#define NotifierVolumeUnmountedNotification				@"Volume Unmounted"
#define NotifierBluetoothConnectionNotification			@"Bluetooth Device Connected"
#define NotifierBluetoothDisconnectionNotification		@"Bluetooth Device Disconnected"
#define NotifierFireWireConnectionNotification			@"FireWire Device Connected"
#define NotifierFireWireDisconnectionNotification		@"FireWire Device Disconnected"
#define NotifierNetworkLinkUpNotification				@"Link-Up"
#define NotifierNetworkLinkDownNotification				@"Link-Down"
#define NotifierNetworkIpAcquiredNotification			@"IP-Acquired"
#define NotifierNetworkIpReleasedNotification			@"IP-Released"
#define NotifierNetworkAirportConnectNotification		@"AirPort-Connect"
#define NotifierNetworkAirportDisconnectNotification	@"AirPort-Disconnect"
#define NotifierSyncStartedNotification					@"Sync started"
#define NotifierSyncFinishedNotification				@"Sync finished"

#define NotifierFireWireConnectionTitle			NSLocalizedString(@"FireWire Connection", @"")
#define NotifierFireWireDisconnectionTitle		NSLocalizedString(@"FireWire Disconnection", @"")
#define NotifierUSBConnectionTitle				NSLocalizedString(@"USB Connection", @"")
#define NotifierUSBDisconnectionTitle			NSLocalizedString(@"USB Disconnection", @"")
#define NotifierBluetoothConnectionTitle		NSLocalizedString(@"Bluetooth Connection", @"")
#define NotifierBluetoothDisconnectionTitle		NSLocalizedString(@"Bluetooth Disconnection", @"")
#define NotifierVolumeMountedTitle				NSLocalizedString(@"Volume Mounted", @"")
#define NotifierVolumeUnmountedTitle			NSLocalizedString(@"Volume Unmounted", @"")
#define NotifierNetworkAirportConnectTitle		NSLocalizedString(@"Airport connected", @"")
#define NotifierNetworkAirportDisconnectTitle	NSLocalizedString(@"Airport disconnected", @"")
#define NotifierNetworkLinkUpTitle				NSLocalizedString(@"Ethernet activated", @"")
#define NotifierNetworkLinkDownTitle			NSLocalizedString(@"Ethernet deactivated", @"")
#define NotifierNetworkIpAcquiredTitle			NSLocalizedString(@"IP address acquired", @"")
#define NotifierNetworkIpReleasedTitle			NSLocalizedString(@"IP address released", @"")
#define NotifierSyncStartedTitle				NSLocalizedString(@"Sync started", @"")
#define NotifierSyncFinishedTitle				NSLocalizedString(@"Sync finished", @"")

#define NotifierNetworkIpAcquiredDescription	NSLocalizedString(@"New primary IP: %@", @"")
#define NotifierNetworkIpReleasedDescription	NSLocalizedString(@"No IP address now", @"")

static NSData	*bluetoothLogoData;
static NSData	*ejectLogoData;
static NSData	*firewireLogoData;
static NSData	*usbLogoData;
static NSData	*airportIconData;
static NSData	*ipIconData;
static NSData	*iSyncIconData;

static io_connect_t			powerConnection;
static io_object_t			powerNotifier;
static CFRunLoopSourceRef	powerRunLoopSource;
static BOOL					sleeping;

static void fwDidConnect(CFStringRef deviceName) {
//	NSLog(@"FireWire Connect: %@", deviceName );

	[GrowlApplicationBridge notifyWithTitle:NotifierFireWireConnectionTitle
							description:(NSString *)deviceName
							notificationName:NotifierFireWireConnectionNotification
							iconData:firewireLogoData
							priority:0
							isSticky:NO
							clickContext:nil];

}

static void fwDidDisconnect(CFStringRef deviceName) {
//	NSLog(@"FireWire Disconnect: %@", deviceName );

	[GrowlApplicationBridge notifyWithTitle:NotifierFireWireDisconnectionTitle
							description:(NSString *)deviceName
							notificationName:NotifierFireWireDisconnectionNotification
							iconData:firewireLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
}

static void usbDidConnect(CFStringRef deviceName) {
//	NSLog(@"USB Connect: %@", deviceName );
	[GrowlApplicationBridge notifyWithTitle:NotifierUSBConnectionTitle
							description:(NSString *)deviceName
							notificationName:NotifierUSBConnectionNotification
							iconData:usbLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
}

static void usbDidDisconnect(CFStringRef deviceName) {
//	NSLog(@"USB Disconnect: %@", deviceName );
	[GrowlApplicationBridge notifyWithTitle:NotifierUSBDisconnectionTitle
							description:(NSString *)deviceName
							notificationName:NotifierUSBDisconnectionNotification
							iconData:usbLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
}

static void bluetoothDidConnect(CFStringRef device) {
//	NSLog(@"Bluetooth Connect: %@", device );
	[GrowlApplicationBridge notifyWithTitle:NotifierBluetoothConnectionTitle
							description:(NSString *)device
							notificationName:NotifierBluetoothConnectionNotification
							iconData:bluetoothLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
}

static void bluetoothDidDisconnect(CFStringRef device) {
//	NSLog(@"Bluetooth Disconnect: %@", device );
	[GrowlApplicationBridge notifyWithTitle:NotifierBluetoothDisconnectionTitle
							description:(NSString *)device
							notificationName:NotifierBluetoothDisconnectionNotification
							iconData:bluetoothLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
}

static void volumeDidMount(CFStringRef name, CFStringRef path) {
	//NSLog(@"volume Mount: %@", name);

	NSData *iconData = [[[NSWorkspace sharedWorkspace] iconForFile:(NSString *)path] TIFFRepresentation];

	[GrowlApplicationBridge notifyWithTitle:NotifierVolumeMountedTitle
							description:(NSString *)name
							notificationName:NotifierVolumeMountedNotification
							iconData:iconData
							priority:0
							isSticky:NO
							clickContext:nil];
}

static void volumeDidUnmount(CFStringRef name) {
	//NSLog(@"volume Unmount: %@", name);

	[GrowlApplicationBridge notifyWithTitle:NotifierVolumeUnmountedTitle
							description:(NSString *)name
							notificationName:NotifierVolumeUnmountedNotification
							iconData:ejectLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
}

static void airportConnect(CFStringRef description) {
	//NSLog(@"AirPort connect: %@", description);

	if (sleeping)
		return;

	[GrowlApplicationBridge notifyWithTitle:NotifierNetworkAirportConnectTitle
								description:(NSString *)description
						   notificationName:NotifierNetworkAirportConnectNotification
								   iconData:airportIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

static void airportDisconnect(CFStringRef description) {
	//NSLog(@"AirPort disconnect: %@", description);

	if (sleeping)
		return;

	[GrowlApplicationBridge notifyWithTitle:NotifierNetworkAirportDisconnectTitle
								description:(NSString *)description
						   notificationName:NotifierNetworkAirportDisconnectNotification
								   iconData:airportIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

static void linkUp(CFStringRef description) {
	//NSLog(@"Link up: %@", description);

	if (sleeping)
		return;

	[GrowlApplicationBridge notifyWithTitle:NotifierNetworkLinkUpTitle
								description:(NSString *)description
						   notificationName:NotifierNetworkLinkUpNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

static void linkDown(CFStringRef description) {
	//NSLog(@"Link down: %@", description);

	if (sleeping)
		return;

	[GrowlApplicationBridge notifyWithTitle:NotifierNetworkLinkDownTitle
								description:(NSString *)description
						   notificationName:NotifierNetworkLinkDownNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

static void ipAcquired(CFStringRef ip) {
	//NSLog(@"IP acquired: %@", ip);

	if (sleeping)
		return;

	NSString *description = [[NSString alloc] initWithFormat:NotifierNetworkIpAcquiredDescription, ip];
	[GrowlApplicationBridge notifyWithTitle:NotifierNetworkIpAcquiredTitle
								description:description
						   notificationName:NotifierNetworkIpAcquiredNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	[description release];
}

static void ipReleased(void) {
	//NSLog(@"IP released");

	if (sleeping)
		return;

	[GrowlApplicationBridge notifyWithTitle:NotifierNetworkIpReleasedTitle
								description:NotifierNetworkIpReleasedDescription
						   notificationName:NotifierNetworkIpReleasedNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

static void syncStarted(void) {
	//NSLog(@"Sync started");

	[GrowlApplicationBridge notifyWithTitle:NotifierSyncStartedTitle
								description:NotifierSyncStartedTitle
						   notificationName:NotifierSyncStartedNotification
								   iconData:iSyncIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

static void syncFinished(void) {
	//NSLog(@"Sync finished");

	[GrowlApplicationBridge notifyWithTitle:NotifierSyncFinishedTitle
								description:NotifierSyncFinishedTitle
						   notificationName:NotifierSyncFinishedNotification
								   iconData:iSyncIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

static struct FireWireNotifierCallbacks fireWireNotifierCallbacks = {
	fwDidConnect,
	fwDidDisconnect
};
static struct USBNotifierCallbacks usbNotifierCallbacks = {
	usbDidConnect,
	usbDidDisconnect
};
static struct BluetoothNotifierCallbacks bluetoothNotifierCallbacks = {
	bluetoothDidConnect,
	bluetoothDidDisconnect
};
static struct VolumeNotifierCallbacks volumeNotifierCallbacks = {
	volumeDidMount,
	volumeDidUnmount
};
static struct NetworkNotifierCallbacks networkNotifierCallbacks = {
	linkUp,
	linkDown,
	ipAcquired,
	ipReleased,
	airportConnect,
	airportDisconnect
};
static struct SyncNotifierCallbacks syncNotifierCallbacks = {
	syncStarted,
	syncFinished
};

static void powerCallback(void *refcon, io_service_t service, natural_t messageType, void *messageArgument) {
#pragma unused(refcon,service)
	switch (messageType) {
		case kIOMessageSystemWillRestart:
		case kIOMessageSystemWillPowerOff:
		case kIOMessageSystemWillSleep:
		case kIOMessageDeviceWillPowerOff:
			sleeping = YES;
			IOAllowPowerChange(powerConnection, (long)messageArgument);
			break;
		case kIOMessageCanSystemPowerOff:
		case kIOMessageCanSystemSleep:
		case kIOMessageCanDevicePowerOff:
			IOAllowPowerChange(powerConnection, (long)messageArgument);
			break;
		case kIOMessageSystemWillNotSleep:
		case kIOMessageSystemWillNotPowerOff:
		case kIOMessageSystemHasPoweredOn:
		case kIOMessageDeviceWillNotPowerOff:
		case kIOMessageDeviceHasPoweredOn:
			sleeping = NO;
		default:
			break;
	}
}

@implementation AppController

- (void) awakeFromNib {
	bluetoothLogoData = [[[NSImage imageNamed: @"BluetoothLogo.png"] TIFFRepresentation] retain];
	ejectLogoData = [[[NSImage imageNamed: @"eject.icns"] TIFFRepresentation] retain];
	firewireLogoData = [[[NSImage imageNamed: @"FireWireLogo.png"] TIFFRepresentation] retain];
	usbLogoData = [[[NSImage imageNamed: @"usbLogoWhite.png"] TIFFRepresentation] retain];

	NSWorkspace *ws = [NSWorkspace sharedWorkspace];

	NSString *path = [ws fullPathForApplication:@"Airport Admin Utility.app"];
	airportIconData = [[[ws iconForFile:path] TIFFRepresentation] retain];

	path = [ws fullPathForApplication:@"iSync.app"];
	iSyncIconData = [[[ws iconForFile:path] TIFFRepresentation] retain];

	path = [ws fullPathForApplication:@"Internet Connect.app"];
	ipIconData = [[[ws iconForFile:path] TIFFRepresentation] retain];

	// Register ourselves as a Growl delegate for registration purposes
	[GrowlApplicationBridge setGrowlDelegate:self];

	// Register for sleep and wake notifications
	IONotificationPortRef ioNotificationPort;
	powerConnection = IORegisterForSystemPower(NULL, &ioNotificationPort, powerCallback, &powerNotifier);
	if (powerConnection) {
		powerRunLoopSource = IONotificationPortGetRunLoopSource(ioNotificationPort);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), powerRunLoopSource, kCFRunLoopDefaultMode);
		CFRelease(powerRunLoopSource);
	}

	FireWireNotifier_init(&fireWireNotifierCallbacks);
	USBNotifier_init(&usbNotifierCallbacks);
	VolumeNotifier_init(&volumeNotifierCallbacks);
	SyncNotifier_init(&syncNotifierCallbacks);
	BluetoothNotifier_init(&bluetoothNotifierCallbacks);
	NetworkNotifier_init(&networkNotifierCallbacks);
}

- (void) dealloc {
	FireWireNotifier_dealloc();
	USBNotifier_dealloc();
	VolumeNotifier_dealloc();
	SyncNotifier_dealloc();
	BluetoothNotifier_dealloc();
	NetworkNotifier_dealloc();

	[bluetoothLogoData release];
	[ejectLogoData     release];
	[airportIconData   release];
	[ipIconData        release];
	[iSyncIconData     release];

	if (powerConnection) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), powerRunLoopSource, kCFRunLoopDefaultMode);
		IODeregisterForSystemPower(&powerNotifier);
	}

	[super dealloc];
}

- (NSString *) applicationNameForGrowl {
	return @"HardwareGrowler";
}

- (NSDictionary *) registrationDictionaryForGrowl {
	// Register with Growl

	NSArray *notifications = [[NSArray alloc] initWithObjects:
		NotifierBluetoothConnectionNotification,
		NotifierBluetoothDisconnectionNotification,
		NotifierFireWireConnectionNotification,
		NotifierFireWireDisconnectionNotification,
		NotifierUSBConnectionNotification,
		NotifierUSBDisconnectionNotification,
		NotifierVolumeMountedNotification,
		NotifierVolumeUnmountedNotification,
		NotifierNetworkLinkUpNotification,
		NotifierNetworkLinkDownNotification,
		NotifierNetworkIpAcquiredNotification,
		NotifierNetworkIpReleasedNotification,
		NotifierNetworkAirportConnectNotification,
		NotifierNetworkAirportDisconnectNotification,
		NotifierSyncStartedNotification,
		NotifierSyncFinishedNotification,
		nil];

	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"HardwareGrowler", GROWL_APP_NAME,
		notifications, GROWL_NOTIFICATIONS_ALL,
		notifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	[notifications release];

	return regDict;
}

- (IBAction) doSimpleHelp: (id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"readme" ofType:@"txt"]];
}

@end
