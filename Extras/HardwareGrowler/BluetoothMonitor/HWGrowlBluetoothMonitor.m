//
//  HWGrowlBluetoothMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/5/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlBluetoothMonitor.h"
#import <stdlib.h>
#import <IOBluetooth/IOBluetooth.h>

static void bluetoothDisconnection(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothObjectRef objectRef);
static void bluetoothConnection(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothObjectRef objectRef);

@interface HWGrowlBluetoothMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign) BOOL starting;

@property (nonatomic, assign) IOBluetoothUserNotificationRef connectionNotification;

@end

@implementation HWGrowlBluetoothMonitor

@synthesize delegate;
@synthesize starting;
@synthesize connectionNotification;

-(void)dealloc {
	IOBluetoothUserNotificationUnregister(connectionNotification);
	[super dealloc];
}

-(id)init {
	if((self = [super init])){
		
	}
	return self;
}

-(void)postRegistrationInit {
	self.starting = YES;
	self.connectionNotification = IOBluetoothRegisterForDeviceConnectNotifications(bluetoothConnection, &self);
	self.starting = NO;
}

-(void)bluetoothName:(NSString*)name connected:(BOOL)connected {
	NSString *title = connected ? NSLocalizedString(@"Bluetooth Connection", @"") : NSLocalizedString(@"Bluetooth Disconnection", @"");
	
	[delegate notifyWithName:connected ? @"BluetoothConnected" : @"BluetoothDisconnected"
							 title:title
					 description:name
							  icon:nil
			  identifierString:name
				  contextString:nil
							plugin:self];
}

-(void)bluetoothDisconnection:(IOBluetoothObjectRef)objectRef  {
	[self bluetoothName:[IOBluetoothDevice withDeviceRef:objectRef].name connected:NO];	
}

static void bluetoothDisconnection(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothObjectRef objectRef) {
	// NSLog(@"BT Device Disconnection: %@" , [device name]);
	HWGrowlBluetoothMonitor *monitor = (HWGrowlBluetoothMonitor*)userRefCon;
	[monitor bluetoothDisconnection:objectRef];
	
	IOBluetoothUserNotificationUnregister(inRef);
}

-(void)bluetoothConnection:(IOBluetoothObjectRef)objectRef {
	if (!starting || [delegate onLaunchEnabled])
		[self bluetoothName:[IOBluetoothDevice withDeviceRef:objectRef].name connected:YES];
	
	IOBluetoothDeviceRegisterForDisconnectNotification(objectRef, bluetoothDisconnection, self);
}

static void bluetoothConnection(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothObjectRef objectRef) {
	HWGrowlBluetoothMonitor *monitor = (HWGrowlBluetoothMonitor*)userRefCon;
	[monitor bluetoothConnection:objectRef];
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate {
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return @"Bluetooth Monitor";
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"BluetoothConnected", @"BluetoothDisconnected", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Bluetooth Connected", @"BluetoothConnected",
			  @"Bluetooth Disconnected", @"BluetoothDisconnected", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Sent when a Bluetooth Device is connected", @"BluetoothConnected",
			  @"Sent when a Bluetooth Device is disconnected", @"BluetoothDisconnected", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"BluetoothConnected", @"BluetoothDisconnected", nil];
}

@end
