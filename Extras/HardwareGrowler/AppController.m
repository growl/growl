#import "AppController.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <CFGrowlAdditions.h>
#include "FireWireNotifier.h"
#include "USBNotifier.h"
#include "BluetoothNotifier.h"
#include "VolumeNotifier.h"
#include "NetworkNotifier.h"
#include "SyncNotifier.h"
#include "PowerNotifier.h"

#define NotifierUSBConnectionNotification				NSLocalizedString(@"USB Device Connected", "")
#define NotifierUSBDisconnectionNotification			NSLocalizedString(@"USB Device Disconnected", "")
#define NotifierVolumeMountedNotification				NSLocalizedString(@"Volume Mounted", "")
#define NotifierVolumeUnmountedNotification				NSLocalizedString(@"Volume Unmounted", "")
#define NotifierBluetoothConnectionNotification			NSLocalizedString(@"Bluetooth Device Connected", "")
#define NotifierBluetoothDisconnectionNotification		NSLocalizedString(@"Bluetooth Device Disconnected", "")
#define NotifierFireWireConnectionNotification			NSLocalizedString(@"FireWire Device Connected", "")
#define NotifierFireWireDisconnectionNotification		NSLocalizedString(@"FireWire Device Disconnected", "")
#define NotifierNetworkLinkUpNotification				NSLocalizedString(@"Network Link Up", "")
#define NotifierNetworkLinkDownNotification				NSLocalizedString(@"Network Link Down", "")
#define NotifierNetworkIpAcquiredNotification			NSLocalizedString(@"IP Acquired", "")
#define NotifierNetworkIpReleasedNotification			NSLocalizedString(@"IP Released", "")
#define NotifierNetworkAirportConnectNotification		NSLocalizedString(@"AirPort Connected", "")
#define NotifierNetworkAirportDisconnectNotification	NSLocalizedString(@"AirPort Disconnected", "")
#define NotifierSyncStartedNotification					NSLocalizedString(@"Sync started", "")
#define NotifierSyncFinishedNotification				NSLocalizedString(@"Sync finished", "")
#define NotifierPowerOnACNotification					NSLocalizedString(@"Switched to A/C Power", "")
#define NotifierPowerOnBatteryNotification				NSLocalizedString(@"Switched to Battery Power", "")
#define NotifierPowerOnUPSNotification					NSLocalizedString(@"Switched to UPS Power", "")

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
#define NotifierNetworkIpAcquiredDescription()			CFCopyLocalizedString(CFSTR("New primary IP: %@ (%@)"), "")
#define NotifierNetworkIpReleasedDescription()			CFCopyLocalizedString(CFSTR("No IP address now"), "")

static io_connect_t			powerConnection;
static io_object_t			powerNotifier;
static CFRunLoopSourceRef	powerRunLoopSource;
static BOOL					sleeping;

#pragma mark Icons

static CFDataRef firewireLogo(void)
{
	static CFDataRef firewireLogoData = NULL;
	char imagePath[PATH_MAX];

	if (!firewireLogoData) {
		CFURLRef imageURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(),
												 CFSTR("FireWireLogo"),
												 CFSTR("png"),
												 /*subDirName*/ NULL);
		if (CFURLGetFileSystemRepresentation(imageURL, false, (UInt8 *)imagePath, sizeof(imagePath)))
			firewireLogoData = (CFDataRef)readFile(imagePath);
		CFRelease(imageURL);
	}

	return firewireLogoData;
}

static CFDataRef usbLogo(void)
{
	static CFDataRef usbLogoData = NULL;
	char imagePath[PATH_MAX];

	if (!usbLogoData) {
		CFURLRef imageURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(),
													CFSTR("usbLogoWhite"),
													CFSTR("png"),
													/*subDirName*/ NULL);
		if (CFURLGetFileSystemRepresentation(imageURL, false, (UInt8 *)imagePath, sizeof(imagePath)))
			usbLogoData = (CFDataRef)readFile(imagePath);
		CFRelease(imageURL);
	}

	return usbLogoData;
}

static CFDataRef bluetoothLogo(void)
{
	static CFDataRef bluetoothLogoData = NULL;
	char imagePath[PATH_MAX];

	if (!bluetoothLogoData) {
		CFURLRef imageURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(),
													CFSTR("BluetoothLogo"),
													CFSTR("png"),
													/*subDirName*/ NULL);
		if (CFURLGetFileSystemRepresentation(imageURL, false, (UInt8 *)imagePath, sizeof(imagePath)))
			bluetoothLogoData = (CFDataRef)readFile(imagePath);
		CFRelease(imageURL);
	}

	return bluetoothLogoData;
}

static CFDataRef airportIcon(void)
{
	static CFDataRef airportIconData = NULL;

	if (!airportIconData) {
		CFURLRef appURL = (CFURLRef)copyURLForApplication(@"Airport Admin Utility.app");
		if (appURL) {
			airportIconData = (CFDataRef)copyIconDataForURL((NSURL *)appURL);
			CFRelease(appURL);
		}
	}

	return airportIconData;
}

static CFDataRef ipIcon(void)
{
	static CFDataRef ipIconData = NULL;

	if (!ipIconData) {
		CFURLRef appURL = (CFURLRef)copyURLForApplication(@"Internet Connect.app");
		if (appURL) {
			ipIconData = (CFDataRef)copyIconDataForURL((NSURL *)appURL);
			CFRelease(appURL);
		}
	}

	return ipIconData;
}

