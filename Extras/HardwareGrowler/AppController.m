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
#import "HGCommon.h"

#import <ServiceManagement/ServiceManagement.h>

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

#define NotifierNetworkAirportDisconnectDescription()	CFCopyLocalizedString(CFSTR("Left network %@."), "")
#define NotifierNetworkIpAcquiredDescription()			CFCopyLocalizedString(CFSTR("New primary IP: %@ (%@)"), "")
#define NotifierNetworkIpReleasedDescription()			CFCopyLocalizedString(CFSTR("No IP address now"), "")


#define NotifierAirPortIdentifier	@"airport"
#define NotifierPowerIdentifier		@"power"
#define NotifierSyncIdentifier		@"sync"
#define NotifierNetworkLinkIdentifier @"link"
#define NotifierNetworkIpIdentifier @"ip"

#define ShowDevicesTitle NSLocalizedString(@"Show Connected Devices at Launch", nil)
#define GroupNetworkTitle NSLocalizedString(@"Group Network Notifications", nil)
#define QuitTitle NSLocalizedString(@"Quit HardwareGrowler", nil)
#define PreferencesTitle NSLocalizedString(@"Preferences...", nil)
#define OpenPreferencesTitle NSLocalizedString(@"Open HardwareGrowler Preferences...", nil)
#define IconTitle NSLocalizedString(@"Icon:", nil)


static io_connect_t			powerConnection;
static io_object_t			powerNotifier;
static CFRunLoopSourceRef	powerRunLoopSource;
static BOOL					sleeping;

#pragma mark Icons

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

static NSData* usbLogo(void)
{
	static NSData* usbLogoData = nil;

	if (!usbLogoData) {
      NSString *path = [[NSBundle mainBundle] pathForImageResource:@"usbLogoWhite"];
		if (path)
         usbLogoData = [[NSData alloc] initWithContentsOfFile:path];
	}

	return usbLogoData;
}

static NSData* bluetoothLogo(void)
{
	static NSData* bluetoothLogoData = nil;

	if (!bluetoothLogoData) {
		NSString* path = [[NSBundle mainBundle] pathForImageResource:@"BluetoothLogo"];
		if (path)
         bluetoothLogoData = [[NSData alloc] initWithContentsOfFile:path];
	}

	return bluetoothLogoData;
}

static NSData* airportIcon(void)
{
	static NSData* airportIconData = nil;

	if (!airportIconData) {
      NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"AirPort Utility.app"];
		if (path) {
			airportIconData = [[NSData alloc] initWithContentsOfFile:path];
		} else {
         path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Airport Admin Utility.app"];
			if (path) {
            airportIconData = [[NSData alloc] initWithContentsOfFile:path];
			}			
		}
	}

	return airportIconData;
}

static NSData* ipIcon(void)
{
	static NSData* ipIconData = nil;

	if (!ipIconData) {
      NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Network Utility.app"];
		if (path) {
			ipIconData = [[NSData alloc] initWithContentsOfFile:path];
		}
	}

	return ipIconData;
}

static NSData* iSyncIcon(void)
{
	static NSData* iSyncIconData = NULL;

	if (!iSyncIconData) {
      NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iSync.app"];
		if (path) {
			iSyncIconData = [[NSData alloc] initWithContentsOfFile:path];
		}
	}

	return iSyncIconData;
}

static NSData* powerBatteryIcon(void)
{
	static NSData* batteryIconData = NULL;

	if (!batteryIconData) {
      NSString *path = [[NSBundle mainBundle] pathForImageResource:@"Power-Battery"];
      if(path)
         batteryIconData = [[NSData alloc] initWithContentsOfFile:path];
	}

	return batteryIconData;
}

static NSData* powerACIcon(void)
{
	static NSData* ACPowerIconData = NULL;

	if (!ACPowerIconData) {
      NSString *path = [[NSBundle mainBundle] pathForImageResource:@"Power-AC"];
      if(path)
         ACPowerIconData = [[NSData alloc] initWithContentsOfFile:path];
   }

	return ACPowerIconData;
}

static NSData* powerACChargingIcon(void)
{
	static NSData* ACChargingPowerIconData = NULL;

	if (!ACChargingPowerIconData) {
      NSString *path = [[NSBundle mainBundle] pathForImageResource:@"Power-ACCharging"];
      if(path)
         ACChargingPowerIconData = [[NSData alloc] initWithContentsOfFile:path];
	}

	return ACChargingPowerIconData;
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
							clickContext:nil
							identifier:(NSString *)deviceName];
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
							clickContext:nil
							identifier:(NSString *) deviceName];
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
							clickContext:nil
							identifier:(NSString *)deviceName];
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
							clickContext:nil
							identifier:(NSString *)deviceName];
	CFRelease(title);
}

