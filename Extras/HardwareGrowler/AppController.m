#import "AppController.h"
#import "FireWireNotifier.h"
#import "USBNotifier.h"
#import "BluetoothNotifier.h"
#import "VolumeNotifier.h"
#import "NetworkNotifier.h"
#import <Growl/Growl.h>

@implementation AppController

-(void)awakeFromNib
{
	bluetoothLogoData = [[[NSImage imageNamed: @"BluetoothLogo.tiff"] TIFFRepresentation] retain];
	ejectLogoData = [[[NSImage imageNamed: @"eject.icns"] TIFFRepresentation] retain];
	firewireLogoData = [[[NSImage imageNamed: @"FireWireLogo.png"] TIFFRepresentation] retain];
	usbLogoData = [[[NSImage imageNamed: @"usbLogoWhite.png"] TIFFRepresentation] retain];

	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	
	NSString *path = [ws fullPathForApplication:@"Airport Admin Utility.app"];
	airportIconData = [[[ws iconForFile:path] TIFFRepresentation] retain];

	path = [ws fullPathForApplication:@"Internet Connect.app"];
	ipIconData = [[[ws iconForFile:path] TIFFRepresentation] retain];

	NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
	
	//Register ourselves as a Growl delegate for registration purposes
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	[nc addObserver: self
		   selector: @selector(fwDidConnect:)
			   name: NotifierFireWireConnectionNotification
			 object: nil];
	
	[nc addObserver: self
		   selector: @selector(fwDidDisconnect:)
			   name: NotifierFireWireDisconnectionNotification
			 object: nil];
	
	
	[nc addObserver: self
		   selector: @selector(usbDidConnect:)
			   name: NotifierUSBConnectionNotification
			 object: nil];
	
	[nc addObserver: self
		   selector: @selector(usbDidDisconnect:)
			   name: NotifierUSBDisconnectionNotification
			 object: nil];


	[nc addObserver: self
		   selector: @selector(bluetoothDidConnect:)
			   name: NotifierBluetoothConnectionNotification
			 object: nil];
	
	[nc addObserver: self
		   selector: @selector(bluetoothDidDisconnect:)
			   name: NotifierBluetoothDisconnectionNotification
			 object: nil];


	[nc addObserver: self
		   selector: @selector(volumeDidMount:)
			   name: NotifierVolumeMountedNotification
			 object: nil];
	
	[nc addObserver: self
		   selector: @selector(volumeDidUnmount:)
			   name: NotifierVolumeUnmountedNotification
			 object: nil];

	
	[nc addObserver: self
		   selector: @selector(linkUp:)
			   name: NotifierNetworkLinkUpNotification
			 object: nil];

	[nc addObserver: self
		   selector: @selector(linkDown:)
			   name: NotifierNetworkLinkDownNotification
			 object: nil];

	[nc addObserver: self
		   selector: @selector(ipAcquired:)
			   name: NotifierNetworkIpAcquiredNotification
			 object: nil];
	
	[nc addObserver: self
		   selector: @selector(ipReleased:)
			   name: NotifierNetworkIpReleasedNotification
			 object: nil];
	
	[nc addObserver: self
		   selector: @selector(airportConnect:)
			   name: NotifierNetworkAirportConnectNotification
			 object: nil];
	
	[nc addObserver: self
		   selector: @selector(airportDisconnect:)
			   name: NotifierNetworkAirportDisconnectNotification
			 object: nil];
	
	fwNotifier = [[FireWireNotifier alloc] init];
	usbNotifier = [[USBNotifier alloc] init];
	btNotifier = [[BluetoothNotifier alloc] init];
	volNotifier = [[VolumeNotifier alloc] init];
	netNotifier = [[NetworkNotifier alloc] init];
}

-(void)dealloc
{
	[fwNotifier release];
	[usbNotifier release];
	[btNotifier release];
	[volNotifier release];
	[netNotifier release];
	
	[bluetoothLogoData release];
	[ejectLogoData release];
	[airportIconData release];
	[ipIconData release];
	
	[super dealloc];
}

-(NSString*) applicationNameForGrowl {
	return @"Hardware Growler";
}

-(NSDictionary*) registrationDictionaryForGrowl {
	//	Register with Growl

	NSMutableArray *notifications = [NSArray arrayWithObjects:
		NotifierBluetoothConnectionNotification,
		NotifierBluetoothDisconnectionNotification,
		NotifierFireWireConnectionNotification,
		NotifierFireWireDisconnectionNotification,
		NotifierUSBConnectionNotification,
		NotifierUSBDisconnectionNotification,
		NotifierVolumeMountedNotification,
		NotifierVolumeUnmountedNotification,
		NotifierNetworkLinkUpNotification,
		NotifierNetworkLinkDownNotification,
		NotifierNetworkIpAcquiredNotification,
		NotifierNetworkIpReleasedNotification,
		NotifierNetworkAirportConnectNotification,
		NotifierNetworkAirportDisconnectNotification,
		nil];

	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Hardware Growler", GROWL_APP_NAME,
		notifications, GROWL_NOTIFICATIONS_ALL,
		notifications,GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	return regDict;
}

