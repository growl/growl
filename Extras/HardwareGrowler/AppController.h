/* AppController */

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

#import "FireWireNotifier.h"
#import "USBNotifier.h"
#import "BluetoothNotifier.h"
#import "VolumeNotifier.h"


@interface AppController : NSObject
{
	
	FireWireNotifier					*fwNotifier;
	USBNotifier							*usbNotifier;
	BluetoothNotifier					*btNotifier;
	VolumeNotifier						*volNotifier;
	
	NSDistributedNotificationCenter		*dnc;
	
	
	NSData				*bluetoothLogoData;
	NSData				*ejectLogoData;
	NSData				*firewireLogoData;
	NSData				*usbLogoData;

}


@end