#pragma mark Bluetooth

void AppController_bluetoothDidConnect(NSString *device) {
//	NSLog(@"Bluetooth Connect: %@", device);
	CFStringRef title = NotifierBluetoothConnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:device
							notificationName:(NSString *)NotifierBluetoothConnectionNotification
							iconData:(NSData *)bluetoothLogo()
							priority:0
							isSticky:NO
							clickContext:nil
							identifier:device];
	CFRelease(title);
}

void AppController_bluetoothDidDisconnect(NSString *device) {
//	NSLog(@"Bluetooth Disconnect: %@", device);
	CFStringRef title = NotifierBluetoothDisconnectionTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
							description:device
							notificationName:(NSString *)NotifierBluetoothDisconnectionNotification
							iconData:(NSData *)bluetoothLogo()
							priority:0
							isSticky:NO
							clickContext:nil
						  identifier:device];
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
							clickContext:context
							identifier:[info name]];
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
							clickContext:nil
							identifier:[info name]];
	CFRelease(title);
}

#pragma mark Network

void AppController_airportConnect(CFStringRef networkName, const unsigned char *bssidBytes) {
	//NSLog(@"AirPort connect: %@", description);

	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkAirportConnectTitle();
	
	NSString *bssid = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
					   bssidBytes[0],
					   bssidBytes[1],
					   bssidBytes[2],
					   bssidBytes[3],
					   bssidBytes[4],
					   bssidBytes[5]];
	NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Joined network.\nSSID:\t\t%@\nBSSID:\t%@", ""),
							 networkName,
							 bssid];

	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:description
						   notificationName:(NSString *)NotifierNetworkAirportConnectNotification
								   iconData:(NSData *)airportIcon()
								   priority:0
								   isSticky:NO
							   clickContext:nil
								 identifier:NotifierAirPortIdentifier];
	CFRelease(title);
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
							   clickContext:nil
								 identifier:NotifierAirPortIdentifier];

	CFRelease(title);
	CFRelease(description);
}

void AppController_linkUp(CFStringRef description) {
	//NSLog(@"Link up: %@", description);

	if (sleeping)
		return;

	
	Boolean keyExistsAndHasValidFormat;
	NSString* identifier = nil;
	if (CFPreferencesGetAppBooleanValue(CFSTR("GroupNetwork"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat))
		identifier = NotifierNetworkLinkIdentifier;
		
	CFStringRef title = NotifierNetworkLinkUpTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkLinkUpNotification
								   iconData:(NSData *)ipIcon()
								   priority:0
								   isSticky:NO
							   clickContext:nil
								 identifier:identifier];
	CFRelease(title);
}

void AppController_linkDown(CFStringRef description) {
	//NSLog(@"Link down: %@", description);

	if (sleeping)
		return;

	Boolean keyExistsAndHasValidFormat;
	NSString* identifier = nil;
	if (CFPreferencesGetAppBooleanValue(CFSTR("GroupNetwork"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat))
		identifier = NotifierNetworkLinkIdentifier;
	
	CFStringRef title = NotifierNetworkLinkDownTitle();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkLinkDownNotification
								   iconData:(NSData *)ipIcon()
								   priority:0
								   isSticky:NO
							   clickContext:nil
								 identifier:identifier];
	CFRelease(title);
}

void AppController_ipAcquired(CFStringRef ip, CFStringRef type) {
	//NSLog(@"IP acquired: %@", ip);

	if (sleeping)
		return;

	Boolean keyExistsAndHasValidFormat;
	NSString* identifier = nil;
	if (CFPreferencesGetAppBooleanValue(CFSTR("GroupNetwork"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat))
		identifier = NotifierNetworkIpIdentifier;

	
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
							   clickContext:nil
								 identifier:identifier];
	CFRelease(title);
	CFRelease(description);
}

