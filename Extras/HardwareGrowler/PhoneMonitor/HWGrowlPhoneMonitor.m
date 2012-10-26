//
//  HWGrowlPhoneMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 6/6/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlPhoneMonitor.h"

@interface HWGrowlPhoneMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;

@property (nonatomic, assign) BOOL starting;
@property (nonatomic, assign) IOBluetoothUserNotification *connectionNotification;

@property (nonatomic, retain) IOBluetoothHandsFree *phone;

@end

@implementation HWGrowlPhoneMonitor

@synthesize delegate;

@synthesize starting;
@synthesize connectionNotification;

@synthesize phone;

-(void)dealloc {
	[connectionNotification unregister];
	connectionNotification = nil;
    
    [phone release];
    phone = nil;
    
	[super dealloc];
}

#ifndef NSFoundationVersionNumber10_7
#define NSFoundationVersionNumber10_7   833.1
#endif
#ifndef NSFoundationVersionNumber10_7_3
#define NSFoundationVersionNumber10_7_3 833.24
#endif
-(id)init {
	if((BOOL)isless(NSFoundationVersionNumber, NSFoundationVersionNumber10_7_3))
	{
		NSLog(@"Phone Module does not work on 10.7-10.7.2, please upgrade to 10.7.3");
		if(![[NSUserDefaults standardUserDefaults] boolForKey:@"SuppressPhoneModuleWarn"]){
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Phone Module requires OSX Lion 10.7.3 or above", @"")
														defaultButton:NSLocalizedString(@"Ok", @"") 
													 alternateButton:nil
														  otherButton:nil
										informativeTextWithFormat:NSLocalizedString(@"In order to receive notifications about Phone Devices, please upgrade to OSX Lion 10.7.3 or above", @"")];
			alert.showsSuppressionButton = YES;
			[[alert suppressionButton] bind:NSValueBinding
										  toObject:[NSUserDefaultsController sharedUserDefaultsController]
									  withKeyPath:@"values.SuppressPhoneModuleWarn"
											options:nil];
			[alert runModal];
		}
		[self release];
		return nil;
	}
	
	if((self = [super init])){
		NSString *path = [[NSBundle mainBundle] pathForResource:@"HandsFreeDeviceSDPRecord" ofType:@"plist"];
		NSDictionary *serviceDict = [NSDictionary dictionaryWithContentsOfFile:path]; 
		if(serviceDict){
			IOReturn result = IOBluetoothAddServiceDict((CFDictionaryRef)serviceDict, NULL);
			if(result != kIOReturnSuccess){
				NSLog(@"Error 0x%x", result);
			}
		}else{
			NSLog(@"couldnt read");
		}
	}
	return self;
}

-(void)postRegistrationInit {
	self.starting = YES;
	self.connectionNotification = [IOBluetoothDevice registerForConnectNotifications:self 
																									selector:@selector(bluetoothConnection:device:)];
	self.starting = NO;
}

-(void)bluetoothDisconnection:(IOBluetoothUserNotification*)note 
							  device:(IOBluetoothDevice*)device
{
	NSLog(@"disconnected");
	self.phone = nil;
	[note	unregister];
}

/* UNDOCUMETED DELEGATE CALL */
-(void)handsFree:(IOBluetoothDevice*)device incomingCallFrom:(NSString*)number {
	NSLog(@"Call %@", number);
	[(IOBluetoothHandsFreeDevice*)device acceptCall];
}

-(void)handsFree:(IOBluetoothHandsFreeDevice *)device 
		currentCall:(NSDictionary *)currentCall
{
	NSLog(@"Call %@", currentCall);	
}

-(void)handsFree:(IOBluetoothHandsFreeDevice *)device 
		incomingSMS:(NSDictionary *)sms
{
	NSLog(@"SMS %@", sms);
}

- (void)handsFree:(IOBluetoothHandsFree *)device connected:(NSNumber *)status {
	
}
- (void)handsFree:(IOBluetoothHandsFree *)device disconnected:(NSNumber *)status {
	
}
- (void)handsFree:(IOBluetoothHandsFree *)device scoConnectionOpened:(NSNumber *)status {
	
}
- (void)handsFree:(IOBluetoothHandsFree *)device scoConnectionClosed:(NSNumber *)status {
	
}

-(void)bluetoothConnection:(IOBluetoothUserNotification*)note 
						  device:(IOBluetoothDevice*)device 
{
	if(device.isHandsFreeAudioGateway){
		NSLog(@"%@", [device name]);
		//if(IOBluetoothLaunchHandsFreeAgent([device addressString]))
		//	NSLog(@"agent launched?");
		
		NSDictionary *scoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																			 forKey:@"Autoconfig hidden"];
		IOReturn result = IOBluetoothAddSCOAudioDevice((IOBluetoothDeviceRef)[device getDeviceRef], (CFDictionaryRef)scoDict); 
		if (result != kIOReturnSuccess)
		{
			NSLog(@"error 0x%x, trying removing and readding", result);
			result = IOBluetoothRemoveSCOAudioDevice((IOBluetoothDeviceRef)device);
			NSLog(@"remove result 0x%x", result);
			result = IOBluetoothAddSCOAudioDevice([device getDeviceRef], (CFDictionaryRef)scoDict);
			if (result != kIOReturnSuccess)
			{
				NSLog(@"error adding SCO audio device. 0x%x", result);
			}
		}
		
		__block HWGrowlPhoneMonitor *blockSelf = self;
		double delayInSeconds = 5.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			IOBluetoothHandsFreeDevice *handsFree = [[IOBluetoothHandsFreeDevice alloc] initWithDevice:device 
																														 delegate:self];
			if(handsFree){
				NSLog(@"yay!");
				
				[handsFree setSupportedFeatures:handsFree.supportedFeatures | IOBluetoothHandsFreeDeviceFeatureCLIPresentation];
				[handsFree connect];
				[blockSelf setPhone:handsFree];
				[handsFree release];
				[device registerForDisconnectNotification:blockSelf selector:@selector(bluetoothDisconnection:device:)];
			}else{
				NSLog(@"Sigh");
			}
		});
	}
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName{
	return NSLocalizedString(@"Phone Module", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsPhone"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	return nil;
}

-(void)fireOnLaunchNotes {
	IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:@"<insert device address here for testing>"];
	[device openConnection];
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"IncomingPhoneCall", @"IncomingSMS", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Incoming Phone Call", @""), @"IncomingPhoneCall", NSLocalizedString(@"Incoming SMS", @""), @"IncomingSMS", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Incoming Phone Call", @""), @"IncomingPhoneCall", NSLocalizedString(@"Incoming SMS", @""), @"IncomingSMS", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"IncomingPhoneCall", @"IncomingSMS", nil];
}

@end
