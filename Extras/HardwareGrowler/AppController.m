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

#define NotifierUSBConnectionNotification				CFSTR("USB Device Connected")
#define NotifierUSBDisconnectionNotification			CFSTR("USB Device Disconnected")
#define NotifierVolumeMountedNotification				CFSTR("Volume Mounted")
#define NotifierVolumeUnmountedNotification				CFSTR("Volume Unmounted")
#define NotifierBluetoothConnectionNotification			CFSTR("Bluetooth Device Connected")
#define NotifierBluetoothDisconnectionNotification		CFSTR("Bluetooth Device Disconnected")
#define NotifierFireWireConnectionNotification			CFSTR("FireWire Device Connected")
#define NotifierFireWireDisconnectionNotification		CFSTR("FireWire Device Disconnected")
#define NotifierNetworkLinkUpNotification				CFSTR("Link-Up")
#define NotifierNetworkLinkDownNotification				CFSTR("Link-Down")
#define NotifierNetworkIpAcquiredNotification			CFSTR("IP-Acquired")
#define NotifierNetworkIpReleasedNotification			CFSTR("IP-Released")
#define NotifierNetworkAirportConnectNotification		CFSTR("AirPort-Connect")
#define NotifierNetworkAirportDisconnectNotification	CFSTR("AirPort-Disconnect")
#define NotifierSyncStartedNotification					CFSTR("Sync started")
#define NotifierSyncFinishedNotification				CFSTR("Sync finished")

#define NotifierFireWireConnectionTitle()				CFCopyLocalizedString(CFSTR("FireWire Connection"), "")
#define NotifierFireWireDisconnectionTitle()			CFCopyLocalizedString(CFSTR("FireWire Disconnection"), "")
#define NotifierUSBConnectionTitle()					CFCopyLocalizedString(CFSTR("USB Connection"), "")
#define NotifierUSBDisconnectionTitle()					CFCopyLocalizedString(CFSTR("USB Disconnection"), "")
#define NotifierBluetoothConnectionTitle()				CFCopyLocalizedString(CFSTR("Bluetooth Connection"), "")
#define NotifierBluetoothDisconnectionTitle()			CFCopyLocalizedString(CFSTR("Bluetooth Disconnection"), "")
#define NotifierVolumeMountedTitle()					CFCopyLocalizedString(CFSTR("Volume Mounted"), "")
#define NotifierVolumeUnmountedTitle()					CFCopyLocalizedString(CFSTR("Volume Unmounted"), "")
#define NotifierNetworkAirportConnectTitle()			CFCopyLocalizedString(CFSTR("Airport connected"), "")
#define NotifierNetworkAirportDisconnectTitle()			CFCopyLocalizedString(CFSTR("Airport disconnected"), "")
#define NotifierNetworkLinkUpTitle()					CFCopyLocalizedString(CFSTR("Ethernet activated"), "")
#define NotifierNetworkLinkDownTitle()					CFCopyLocalizedString(CFSTR("Ethernet deactivated"), "")
#define NotifierNetworkIpAcquiredTitle()				CFCopyLocalizedString(CFSTR("IP address acquired"), "")
#define NotifierNetworkIpReleasedTitle()				CFCopyLocalizedString(CFSTR("IP address released"), "")
#define NotifierSyncStartedTitle()						CFCopyLocalizedString(CFSTR("Sync started"), "")
#define NotifierSyncFinishedTitle()						CFCopyLocalizedString(CFSTR("Sync finished"), "")

#define NotifierNetworkAirportConnectDescription()		CFCopyLocalizedString(CFSTR("Joined network.\nSSID:\t\t%@\nBSSID:\t%02X:%02X:%02X:%02X:%02X:%02X"), "")
#define NotifierNetworkAirportDisconnectDescription()	CFCopyLocalizedString(CFSTR("Left network %@."), "")
#define NotifierNetworkIpAcquiredDescription()			CFCopyLocalizedString(CFSTR("New primary IP: %@"), "")
#define NotifierNetworkIpReleasedDescription()			CFCopyLocalizedString(CFSTR("No IP address now"), "")

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

