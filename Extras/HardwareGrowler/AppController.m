#import "AppController.h"


@implementation AppController

-(void)awakeFromNib
{
	bluetoothLogoData = [[[NSImage imageNamed: @"BluetoothLogo.tiff"] TIFFRepresentation] retain];
	ejectLogoData = [[[NSImage imageNamed: @"eject.icns"] TIFFRepresentation] retain];
	firewireLogoData = [[[NSImage imageNamed: @"FireWireLogo.png"] TIFFRepresentation] retain];
	usbLogoData = [[[NSImage imageNamed: @"usbLogoWhite.png"] TIFFRepresentation] retain];
	
	
	
	NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
	dnc = [NSDistributedNotificationCenter defaultCenter];
	
	//	Register with Growl

	NSMutableArray			*notifications = [[NSMutableArray alloc] init];
	
	[notifications addObject: NotifierBluetoothConnectionNotification];
	[notifications addObject: NotifierBluetoothDisconnectionNotification];
	[notifications addObject: NotifierFireWireConnectionNotification];
	[notifications addObject: NotifierFireWireDisconnectionNotification];
	[notifications addObject: NotifierUSBConnectionNotification];
	[notifications addObject: NotifierUSBDisconnectionNotification];
	[notifications addObject: NotifierVolumeMountedNotification];
	[notifications addObject: NotifierVolumeUnmountedNotification];
	
	
	
	NSMutableDictionary		*regDict = [[NSMutableDictionary alloc] init];

	[regDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[regDict setObject: notifications forKey: (NSString *) GROWL_NOTIFICATIONS_ALL];
	[regDict setObject: notifications forKey: (NSString *) GROWL_NOTIFICATIONS_DEFAULT];

	
	[dnc postNotificationName: (NSString *) GROWL_APP_REGISTRATION
					   object: nil
					 userInfo: regDict 
		   deliverImmediately: NO];
	
	[notifications release];
	[regDict release];
	
	
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






#pragma mark -
#pragma mark Notification methods 

-(void)fwDidConnect:(NSNotification*)note
{
//	NSLog(@"FireWire Connect: %@" , [note object] );
	
	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierFireWireConnectionNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"FireWire Connection" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [note object] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: firewireLogoData forKey: (NSString *) GROWL_NOTIFICATION_ICON];

	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}

-(void)fwDidDisconnect:(NSNotification*)note
{
//	NSLog(@"FireWire Disconnect: %@" , [note object] );

	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierFireWireConnectionNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"FireWire Disconnection" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [note object] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: firewireLogoData forKey: (NSString *) GROWL_NOTIFICATION_ICON];
	
	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}

-(void)usbDidConnect:(NSNotification*)note
{
//	NSLog(@"USB Connect: %@" , [note object] );
	
	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierFireWireConnectionNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"USB Connection" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [note object] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: usbLogoData forKey: (NSString *) GROWL_NOTIFICATION_ICON];
	
	
	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}

-(void)usbDidDisconnect:(NSNotification*)note
{
//	NSLog(@"USB Disconnect: %@" , [note object] );
	
	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierFireWireConnectionNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"USB Disconnection" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [note object] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: usbLogoData forKey: (NSString *) GROWL_NOTIFICATION_ICON];
	
	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}


-(void)bluetoothDidConnect:(NSNotification*)note
{
//	NSLog(@"Bluetooth Connect: %@" , [note object] );

	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierFireWireConnectionNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"Bluetooth Connection" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [note object] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: bluetoothLogoData forKey: (NSString *) GROWL_NOTIFICATION_ICON];
		
	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}

-(void)bluetoothDidDisconnect:(NSNotification*)note
{
//	NSLog(@"Bluetooth Disconnect: %@" , [note object] );
	
	
	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierFireWireConnectionNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"Bluetooth Disconnection" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [note object] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: bluetoothLogoData forKey: (NSString *) GROWL_NOTIFICATION_ICON];

	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}


//volumeDidUnmount:

-(void)volumeDidMount:(NSNotification*)note
{
//	NSLog(@"volume Mount: %@" , [note object] );
	
	NSData	*iconData = [[[NSWorkspace sharedWorkspace] iconForFile: [note object]] TIFFRepresentation];  
	
	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierVolumeMountedNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"Volume Mounted" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [[note object] lastPathComponent] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: iconData forKey: (NSString *) GROWL_NOTIFICATION_ICON];
	
		
	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}



-(void)volumeDidUnmount:(NSNotification*)note
{
//	NSLog(@"volume DisMount: %@" , [note object] );
	
	NSData	*iconData = [[[NSWorkspace sharedWorkspace] iconForFile: [note object]] TIFFRepresentation];  
	
	NSMutableDictionary		*noteDict = [[NSMutableDictionary alloc] init];
	[noteDict setObject: @"Hardware Growler" forKey: (NSString *) GROWL_APP_NAME];
	[noteDict setObject: NotifierVolumeUnmountedNotification forKey: (NSString *) GROWL_NOTIFICATION_NAME];
	[noteDict setObject: @"Volume Dismounted" forKey: (NSString *) GROWL_NOTIFICATION_TITLE];
	[noteDict setObject: [[note object] lastPathComponent] forKey: (NSString *) GROWL_NOTIFICATION_DESCRIPTION];
	[noteDict setObject: ejectLogoData forKey: (NSString *) GROWL_NOTIFICATION_ICON];
	
	[dnc postNotificationName: (NSString *) GROWL_NOTIFICATION
					   object: nil
					 userInfo: noteDict 
		   deliverImmediately: NO];
	
	[noteDict release];
}





@end