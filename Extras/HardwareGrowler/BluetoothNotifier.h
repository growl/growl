/* BluetoothNotifier */

#import <Cocoa/Cocoa.h>

extern	NSString		*NotifierBluetoothConnectionNotification;
extern	NSString		*NotifierBluetoothDisconnectionNotification;

@interface BluetoothNotifier : NSObject
{
}

-(void)setUpBluetoothNotifications;

@end