static CFDataRef iSyncIcon(void)
{
	static CFDataRef iSyncIconData = NULL;

	if (!iSyncIconData) {
		CFURLRef appURL = (CFURLRef)copyURLForApplication(@"iSync.app");
		if (appURL) {
			iSyncIconData = (CFDataRef)copyIconDataForURL((NSURL *)appURL);
			CFRelease(appURL);
		}
	}

	return iSyncIconData;
}

#pragma mark Firewire

void AppController_fwDidConnect(CFStringRef deviceName) {
//	NSLog(@"FireWire Connect: %@", deviceName);

	CFStringRef title = NotifierFireWireConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:(NSString *)deviceName
							notificationName:(NSString *)NotifierFireWireConnectionNotification
							iconData:(NSData *)firewireLogo()
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
							iconData:(NSData *)firewireLogo()
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
							iconData:(NSData *)usbLogo()
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
							iconData:(NSData *)usbLogo()
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
							iconData:(NSData *)bluetoothLogo()
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
							iconData:(NSData *)bluetoothLogo()
							priority:0
							isSticky:NO
							clickContext:nil];
	CFRelease(title);
}

#pragma mark Volumes

void AppController_volumeDidMount(VolumeInfo *info) {
//	NSLog(@"volume Mount: %@", info);

	CFStringRef title = NotifierVolumeMountedTitle();
	NSDictionary *context = nil;
	
	if ([info path]) {
		context = [NSDictionary dictionaryWithObjectsAndKeys:
								(NSString *)NotifierVolumeMountedNotification, @"notification",
								[info path], @"path",
								nil];
	}
	
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:[info name]
							notificationName:(NSString *)NotifierVolumeMountedNotification
							iconData:[info iconData]
							priority:0
							isSticky:NO
							clickContext:context];
	CFRelease(title);
}

void AppController_volumeDidUnmount(VolumeInfo *info) {
//	NSLog(@"volume Unmount: %@", info);

	CFStringRef title = NotifierVolumeUnmountedTitle();

	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:[info name]
							notificationName:(NSString *)NotifierVolumeUnmountedNotification
							iconData:[info iconData]
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
								   iconData:(NSData *)airportIcon()
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
								   iconData:(NSData *)airportIcon()
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
								   iconData:(NSData *)ipIcon()
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
								   iconData:(NSData *)ipIcon()
								   priority:0
								   isSticky:NO
							   clickContext:nil];
	CFRelease(title);
}

void AppController_ipAcquired(CFStringRef ip, CFStringRef type) {
	//NSLog(@"IP acquired: %@", ip);

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkIpAcquiredTitle();
	CFStringRef format = NotifierNetworkIpAcquiredDescription();
	CFStringRef description = CFStringCreateWithFormat(kCFAllocatorDefault,
													   NULL,
													   format,
													   ip,
													   type);
	CFRelease(format);
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkIpAcquiredNotification
								   iconData:(NSData *)ipIcon()
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
								   iconData:(NSData *)ipIcon()
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
								   iconData:(NSData *)iSyncIcon()
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
								   iconData:(NSData *)iSyncIcon()
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
	CFDataRef		imageData = iSyncIcon();

	BOOL		haveBatteryTime = (batteryTime != -1);
	BOOL		haveBatteryPercentage = (batteryPercentage != -1);

	if (powerSource == HGACPower) {
		title = NSLocalizedString(@"On A/C power", nil);

		if (isCharging == kCFBooleanTrue) {
			[description appendString:NSLocalizedString(@"Battery charging...", nil)];
			if (haveBatteryTime || haveBatteryPercentage) [description appendString:@"\n"];
			if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time to charge: %i", nil), batteryTime];
			if (haveBatteryTime && haveBatteryPercentage) [description appendString:@"\n"];
			if (haveBatteryPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];
		}

		notificationName = (NSString *)NotifierPowerOnACNotification;

	} else if (powerSource == HGBatteryPower) {
		title = NSLocalizedString(@"On battery power", nil);

		if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time remaining: %i minutes", nil), batteryTime];
		if (haveBatteryTime && haveBatteryPercentage) [description appendString:@"\n"];
		if (haveBatteryPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];

		notificationName = (NSString *)NotifierPowerOnBatteryNotification;

	} else if (powerSource == HGUPSPower) {
		title = NSLocalizedString(@"On UPS power", nil);

		notificationName = (NSString *)NotifierPowerOnUPSNotification;
	}

	if (notificationName)
		[GrowlApplicationBridge notifyWithTitle:title
									description:description
							   notificationName:notificationName
									   iconData:(NSData *)imageData
									   priority:0
									   isSticky:NO
								   clickContext:nil];
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
	networkNotifier = [[NetworkNotifier alloc] init];
	PowerNotifier_init();
}

- (void) dealloc {
	FireWireNotifier_dealloc();
	USBNotifier_dealloc();
	VolumeNotifier_dealloc();
	SyncNotifier_dealloc();
	BluetoothNotifier_dealloc();
	[networkNotifier release];

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
	NSArray *notifications = [NSArray arrayWithObjects:
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
							  NotifierPowerOnUPSNotification,
							  nil];
	
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"HardwareGrowler", GROWL_APP_NAME,
		notifications,      GROWL_NOTIFICATIONS_ALL,
		notifications,      GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	CFRelease(notifications);

	return regDict;
}

- (void) growlNotificationWasClicked:(id)clickContext {
	if ([[clickContext objectForKey:@"notification"] isEqualToString:(NSString *)NotifierVolumeMountedNotification])
		[[NSWorkspace sharedWorkspace] openFile:[clickContext objectForKey:@"path"]];
}

- (IBAction) doSimpleHelp:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"readme" ofType:@"txt"]];
}

@end
