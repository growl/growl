/* BluetoothNotifier */

#import <Cocoa/Cocoa.h>

#import <IOBluetooth/Bluetooth.h>
#import <IOBluetooth/objc/IOBluetoothOBEXSession.h>

#include "MFIOBluetoothDeviceAdditions.h"

extern	NSString		*NotifierBluetoothConnectionNotification;
extern	NSString		*NotifierBluetoothDisconnectionNotification;



@interface BluetoothNotifier : NSObject
{


}

-(void)setUpBluetoothNotifications;

@end