void AppController_ipReleased(void) {
	//NSLog(@"IP released");

	if (sleeping)
		return;

	Boolean keyExistsAndHasValidFormat;
	NSString* identifier = nil;
	if (CFPreferencesGetAppBooleanValue(CFSTR("GroupNetwork"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat))
		identifier = NotifierNetworkIpIdentifier;

	CFStringRef title = NotifierNetworkIpReleasedTitle();
	CFStringRef description = NotifierNetworkIpReleasedDescription();
	[GrowlApplicationBridge notifyWithTitle:(NSString *)title
								description:(NSString *)description
						   notificationName:(NSString *)NotifierNetworkIpReleasedNotification
								   iconData:(NSData *)ipIcon()
								   priority:0
								   isSticky:NO
							   clickContext:nil
								 identifier:identifier];
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
							   clickContext:nil
								 identifier:NotifierSyncIdentifier];
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
							   clickContext:nil
								 identifier:NotifierSyncIdentifier];
	CFRelease(title);
}

#pragma mark Power
void AppController_powerSwitched(HGPowerSource powerSource, CFBooleanRef isCharging,
								 CFIndex batteryTime, CFIndex batteryPercentage)
{
	NSString		*title = nil;
	NSMutableString *description = [NSMutableString string];
	NSString		*notificationName = nil;
	NSData		*imageData = nil;

	BOOL		haveBatteryTime = (batteryTime != -1);
	BOOL		haveBatteryPercentage = (batteryPercentage != -1);

	if (powerSource == HGACPower) {
		title = NSLocalizedString(@"On A/C power", nil);

		if (isCharging == kCFBooleanTrue) {
			[description appendString:NSLocalizedString(@"Battery charging...", nil)];
			if (haveBatteryTime || haveBatteryPercentage) [description appendString:@"\n"];
			if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time to charge: %i minutes", nil), batteryTime];
			if (haveBatteryTime && haveBatteryPercentage) [description appendString:@"\n"];
			if (haveBatteryPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];
			imageData = powerACChargingIcon();
		} else {
			imageData = powerACIcon();
		}

		notificationName = (NSString *)NotifierPowerOnACNotification;

	} else if (powerSource == HGBatteryPower) {
		title = NSLocalizedString(@"On battery power", nil);

		if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time remaining: %i minutes", nil), batteryTime];
		if (haveBatteryTime && haveBatteryPercentage) [description appendString:@"\n"];
		if (haveBatteryPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];

		notificationName = (NSString *)NotifierPowerOnBatteryNotification;

		imageData = powerBatteryIcon();

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
								   clickContext:nil
									 identifier:NotifierPowerIdentifier];
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
@synthesize showDevices, groupNetworkTitle, quitTitle, preferencesTitle, openPreferencesTitle, iconTitle;
@synthesize prefsWindow;
@synthesize iconOptions;
@synthesize onLoginSegmentedControl;
@synthesize iconPopUp;

- (void) awakeFromNib {
	iconInMenu = NSLocalizedString(@"Show icon in the menubar", @"default option for where the icon should be seen");
    iconInDock = NSLocalizedString(@"Show icon in the dock", @"display the icon only in the dock");
    iconInBoth = NSLocalizedString(@"Show icon in both", @"display the icon in both the menubar and the dock");
    noIcon = NSLocalizedString(@"No icon visible", @"display no icon at all");            

    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [NSNumber numberWithBool:NO], @"OnLogin",
                                                             [NSNumber numberWithBool:YES], @"ShowExisting",
                                                             [NSNumber numberWithBool:NO], @"GroupNetwork",
                                                             [NSNumber numberWithInteger:0], @"Visibility", nil]];
    
	NSNumber *visibility = [[NSUserDefaults standardUserDefaults] objectForKey:@"Visibility"];
	if(visibility == nil || [visibility integerValue] == kShowIconInDock || [visibility integerValue] == kShowIconInBoth){
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	}
	
	if(visibility == nil || [visibility integerValue] == kShowIconInMenu || [visibility integerValue] == kShowIconInBoth){
		[self initMenu];
	}
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
	
	[statusItem dealloc];
	[super dealloc];
}

- (NSString *) applicationNameForGrowl {
	return @"HardwareGrowler";
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
							 @"HardwareGrowler", GROWL_APP_NAME,
							 allNotifications, GROWL_NOTIFICATIONS_ALL,
							 defaultNotifications,	GROWL_NOTIFICATIONS_DEFAULT,
							 notificationsWithDescriptions,	GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
							 nil];

	[defaultNotifications release];

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


- (void) initMenu{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setMenu:statusMenu];

	NSString* icon_path = [[NSBundle mainBundle] pathForResource:@"hwgrowler_statusbar_icn" ofType:@"png"];
	NSImage *icon = [[NSImage alloc] initWithContentsOfFile:icon_path];
	
	[statusItem setImage:icon];
	[icon release];
	
	[statusItem setHighlightMode:YES];

}

