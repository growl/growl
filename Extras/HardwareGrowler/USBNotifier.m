#import "USBNotifier.h"

NSString		*NotifierUSBConnectionNotification		=	@"USB Device Connected";
NSString		*NotifierUSBDisconnectionNotification		=	@"USB Device Disconnected";


@implementation USBNotifier




- (id)init
{
	if ((self = [super init])) {
		[self ioKitSetUp];
		[self registerForUSBNotifications];
	}
	return self;
}


-(void)dealloc
{
	[self ioKitTearDown];
	
	[super dealloc];
}


-(void)ioKitSetUp
{
//#warning	kIOMasterPortDefault is only available on 10.2 and above... 
	ioKitNotificationPort = IONotificationPortCreate(kIOMasterPortDefault);
	notificationRunLoopSource = IONotificationPortGetRunLoopSource(ioKitNotificationPort);
	
	CFRunLoopAddSource(CFRunLoopGetCurrent(), 
					   notificationRunLoopSource, 
					   kCFRunLoopDefaultMode);
	
}

-(void)ioKitTearDown
{
	if(ioKitNotificationPort)
	{
		CFRunLoopRemoveSource( CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode );
		IONotificationPortDestroy(ioKitNotificationPort) ;
	}	
}



-(void)registerForUSBNotifications
{
	//http://developer.apple.com/documentation/DeviceDrivers/Conceptual/AccessingHardware/AH_Finding_Devices/chapter_4_section_2.html#//apple_ref/doc/uid/TP30000379/BABEACCJ
	kern_return_t			matchingResult;
	io_iterator_t			addedIterator;
	io_iterator_t			removedIterator;
	
	NSLog(@"registerForUSBNotifications");
	
	//	Setup a matching Dictionary.
	CFDictionaryRef myMatchDictionary;	
	myMatchDictionary = nil;	
	myMatchDictionary = IOServiceMatching(kIOUSBDeviceClassName);

	//	Register our notification
	addedIterator = nil;				
	matchingResult = IOServiceAddMatchingNotification(
													  ioKitNotificationPort,
													  kIOPublishNotification,
													  myMatchDictionary,
													  usbDeviceAdded,
													  (void *) self,
													  (io_iterator_t *) &addedIterator ); 
	
	if (matchingResult) 
		NSLog(@"matching notification registration failed: %d" , matchingResult);
	
	//	Prime the Notifications (And Deal with the existing devices)...
	[self usbDeviceAdded: addedIterator];
	
	
	
	
	
	//	Register for removal notifications.
	//	It seems we have to make a new dictionary...  reusing the old one didn't work.
	
	myMatchDictionary = nil;	
	myMatchDictionary = IOServiceMatching(kIOUSBDeviceClassName);
	kern_return_t			removeNoteResult;
//	io_iterator_t			removedIterator ;
	removeNoteResult = IOServiceAddMatchingNotification(ioKitNotificationPort, 
														kIOTerminatedNotification,
														myMatchDictionary, 
														usbDeviceRemoved, 
														self, 
														&removedIterator );
	
	// Matching notification must be "primed" by iterating over the 
	// iterator returned from IOServiceAddMatchingNotification(), so
	// we call our device removed method here...
	//
	if (kIOReturnSuccess != removeNoteResult) {
		NSLog(@"Couldn't add device removal notification") ;
	} else {
		[self usbDeviceRemoved: removedIterator];
	}
}




-(void)usbDeviceAdded: (io_iterator_t ) iterator
{
//	NSLog(@"USB Device Added Notification.");
	io_object_t		thisObject = nil;
	while ((thisObject = IOIteratorNext( iterator ))) {
		kern_return_t	nameResult;
		io_name_t		deviceNameChars;
		
//		NSLog(@"got one new object.");
		
		//	This works with USB devices...  
		//	but apparently not firewire
		nameResult = IORegistryEntryGetName( thisObject, 
											 deviceNameChars ); 		
		
		NSString	*deviceName = [NSString stringWithCString: deviceNameChars];
		if (!deviceName) {
			deviceName = @"Unnamed USB Device";
		}
		// NSLog(@"USB Device Attached: %@" , deviceName);		
		[[NSNotificationCenter defaultCenter] postNotificationName: NotifierUSBConnectionNotification object: deviceName ];

		IOObjectRelease(thisObject);
	}
}

-(void)usbDeviceRemoved: (io_iterator_t ) iterator
{
//	NSLog(@"USB Device Removed Notification.");
	io_object_t		thisObject = nil;
	while ((thisObject = IOIteratorNext( iterator ))) {
//		NSLog(@"got one new removed object.");
		
		kern_return_t	nameResult;
		io_name_t		deviceNameChars;

		//	This works with USB devices...  
		//	but apparently not firewire
		nameResult = IORegistryEntryGetName( thisObject, 
											 deviceNameChars ); 		
		NSString	*deviceName = [NSString stringWithCString: deviceNameChars];
		if (!deviceName) {
			deviceName = @"Unnamed USB Device";
		}
		// NSLog(@"USB Device Detached: %@" , deviceName);		
		[[NSNotificationCenter defaultCenter] postNotificationName: NotifierUSBDisconnectionNotification object: deviceName ];
		
		IOObjectRelease(thisObject);
	}
}



#pragma mark -
#pragma mark	C Callbacks

void usbDeviceAdded (void *refCon, io_iterator_t iter) {
	[(USBNotifier*)refCon usbDeviceAdded:iter];
}

void usbDeviceRemoved (void *refCon, io_iterator_t iter) {
	[(USBNotifier*)refCon usbDeviceRemoved:iter];
}



@end