void AppController_fwDidConnect(CFStringRef deviceName) {
//	NSLog(@"FireWire Connect: %@", deviceName);

	CFStringRef title = NotifierFireWireConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)deviceName
							notificationName:(NSString *)NotifierFireWireConnectionNotification
							iconData:firewireLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_fwDidDisconnect(CFStringRef deviceName) {
//	NSLog(@"FireWire Disconnect: %@", deviceName);

	CFStringRef title = NotifierFireWireDisconnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)deviceName
							notificationName:(NSString *)NotifierFireWireDisconnectionNotification
							iconData:firewireLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_usbDidConnect(CFStringRef deviceName) {
//	NSLog(@"USB Connect: %@", deviceName);
	CFStringRef title = NotifierUSBConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)deviceName
							notificationName:(NSString *)NotifierUSBConnectionNotification
							iconData:usbLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_usbDidDisconnect(CFStringRef deviceName) {
//	NSLog(@"USB Disconnect: %@", deviceName);
	CFStringRef title = NotifierUSBDisconnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)deviceName
							notificationName:(NSString *)NotifierUSBDisconnectionNotification
							iconData:usbLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_bluetoothDidConnect(CFStringRef device) {
//	NSLog(@"Bluetooth Connect: %@", device);
	CFStringRef title = NotifierBluetoothConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)device
							notificationName:(NSString *)NotifierBluetoothConnectionNotification
							iconData:bluetoothLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_bluetoothDidDisconnect(CFStringRef device) {
//	NSLog(@"Bluetooth Disconnect: %@", device);
	CFStringRef title = NotifierBluetoothDisconnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)device
							notificationName:(NSString *)NotifierBluetoothDisconnectionNotification
							iconData:bluetoothLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_volumeDidMount(CFStringRef name, CFStringRef path) {
	//NSLog(@"volume Mount: %@", name);

	CFStringRef title = NotifierVolumeMountedTitle();
	NSData *iconData = [[[NSWorkspace sharedWorkspace] iconForFile:(NSString *)path] TIFFRepresentation];

	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)name
							notificationName:(NSString *)NotifierVolumeMountedNotification
							iconData:iconData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_volumeDidUnmount(CFStringRef name) {
	//NSLog(@"volume Unmount: %@", name);

	CFStringRef title = NotifierVolumeUnmountedTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)name
							notificationName:(NSString *)NotifierVolumeUnmountedNotification
							iconData:ejectLogoData
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

void AppController_airportConnect(CFStringRef networkName, const unsigned char *bssidBytes) {
	//NSLog(@"AirPort connect: %@", description);

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkAirportConnectTitle();
	CFStringRef format = NotifierNetworkAirportConnectDescription();
	CFStringRef description = CFStringCreateWithFormat(kCFAllocatorDefault,
													   NULL,
													   format,
													   networkName,
													   bssidBytes[0],
													   bssidBytes[1],
													   bssidBytes[2],
													   bssidBytes[3],
													   bssidBytes[4],
													   bssidBytes[5]);
	CFRelease(format);

	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkAirportConnectNotification
								   iconData:airportIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];

	CFRelease(title);
	CFRelease(description);
}

void AppController_airportDisconnect(CFStringRef networkName) {
	//NSLog(@"AirPort disconnect: %@", description);

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkAirportDisconnectTitle();
	CFStringRef format = NotifierNetworkAirportDisconnectDescription();
	CFStringRef description = CFStringCreateWithFormat(kCFAllocatorDefault,
													   NULL,
													   format,
													   networkName);
	CFRelease(format);
		
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkAirportDisconnectNotification
								   iconData:airportIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];

	CFRelease(title);
	CFRelease(description);
}

void AppController_linkUp(CFStringRef description) {
	//NSLog(@"Link up: %@", description);

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkLinkUpTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkLinkUpNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
}

void AppController_linkDown(CFStringRef description) {
	//NSLog(@"Link down: %@", description);

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkLinkDownTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkLinkDownNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
}

void AppController_ipAcquired(CFStringRef ip) {
	//NSLog(@"IP acquired: %@", ip);

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkIpAcquiredTitle();
	CFStringRef format = NotifierNetworkIpAcquiredDescription();
	CFStringRef description = CFStringCreateWithFormat(kCFAllocatorDefault,
													   NULL,
													   format,
													   ip);
	CFRelease(format);
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkIpAcquiredNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
	CFRelease(description);
}

void AppController_ipReleased(void) {
	//NSLog(@"IP released");

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkIpReleasedTitle();
	CFStringRef description = NotifierNetworkIpReleasedDescription();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkIpReleasedNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
	CFRelease(description);
}

void AppController_syncStarted(void) {
	//NSLog(@"Sync started");

	CFStringRef title = NotifierSyncStartedTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)title
						   notificationName:(NSString *)NotifierSyncStartedNotification
								   iconData:iSyncIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
}

void AppController_syncFinished(void) {
	//NSLog(@"Sync finished");

	CFStringRef title = NotifierSyncFinishedTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)title
						   notificationName:(NSString *)NotifierSyncFinishedNotification
								   iconData:iSyncIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
}

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
	}

	FireWireNotifier_init();
	USBNotifier_init();
	VolumeNotifier_init();
	SyncNotifier_init();
	BluetoothNotifier_init();
	NetworkNotifier_init();
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
	static const CFStringRef notificationNames[16] = {
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
		NotifierSyncFinishedNotification
	};

	CFArrayRef notifications = CFArrayCreate(kCFAllocatorDefault,
											 (const void **)notificationNames,
											 16,
											 &kCFTypeArrayCallBacks);

	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"HardwareGrowler", GROWL_APP_NAME,
		notifications,      GROWL_NOTIFICATIONS_ALL,
		notifications,      GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	CFRelease(notifications);

	return regDict;
}

- (IBAction) doSimpleHelp:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"readme" ofType:@"txt"]];
}

@end
