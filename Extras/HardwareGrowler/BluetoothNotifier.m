#import "BluetoothNotifier.h"

NSString		*NotifierBluetoothConnectionNotification		=	@"Bluetooth Device Connected";
NSString		*NotifierBluetoothDisconnectionNotification		=	@"Bluetooth Device Disconnected";

@implementation BluetoothNotifier



-(id)init
{
	if (self = [super init]) {
		[self setUpBluetoothNotifications];
	}
	return nil;
}




-(void)setUpBluetoothNotifications
{
	NSLog(@"registering for BT Notes.");
	

	/*
	[IOBluetoothRFCOMMChannel registerForChannelOpenNotifications: self
														 selector: @selector(channelOpened:withChannel:)
													withChannelID: 0
														direction: kIOBluetoothUserNotificationChannelDirectionAny]; 
	*/
	
	[IOBluetoothDevice registerForConnectNotifications: self 
											  selector: @selector(bluetoothConnection:toDevice:)];

}



-(void)dealloc
{

	
	[super	dealloc];
}




/*
-(void)channelOpened: (IOBluetoothUserNotification*)note withChannel: (IOBluetoothRFCOMMChannel *) chan
{
	NSLog(@"BT Channel opened." );

	NSLog(@"%@" , [[chan getDevice] name] );
	

	[chan registerForChannelCloseNotification: self 
									 selector: @selector(channelClosed:withChannel:)]; 

}


-(void)channelClosed: (IOBluetoothUserNotification*)note withChannel: (IOBluetoothRFCOMMChannel *) chan
{
	NSLog(@"BT Channel closed. %@" , note);
}
*/


-(void)bluetoothConnection: (IOBluetoothUserNotification*)note toDevice: (IOBluetoothDevice*)device
{
	[[NSNotificationCenter defaultCenter] postNotificationName: NotifierBluetoothConnectionNotification object: [device name] ];

	// NSLog(@"BT Device connection: %@" , [device name]);	
	[device registerForDisconnectNotification: self
									 selector:@selector(bluetoothDisconnection:fromDevice:)];
}

-(void)bluetoothDisconnection: (IOBluetoothUserNotification*)note fromDevice: (IOBluetoothDevice*)device
{
	[[NSNotificationCenter defaultCenter] postNotificationName: NotifierBluetoothDisconnectionNotification object: [device name] ];
	

	// NSLog(@"BT Device Disconnection: %@" , [device name]);	
}

@end
