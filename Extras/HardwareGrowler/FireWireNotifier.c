#include "FireWireNotifier.h"
#include <IOKit/IOKitLib.h>

extern void NSLog(CFStringRef format, ...);

static struct FireWireNotifierCallbacks	callbacks;
static IONotificationPortRef			ioKitNotificationPort;
static CFRunLoopSourceRef				notificationRunLoopSource;
static Boolean							notificationsArePrimed = false;

static CFStringRef nameForFireWireObject(io_object_t thisObject) {
	//	This works with USB devices...
	//	but apparently not firewire
	kern_return_t	nameResult;
	io_name_t		deviceNameChars;

	nameResult = IORegistryEntryGetName(thisObject, deviceNameChars);
	CFStringRef tempDeviceName = CFStringCreateWithCString(kCFAllocatorDefault,
														   deviceNameChars,
														   kCFStringEncodingASCII);
	if (CFStringCompare(tempDeviceName, CFSTR("IOFireWireDevice"), 0) != kCFCompareEqualTo)
		return tempDeviceName;

	tempDeviceName = IORegistryEntrySearchCFProperty(thisObject,
													 kIOFireWirePlane,
													 CFSTR("FireWire Product Name"),
													 nil,
													 kIORegistryIterateRecursively);

	if (tempDeviceName)
		return tempDeviceName;

	tempDeviceName = IORegistryEntrySearchCFProperty(thisObject,
													 kIOFireWirePlane,
													 CFSTR("FireWire Vendor Name"),
													 nil,
													 kIORegistryIterateRecursively);

	if (tempDeviceName)
		return tempDeviceName;

	return CFSTR("Unnamed FireWire Device");
}

#pragma mark Callbacks

static void fwDeviceAdded(void *refCon, io_iterator_t iterator) {
#pragma unused(refCon)
//	NSLog(@"FireWire Device Added Notification.");
	io_object_t	thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		Boolean keyExistsAndHasValidFormat;
		if (notificationsArePrimed || CFPreferencesGetAppBooleanValue(CFSTR("ShowExisting"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat)) {
			if (callbacks.didConnect) {
				CFStringRef deviceName = nameForFireWireObject(thisObject);
				// NSLog(@"FireWire Device Attached: %@" , deviceName);
				callbacks.didConnect(deviceName);
				CFRelease(deviceName);
			}
		}
		IOObjectRelease(thisObject);
	}
}

static void fwDeviceRemoved(void *refCon, io_iterator_t iterator) {
#pragma unused(refCon)
//	NSLog(@"FireWire Device Removed Notification.");
	io_object_t thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		if (callbacks.didDisconnect) {
			CFStringRef deviceName = nameForFireWireObject(thisObject);
			// NSLog(@"FireWire Device Removed: %@" , deviceName);
			callbacks.didDisconnect(deviceName);
			CFRelease(deviceName);
		}
		
		IOObjectRelease(thisObject);
	}
}

#pragma mark -

static void registerForFireWireNotifications(void) {
	//http://developer.apple.com/documentation/DeviceDrivers/Conceptual/AccessingHardware/AH_Finding_Devices/chapter_4_section_2.html#//apple_ref/doc/uid/TP30000379/BABEACCJ
	kern_return_t   matchingResult;
	io_iterator_t   gFWAddedIter;
	kern_return_t   removeNoteResult;
	io_iterator_t   removedIterator;
	CFDictionaryRef myFireWireMatchDictionary;

//	NSLog(@"registerForFireWireNotifications");

	//	Setup a matching Dictionary.
	//		myFireWireMatchDictionary = IOServiceMatching(kIOUSBDeviceClassName);
	myFireWireMatchDictionary = IOServiceMatching("IOFireWireDevice");

	//	Register our notification
	matchingResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
													  kIOPublishNotification,
													  myFireWireMatchDictionary,
													  fwDeviceAdded,
													  NULL,
													  &gFWAddedIter);

	if (matchingResult)
		NSLog(CFSTR("matching notification registration failed: %d)"), matchingResult);

	//	Prime the Notifications (And Deal with the existing devices)...
	fwDeviceAdded(NULL, gFWAddedIter);

	//	Register for removal notifications.
	//	It seems we have to make a new dictionary...  reusing the old one didn't work.

	//		myFireWireMatchDictionary = IOServiceMatching(kIOUSBDeviceClassName);
	myFireWireMatchDictionary = IOServiceMatching("IOFireWireDevice");
	removeNoteResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
														kIOTerminatedNotification,
														myFireWireMatchDictionary,
														fwDeviceRemoved,
														NULL,
														&removedIterator);

	// Matching notification must be "primed" by iterating over the
	// iterator returned from IOServiceAddMatchingNotification(), so
	// we call our device removed method here...
	//
	if (kIOReturnSuccess != removeNoteResult)
		NSLog(CFSTR("Couldn't add device removal notification"));
	else
		fwDeviceRemoved(NULL, removedIterator);

	notificationsArePrimed = true;
}

#pragma mark -

void FireWireNotifier_init(const struct FireWireNotifierCallbacks *c) {
	callbacks = *c;
	notificationsArePrimed = false;
//#warning	kIOMasterPortDefault is only available on 10.2 and above...
	ioKitNotificationPort = IONotificationPortCreate(kIOMasterPortDefault);
	notificationRunLoopSource = IONotificationPortGetRunLoopSource(ioKitNotificationPort);

	CFRunLoopAddSource(CFRunLoopGetCurrent(),
					   notificationRunLoopSource,
					   kCFRunLoopDefaultMode);
	CFRelease(notificationRunLoopSource);
	registerForFireWireNotifications();
}

void FireWireNotifier_dealloc(void) {
	if (ioKitNotificationPort) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
		IONotificationPortDestroy(ioKitNotificationPort);
	}
}