- (BOOL) isEnabled: (CFStringRef) type{
#pragma unused(type)
	/*Boolean keyExistsAndHasValidFormat;
	NSString* identifier = nil;
	if (CFPreferencesGetAppBooleanValue(CFSTR(type), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat))*/
   return YES;

}

- (void) initTitles{
	self.showDevices = ShowDevicesTitle;
	self.groupNetworkTitle = GroupNetworkTitle;
	self.quitTitle = QuitTitle;
	self.preferencesTitle = PreferencesTitle;
	self.openPreferencesTitle = OpenPreferencesTitle;
	self.iconTitle = IconTitle;
}

 #ifdef BETA
 #define DAYSTOEXPIRY 14
 - (NSCalendarDate *)dateWithString:(NSString *)str {
 str = [str stringByReplacingOccurrencesOfString:@"  " withString:@" "];
 NSArray *dateParts = [str componentsSeparatedByString:@" "];
 int month = 1;
 NSString *monthString = [dateParts objectAtIndex:0];
 if ([monthString isEqualToString:@"Feb"]) {
 month = 2;
 } else if ([monthString isEqualToString:@"Mar"]) {
 month = 3;
 } else if ([monthString isEqualToString:@"Apr"]) {
 month = 4;
 } else if ([monthString isEqualToString:@"May"]) {
 month = 5;
 } else if ([monthString isEqualToString:@"Jun"]) {
 month = 6;
 } else if ([monthString isEqualToString:@"Jul"]) {
 month = 7;
 } else if ([monthString isEqualToString:@"Aug"]) {
 month = 8;
 } else if ([monthString isEqualToString:@"Sep"]) {
 month = 9;
 } else if ([monthString isEqualToString:@"Oct"]) {
 month = 10;
 } else if ([monthString isEqualToString:@"Nov"]) {
 month = 11;
 } else if ([monthString isEqualToString:@"Dec"]) {
 month = 12;
 }
 
 NSString *dateString = [NSString stringWithFormat:@"%@-%d-%@ 00:00:00 +0000", [dateParts objectAtIndex:2], month, [dateParts objectAtIndex:1]];
 return [NSCalendarDate dateWithString:dateString];
 }
 
 - (BOOL)expired
 {
 BOOL result = YES;
 
 NSCalendarDate* nowDate = [self dateWithString:[NSString stringWithUTF8String:__DATE__]];
 NSCalendarDate* expiryDate = [nowDate dateByAddingTimeInterval:(60*60*24* DAYSTOEXPIRY)];
 
 if ([expiryDate earlierDate:[NSDate date]] != expiryDate)
 result = NO;
 
 return result;
 }
 
 - (void)expiryCheck
 {
 if([self expired])
 {
 [NSApp activateIgnoringOtherApps:YES];
 NSInteger alert = NSRunAlertPanel(@"This Beta Has Expired", [NSString stringWithFormat:@"Please download a new version to keep using %@.", [[NSProcessInfo processInfo] processName]], @"Quit", nil, nil);
 if (alert == NSOKButton) 
 {
 [NSApp terminate:self];
 }
 }
 }
 #else
 - (void)expiryCheck{
 }
 #endif

- (IBAction)showPreferences:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
   if(![self.prefsWindow isVisible]){
      [self.prefsWindow center];
      [self.prefsWindow setFrameAutosaveName:@"HWGrowlerPrefsWindowFrame"];
      [self.prefsWindow setFrameUsingName:@"HWGrowlerPrefsWindowFrame" force:YES];
   }
    [self.prefsWindow makeKeyAndOrderFront:sender];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
