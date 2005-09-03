/* AppController */

#import <Cocoa/Cocoa.h>

@class FireWireNotifier, USBNotifier, BluetoothNotifier, VolumeNotifier, NetworkNotifier, SyncNotifier;

@interface AppController : NSObject {
	FireWireNotifier	*fwNotifier;
	USBNotifier			*usbNotifier;
	BluetoothNotifier	*btNotifier;
	VolumeNotifier		*volNotifier;
	NetworkNotifier		*netNotifier;
	SyncNotifier		*syncNotifier;

	NSData				*bluetoothLogoData;
	NSData				*ejectLogoData;
	NSData				*firewireLogoData;
	NSData				*usbLogoData;
	NSData				*airportIconData;
	NSData				*ipIconData;
	NSData				*iSyncIconData;

	BOOL				sleeping;
}

- (IBAction) doSimpleHelp:(id)sender;

@end
