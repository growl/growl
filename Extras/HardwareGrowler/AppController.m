#import "AppController.h"


@implementation AppController

-(void)awakeFromNib
{
	bluetoothLogoData = [[[NSImage imageNamed: @"BluetoothLogo.tiff"] TIFFRepresentation] retain];
	ejectLogoData = [[[NSImage imageNamed: @"eject.icns"] TIFFRepresentation] retain];
	firewireLogoData = [[[NSImage imageNamed: @"FireWireLogo.png"] TIFFRepresentation] retain];
	usbLogoData = [[[NSImage imageNamed: @"usbLogoWhite.png"] TIFFRepresentation] retain];
	
	
	
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
	
	
	fwNotifier = [[FireWireNotifier alloc] init];
	usbNotifier = [[USBNotifier alloc] init];
	btNotifier = [[BluetoothNotifier alloc] init];
	volNotifier = [[VolumeNotifier alloc] init];

	
}

-(void)dealloc
{
	[fwNotifier release];
	[usbNotifier release];
	[btNotifier release];
	[volNotifier release];
	
	[bluetoothLogoData release];
	[ejectLogoData release];
	
	[super dealloc];
}


-(NSString*) applicationNameForGrowl {
	return @"Hardware Growler";
}
-(NSDictionary*) registrationDictionaryForGrowl {
	//	Register with Growl

	NSMutableArray			*notifications = [[[NSMutableArray alloc] init] autorelease];
	
	[notifications addObject: NotifierBluetoothConnectionNotification];
	[notifications addObject: NotifierBluetoothDisconnectionNotification];
	[notifications addObject: NotifierFireWireConnectionNotification];
	[notifications addObject: NotifierFireWireDisconnectionNotification];
	[notifications addObject: NotifierUSBConnectionNotification];
	[notifications addObject: NotifierUSBDisconnectionNotification];
	[notifications addObject: NotifierVolumeMountedNotification];
	[notifications addObject: NotifierVolumeUnmountedNotification];
	
	
	
	NSMutableDictionary		*regDict = [[[NSMutableDictionary alloc] init] autorelease];

	[regDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[regDict setObject: notifications forKey: (NSString *) GROWL_NOTIFICATIONS_ALL];
	[regDict setObject: notifications forKey: (NSString *) GROWL_NOTIFICATIONS_DEFAULT];

	return regDict;
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
							isSticky:0
							clickContext:NULL];

	}

-(void)fwDidDisconnect:(NSNotification*)note
{
//	NSLog(@"FireWire Disconnect: %@" , [note object] );

	[GrowlApplicationBridge notifyWithTitle:@"FireWire Disconnection"
							description:[note object]
							notificationName:NotifierFireWireConnectionNotification
							iconData:firewireLogoData 
							priority:0
							isSticky:0
							clickContext:NULL];
}

-(void)usbDidConnect:(NSNotification*)note
{
//	NSLog(@"USB Connect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"USB Connection"
							description:[note object]
							notificationName:NotifierUSBConnectionNotification
							iconData:usbLogoData 
							priority:0
							isSticky:0
							clickContext:NULL];
}

-(void)usbDidDisconnect:(NSNotification*)note
{
//	NSLog(@"USB Disconnect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"USB Disconnection"
							description:[note object]
							notificationName:NotifierUSBDisconnectionNotification
							iconData:usbLogoData 
							priority:0
							isSticky:0
							clickContext:NULL];
}


-(void)bluetoothDidConnect:(NSNotification*)note
{
//	NSLog(@"Bluetooth Connect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"Bluetooth Connection"
							description:[note object]
							notificationName:NotifierBluetoothConnectionNotification
							iconData:bluetoothLogoData 
							priority:0
							isSticky:0
							clickContext:NULL];
}

-(void)bluetoothDidDisconnect:(NSNotification*)note
{
//	NSLog(@"Bluetooth Disconnect: %@" , [note object] );
	[GrowlApplicationBridge notifyWithTitle:@"Bluetooth Disconnection"
							description:[[note object] lastPathComponent]
							notificationName:NotifierBluetoothDisconnectionNotification
							iconData:bluetoothLogoData 
							priority:0
							isSticky:0
							clickContext:NULL];
}


//volumeDidUnmount:

-(void)volumeDidMount:(NSNotification*)note
{
//	NSLog(@"volume Mount: %@" , [note object] );

	NSData	*iconData = [[[NSWorkspace sharedWorkspace] iconForFile: [note object]] TIFFRepresentation];  

	[GrowlApplicationBridge notifyWithTitle:@"Volume Mounted"
							description:[[note object] lastPathComponent]
							notificationName:NotifierVolumeMountedNotification
							iconData:iconData 
							priority:0
							isSticky:0
							clickContext:NULL];
}



-(void)volumeDidUnmount:(NSNotification*)note
{
//	NSLog(@"volume DisMount: %@" , [note object] );
	
//	NSData	*iconData = [[[NSWorkspace sharedWorkspace] iconForFile: [note object]] TIFFRepresentation];  
	[GrowlApplicationBridge notifyWithTitle:@"Volume Dismounted"
							description:[[note object] lastPathComponent]
							notificationName:NotifierVolumeUnmountedNotification
							iconData:ejectLogoData 
							priority:0
							isSticky:0
							clickContext:NULL];
}





@end
