#include "BluetoothNotifier.h"
#include "AppController.h"
#include <stdlib.h>
#include <IOBluetooth/Bluetooth.h>
#include <IOBluetooth/IOBluetoothUserLib.h>

extern void NSLog(CFStringRef format, ...);

static IOBluetoothUserNotificationRef	connectionNotification;
static Boolean							initializing;

static void bluetoothDisconnection(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothObjectRef objectRef) {
#pragma unused(userRefCon)
	// NSLog(@"BT Device Disconnection: %@" , [device name]);
	AppController_bluetoothDidDisconnect(IOBluetoothDeviceGetName(objectRef));

	IOBluetoothUserNotificationUnregister(inRef);
}

static void bluetoothConnection(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothObjectRef objectRef) {
#pragma unused(userRefCon,status,inRef)
	// NSLog(@"BT Device connection: %@" , [device name]);
	Boolean keyExistsAndHasValidFormat;
	if (!initializing || CFPreferencesGetAppBooleanValue(CFSTR("ShowExisting"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat))
		AppController_bluetoothDidConnect(IOBluetoothDeviceGetName(objectRef));

	IOBluetoothDeviceRegisterForDisconnectNotification(objectRef, bluetoothDisconnection, NULL);
}

/*
static void channelOpened(IOBluetoothUserNotification*)note withChannel: (IOBluetoothRFCOMMChannel *) chan {
	NSLog(@"BT Channel opened.");

	NSLog(@"%@" , [[chan getDevice] name]);

	[chan registerForChannelCloseNotification: self
									 selector: @selector(channelClosed:withChannel:)];

}

static void channelClosed(IOBluetoothUserNotification*)note withChannel: (IOBluetoothRFCOMMChannel *) chan {
	NSLog(@"BT Channel closed. %@" , note);
}
*/

void BluetoothNotifier_init(void) {
	initializing = true;
//	NSLog(@"registering for BT Notes.");
	/*
	 [IOBluetoothRFCOMMChannel registerForChannelOpenNotifications: self
														  selector: @selector(channelOpened:withChannel:)
													 withChannelID: 0
														 direction: kIOBluetoothUserNotificationChannelDirectionAny];
	 */

	connectionNotification = IOBluetoothRegisterForDeviceConnectNotifications(bluetoothConnection, NULL);
	initializing = false;
}

void BluetoothNotifier_dealloc(void) {
	IOBluetoothUserNotificationUnregister(connectionNotification);
}
