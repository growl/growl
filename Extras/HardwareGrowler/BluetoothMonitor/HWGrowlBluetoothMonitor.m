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

@interface HWGrowlBluetoothMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign) BOOL starting;

@property (nonatomic, assign) IOBluetoothUserNotification *connectionNotification;

@end

@implementation HWGrowlBluetoothMonitor

@synthesize delegate;
@synthesize starting;
@synthesize connectionNotification;

-(void)dealloc {
	[connectionNotification unregister];
	connectionNotification = nil;
	[super dealloc];
}

#ifndef NSFoundationVersionNumber10_7
#define NSFoundationVersionNumber10_7   833.1
#endif
#ifndef NSFoundationVersionNumber10_7_3
#define NSFoundationVersionNumber10_7_3 833.24
#endif
-(id)init {
	if((BOOL)isgreaterequal(NSFoundationVersionNumber, NSFoundationVersionNumber10_7) &&
		(BOOL)isless(NSFoundationVersionNumber, NSFoundationVersionNumber10_7_3))
	{
		NSLog(@"Bluetooth Module does not work on 10.7-10.7.2, please upgrade to 10.7.3");
		if(![[NSUserDefaults standardUserDefaults] boolForKey:@"SuppressBluetoothModuleWarn"]){
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Bluetooth Module on OSX Lion requires 10.7.3", @"")
														defaultButton:NSLocalizedString(@"Ok", @"") 
													 alternateButton:nil
														  otherButton:nil
										informativeTextWithFormat:NSLocalizedString(@"In order to receive notifications about Bluetooth devices on OSX Lion, please upgrade to 10.7.3 or above", @"")];
			alert.showsSuppressionButton = YES;
			[[alert suppressionButton] bind:NSValueBinding
										  toObject:[NSUserDefaultsController sharedUserDefaultsController]
									  withKeyPath:@"values.SuppressBluetoothModuleWarn"
											options:nil];
			[alert runModal];
		}
		[self release];
		return nil;
	}
	
	if((self = [super init])){
		
	}
	return self;
}

-(void)postRegistrationInit {
	self.starting = YES;
	self.connectionNotification = [IOBluetoothDevice registerForConnectNotifications:self 
																									selector:@selector(bluetoothConnection:device:)];
	self.starting = NO;
}

-(void)bluetoothName:(NSString*)name connected:(BOOL)connected {
	NSString *title = connected ? NSLocalizedString(@"Bluetooth Connection", @"") : NSLocalizedString(@"Bluetooth Disconnection", @"");
	
	[delegate notifyWithName:connected ? @"BluetoothConnected" : @"BluetoothDisconnected"
							 title:title
					 description:name
							  icon:connected ? [[NSImage imageNamed:@"Bluetooth-On"] TIFFRepresentation] : [[NSImage imageNamed:@"Bluetooth-Off"] TIFFRepresentation]
			  identifierString:name
				  contextString:nil
							plugin:self];
}

-(void)bluetoothDisconnection:(IOBluetoothUserNotification*)note 
							  device:(IOBluetoothDevice*)device
{
	[self bluetoothName:[device name] connected:NO];
	[note unregister];
	
}

-(void)bluetoothConnection:(IOBluetoothUserNotification*)note 
						  device:(IOBluetoothDevice*)device 
{
	if (!starting || [delegate onLaunchEnabled])
		[self bluetoothName:[device name] connected:YES];
	
	[device registerForDisconnectNotification:self selector:@selector(bluetoothDisconnection:device:)];
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate {
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return NSLocalizedString(@"Bluetooth Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsBluetooth"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"BluetoothConnected", @"BluetoothDisconnected", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Bluetooth Connected", @""), @"BluetoothConnected",
			  NSLocalizedString(@"Bluetooth Disconnected", @""), @"BluetoothDisconnected", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sent when a Bluetooth Device is connected", @""), @"BluetoothConnected",
			  NSLocalizedString(@"Sent when a Bluetooth Device is disconnected", @""), @"BluetoothDisconnected", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"BluetoothConnected", @"BluetoothDisconnected", nil];
}

@end
