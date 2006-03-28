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
#include "PowerNotifier.h"

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
#define NotifierPowerOnACNotification					CFSTR("Switched to A/C Power")
#define NotifierPowerOnBatteryNotification				CFSTR("Switched to Battery Power")
#define NotifierPowerOnUPSNotification					CFSTR("Switched to UPS Power")

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

NSData *firewireLogo(void);
NSData *usbLogo(void);
NSData *ejectLogo(void);
NSData *airportIcon(void);
NSData *ipIcon(void);
NSData *iSyncIcon(void);
NSData *bluetoothLogo(void);

static io_connect_t			powerConnection;
static io_object_t			powerNotifier;
static CFRunLoopSourceRef	powerRunLoopSource;
static BOOL					sleeping;

#pragma mark Firewire

void AppController_fwDidConnect(CFStringRef deviceName) {
//	NSLog(@"FireWire Connect: %@", deviceName);

	CFStringRef title = NotifierFireWireConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)deviceName
							notificationName:(NSString *)NotifierFireWireConnectionNotification
							iconData:firewireLogo()
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
							iconData:firewireLogo()
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

#pragma mark USB

void AppController_usbDidConnect(CFStringRef deviceName) {
//	NSLog(@"USB Connect: %@", deviceName);
	CFStringRef title = NotifierUSBConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)deviceName
							notificationName:(NSString *)NotifierUSBConnectionNotification
							iconData:usbLogo()
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
							iconData:usbLogo()
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

#pragma mark Bluetooth

void AppController_bluetoothDidConnect(CFStringRef device) {
//	NSLog(@"Bluetooth Connect: %@", device);
	CFStringRef title = NotifierBluetoothConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)device
							notificationName:(NSString *)NotifierBluetoothConnectionNotification
							iconData:bluetoothLogo()
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
							iconData:bluetoothLogo()
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

#pragma mark Volumes

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
							iconData:ejectLogo()
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

#pragma mark Network

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
								   iconData:airportIcon()
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
								   iconData:airportIcon()
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
								   iconData:ipIcon()
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
								   iconData:ipIcon()
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
								   iconData:ipIcon()
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
								   iconData:ipIcon()
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
	CFRelease(description);
}

#pragma mark Sync

void AppController_syncStarted(void) {
	//NSLog(@"Sync started");

	CFStringRef title = NotifierSyncStartedTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)title
						   notificationName:(NSString *)NotifierSyncStartedNotification
								   iconData:iSyncIcon()
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
								   iconData:iSyncIcon()
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
}

#pragma mark Power
void AppController_powerSwitched(HGPowerSource powerSource, CFBooleanRef isCharging,
								 int batteryTime, int batteryPercentage)
{
	NSString		*title = nil;
	NSMutableString *description = [NSMutableString string];
	NSString		*notificationName = nil;
	NSData			*imageData = iSyncIcon();

	BOOL		haveBatteryTime = (batteryTime != -1);
	BOOL		haveBatterPercentage = (batteryPercentage != -1);
	
	if (powerSource == HGACPower) {
		title = NSLocalizedString(@"On A/C power", nil);

		if (isCharging == kCFBooleanTrue) {
			[description appendString:NSLocalizedString(@"Battery charging...", nil)];
			if (haveBatteryTime || haveBatterPercentage) [description appendString:@"\n"];
			if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time to charge: %i", nil), batteryTime];
			if (haveBatteryTime && haveBatterPercentage) [description appendString:@"\n"];
			if (haveBatterPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];
		}

		notificationName = (NSString *)NotifierPowerOnACNotification;

	} else if (powerSource == HGBatteryPower) {
		title = NSLocalizedString(@"On battery power", nil);
		
		if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time remaining: %i minutes", nil), batteryTime];
		if (haveBatteryTime && haveBatterPercentage) [description appendString:@"\n"];
		if (haveBatterPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];
		
		notificationName = (NSString *)NotifierPowerOnBatteryNotification;

	} else if (powerSource == HGUPSPower) {
		title = NSLocalizedString(@"On UPS power", nil);
		
		notificationName = (NSString *)NotifierPowerOnUPSNotification;
	}

	if (notificationName) {
		[GrowlApplicationBridge notifyWithTitle:title
									description:description
							   notificationName:notificationName
									   iconData:imageData
									   priority:0
									   isSticky:NO
								   clickContext:nil];
	}
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

#pragma mark Icons

NSData *firewireLogo(void)
{
	static NSData	*firewireLogoData = nil;
	if (!firewireLogoData) {
		firewireLogoData = [[[NSImage imageNamed: @"FireWireLogo.png"] TIFFRepresentation] retain];
	}
	return firewireLogoData;
}

NSData *usbLogo(void)
{
	static NSData	*usbLogoData = nil;
	
	if (!usbLogoData) {
		usbLogoData = [[[NSImage imageNamed: @"usbLogoWhite.png"] TIFFRepresentation] retain];
	}
	
	return usbLogoData;
}

NSData *bluetoothLogo(void)
{
	static NSData	*bluetoothLogoData = nil;
	if (!bluetoothLogoData) {
		bluetoothLogoData = [[[NSImage imageNamed: @"BluetoothLogo.png"] TIFFRepresentation] retain];
	}
	
	return bluetoothLogoData;
}

NSData *ejectLogo(void)
{	
	static NSData	*ejectLogoData = nil;
	if (!ejectLogoData) {
		ejectLogoData = [[[NSImage imageNamed: @"eject.icns"] TIFFRepresentation] retain];
	}
	
	return ejectLogoData;
}


NSData *airportIcon()
{
	static NSData	*airportIconData = nil;
	
	if (!airportIconData) {
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		
		airportIconData = [[[ws iconForFile:[ws fullPathForApplication:@"Airport Admin Utility.app"]] TIFFRepresentation] retain];
	}
	
	return airportIconData;
}

NSData *ipIcon(void)
{
	static NSData	*ipIconData = nil;
	if (!ipIconData) {
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		
		ipIconData = [[[ws iconForFile:[ws fullPathForApplication:@"Internet Connect.app"]] TIFFRepresentation] retain];
	}
	
	return ipIconData;
}

NSData *iSyncIcon()
{
	static NSData	*iSyncIconData = nil;
	
	if (!iSyncIconData) {
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		
		iSyncIconData = [[[ws iconForFile:[ws fullPathForApplication:@"iSync.app"]] TIFFRepresentation] retain];
	}
	
	return iSyncIconData;
}

@implementation AppController

- (void) awakeFromNib {
	// Register ourselves as a Growl delegate for registration purposes
	[GrowlApplicationBridge setGrowlDelegate:self];

	// Register for sleep and wake notifications so we can suppress various notifications during sleep
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
	PowerNotifier_init();
}

- (void) dealloc {
	FireWireNotifier_dealloc();
	USBNotifier_dealloc();
	VolumeNotifier_dealloc();
	SyncNotifier_dealloc();
	BluetoothNotifier_dealloc();
	NetworkNotifier_dealloc();

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
#define NUMBER_OF_NOTIFICATIONS 19
	static const CFStringRef notificationNames[NUMBER_OF_NOTIFICATIONS] = {
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
		NotifierPowerOnACNotification,
		NotifierPowerOnBatteryNotification,
		NotifierPowerOnUPSNotification
	};

	CFArrayRef notifications = CFArrayCreate(kCFAllocatorDefault,
											 (const void **)notificationNames,
											 NUMBER_OF_NOTIFICATIONS,
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
