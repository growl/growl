/* BluetoothNotifier */

#import <Cocoa/Cocoa.h>

@class IOBluetoothUserNotification;

@interface BluetoothNotifier : NSObject {
	id                          delegate;
	IOBluetoothUserNotification *connectionNotification;
}

- (id)initWithDelegate:(id)object;

@end

@interface NSObject(BluetoothNotifierDelegate)
- (void)bluetoothDidConnect:(NSString *)device;
- (void)bluetoothDidDisconnect:(NSString *)device;
@end