#pragma unused(notification)
    self.iconOptions = [NSArray arrayWithObjects:iconInMenu, iconInDock, iconInBoth, noIcon, nil];
    
    // Register ourselves as a Growl delegate for registration purposes
	[GrowlApplicationBridge setGrowlDelegate:self];
    [GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
    
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
    
	[mainItem setSubmenu:submenu];
    
    
	[self initTitles];
	
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.Visibility" options:NSKeyValueObservingOptionNew context:&self];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.OnLogin" options:NSKeyValueObservingOptionNew context:&self];
    oldIconValue = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] integerForKey:@"Visibility"];
    oldOnLoginValue = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] integerForKey:@"OnLogin"];
    
	NSLog(@"Application Launched");
	[self expiryCheck];
}
- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
#pragma unused(theApplication, flag)    
    [self showPreferences:self];
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(object, change, context)
    if([keyPath isEqualToString:@"values.Visibility"])
    {
        
            NSNumber *value = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey:@"Visibility"];
            NSInteger index = [value integerValue];
            switch (index) {
                case kDontShowIcon:
                    [NSApp activateIgnoringOtherApps:YES];
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! Enabling this option will cause HardwareGrowler to run in the background", nil)
                                                     defaultButton:NSLocalizedString(@"Ok", nil)
                                                   alternateButton:NSLocalizedString(@"Cancel", nil)
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"Enabling this option will cause HardwareGrowler to run without showing a dock icon or a menu item.\n\nTo access preferences, tap HardwareGrowler in Launchpad, or open HardwareGrowler in Finder.", nil)];
                    NSInteger allow = [alert runModal];
                    if(allow == NSAlertDefaultReturn)
                    {
                        [self warnUserAboutIcons];
                        [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
                        [statusItem release];
                        statusItem = nil;
                    }
                    else
                    {
                        [[[NSUserDefaultsController sharedUserDefaultsController] defaults] setInteger:oldIconValue forKey:@"Visibility"];
                        [[[NSUserDefaultsController sharedUserDefaultsController] defaults] synchronize];
                        [iconPopUp selectItemAtIndex:oldIconValue];
                    }
                    break;
                case kShowIconInBoth:
                    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
                    if(!statusItem)
                        [self initMenu];
                    break;
                case kShowIconInDock:
                    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
                    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
                    [statusItem release];
                    statusItem = nil;
                    break;
                case kShowIconInMenu:
                default:
                    if(!statusItem)
                        [self initMenu];
                    if(oldIconValue == kShowIconInBoth || oldIconValue == kShowIconInDock)
                        [self warnUserAboutIcons];
                    break;
            }
        oldIconValue = index;
    }
    else if ([keyPath isEqualToString:@"values.OnLogin"])
    {
        NSInteger index = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] integerForKey:@"OnLogin"];
        if((index == 0) && (oldOnLoginValue != index))
        {
            [NSApp activateIgnoringOtherApps:YES];
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert! Enabling this option will add HardwareGrowler to your login items", nil)
                                             defaultButton:NSLocalizedString(@"Ok", nil)
                                           alternateButton:NSLocalizedString(@"Cancel", nil)
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Allowing this will let HardwareGrowler launch everytime you login, so that it is available for applications which use it at all times", nil)];
            NSInteger allow = [alert runModal];
            if(allow == NSAlertDefaultReturn)
            {
                [self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:YES];
            }
            else
            {
                [self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:NO];
                [[[NSUserDefaultsController sharedUserDefaultsController] defaults] setInteger:oldOnLoginValue forKey:@"OnLogin"];
                [[[NSUserDefaultsController sharedUserDefaultsController] defaults] synchronize];
                [onLoginSegmentedControl setSelectedSegment:oldOnLoginValue];
            }
        }
        else
            [self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:NO];

        oldOnLoginValue = index;
    }
}

- (void)warnUserAboutIcons
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:NSLocalizedString(@"This setting will take effect when Hardware Growler restarts",nil)];
    [alert runModal];    
}

- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled {
	OSStatus status;
	CFURLRef URLToToggle = (CFURLRef)[NSURL fileURLWithPath:path];
	LSSharedFileListItemRef existingItem = NULL;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL);
    if(loginItems)
    {
	UInt32 seed = 0U;
	NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
	for (id itemObject in currentLoginItems) {
		LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
        
		UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
		CFURLRef URL = NULL;
		OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
		if (err == noErr) {
			Boolean foundIt = CFEqual(URL, URLToToggle);
			CFRelease(URL);
            
			if (foundIt) {
				existingItem = item;
				break;
			}
		}
	}
    
	if (enabled && (existingItem == NULL)) {
		NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
		IconRef icon = NULL;
		FSRef ref;
		Boolean gotRef = CFURLGetFSRef(URLToToggle, &ref);
		if (gotRef) {
			status = GetIconRefFromFileInfo(&ref,
											/*fileNameLength*/ 0, /*fileName*/ NULL,
											kFSCatInfoNone, /*catalogInfo*/ NULL,
											kIconServicesNormalUsageFlag,
											&icon,
											/*outLabel*/ NULL);
			if (status != noErr)
				icon = NULL;
		}
        
		LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, (CFStringRef)displayName, icon, URLToToggle, /*propertiesToSet*/ NULL, /*propertiesToClear*/ NULL);
	} else if (!enabled && (existingItem != NULL))
		LSSharedFileListItemRemove(loginItems, existingItem);
    
    CFRelease(loginItems);
    }
}

@end