- (IBAction)doSimpleHelp: (id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"readme" ofType:@"txt"]]; 
}

#pragma mark -
#pragma mark Notification methods 

-(void)fwDidConnect:(NSNotification*)note
{
//	NSLog(@"FireWire Connect: %@" , [note object] );
	
	[GrowlApplicationBridge notifyWithTitle:@"FireWire Connection"
							description:[note object]
							notificationName:NotifierFireWireConnectionNotification
							iconData:firewireLogoData 
							priority:0
							isSticky:NO
							clickContext:nil];

	}

-(void)fwDidDisconnect:(NSNotification*)note
{
//	NSLog(@"FireWire Disconnect: %@" , [note object] );

	[GrowlApplicationBridge notifyWithTitle:@"FireWire Disconnection"
							description:[note object]
							notificationName:NotifierFireWireConnectionNotification
							iconData:firewireLogoData 
							priority:0
							isSticky:NO
							clickContext:nil];
}

-(void)usbDidConnect:(NSNotification*)note
{
//	NSLog(@"USB Connect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"USB Connection"
							description:[note object]
							notificationName:NotifierUSBConnectionNotification
							iconData:usbLogoData 
							priority:0
							isSticky:NO
							clickContext:nil];
}

-(void)usbDidDisconnect:(NSNotification*)note
{
//	NSLog(@"USB Disconnect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"USB Disconnection"
							description:[note object]
							notificationName:NotifierUSBDisconnectionNotification
							iconData:usbLogoData 
							priority:0
							isSticky:NO
							clickContext:nil];
}


-(void)bluetoothDidConnect:(NSNotification*)note
{
//	NSLog(@"Bluetooth Connect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"Bluetooth Connection"
							description:[note object]
							notificationName:NotifierBluetoothConnectionNotification
							iconData:bluetoothLogoData 
							priority:0
							isSticky:NO
							clickContext:nil];
}

-(void)bluetoothDidDisconnect:(NSNotification*)note
{
//	NSLog(@"Bluetooth Disconnect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"Bluetooth Disconnection"
							description:[[note object] lastPathComponent]
							notificationName:NotifierBluetoothDisconnectionNotification
							iconData:bluetoothLogoData 
							priority:0
							isSticky:NO
							clickContext:nil];
}

-(void)volumeDidMount:(NSNotification*)note
{
//	NSLog(@"volume Mount: %@" , [note object] );

	NSData	*iconData = [[[NSWorkspace sharedWorkspace] iconForFile: [note object]] TIFFRepresentation];  

	[GrowlApplicationBridge notifyWithTitle:@"Volume Mounted"
							description:[[note object] lastPathComponent]
							notificationName:NotifierVolumeMountedNotification
							iconData:iconData 
							priority:0
							isSticky:NO
							clickContext:nil];
}

-(void)volumeDidUnmount:(NSNotification*)note
{
//	NSLog(@"volume UnMount: %@" , [note object] );
	
//	NSData	*iconData = [[[NSWorkspace sharedWorkspace] iconForFile: [note object]] TIFFRepresentation];  
	[GrowlApplicationBridge notifyWithTitle:@"Volume Unmounted"
							description:[[note object] lastPathComponent]
							notificationName:NotifierVolumeUnmountedNotification
							iconData:ejectLogoData 
							priority:0
							isSticky:NO
							clickContext:nil];
}

-(void)airportConnect:(NSNotification*)note
{
	[GrowlApplicationBridge notifyWithTitle:@"Airport connected"
								description:[note object]
						   notificationName:NotifierNetworkAirportConnectNotification
								   iconData:airportIconData 
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)airportDisconnect:(NSNotification*)note
{
	[GrowlApplicationBridge notifyWithTitle:@"Airport disconnected"
								description:[note object]
						   notificationName:NotifierNetworkAirportDisconnectNotification
								   iconData:airportIconData 
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)linkUp:(NSNotification*)note
{
	[GrowlApplicationBridge notifyWithTitle:@"Ethernet activated"
								description:[note object]
						   notificationName:NotifierNetworkLinkUpNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)linkDown:(NSNotification*)note
{
	[GrowlApplicationBridge notifyWithTitle:@"Ethernet deactivated"
								description:[note object]
						   notificationName:NotifierNetworkLinkDownNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)ipAcquired:(NSNotification*)note
{
	[GrowlApplicationBridge notifyWithTitle:@"IP address acquired"
								description:[NSString stringWithFormat:@"New primary IP: %@", [note object]]
						   notificationName:NotifierNetworkIpAcquiredNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)ipReleased:(NSNotification*)note
{
	[GrowlApplicationBridge notifyWithTitle:@"IP address released"
								description:@"No IP address now"
						   notificationName:NotifierNetworkIpReleasedNotification
								   iconData:ipIconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

@end
