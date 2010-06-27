#include "FireWireNotifier.h"
#include "AppController.h"
#include <IOKit/IOKitLib.h>

extern void NSLog(CFStringRef format, ...);

static IONotificationPortRef			ioKitNotificationPort;
static CFRunLoopSourceRef				notificationRunLoopSource;
static Boolean							notificationsArePrimed = false;

static CFStringRef nameForFireWireObject(io_object_t thisObject) {
	//	This works with USB devices...
	//	but apparently not firewire
	kern_return_t	nameResult;
	io_name_t		deviceNameChars;

	nameResult = IORegistryEntryGetName(thisObject, deviceNameChars);
	if (nameResult != KERN_SUCCESS) {
		NSLog(CFSTR("Could not get name for FireWire object: IORegistryEntryGetName returned 0x%x"), nameResult);
		return NULL;
	}
	CFStringRef tempDeviceName = CFStringCreateWithCString(kCFAllocatorDefault,
														   deviceNameChars,
														   kCFStringEncodingASCII);
	if (tempDeviceName) {
		if (CFStringCompare(tempDeviceName, CFSTR("IOFireWireDevice"), 0) != kCFCompareEqualTo)
			return tempDeviceName;
		else
			CFRelease(tempDeviceName);
	}

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

	return CFCopyLocalizedString(CFSTR("Unnamed FireWire Device"), "");
}

#pragma mark Callbacks

static void fwDeviceAdded(void *refCon, io_iterator_t iterator) {
#pragma unused(refCon)
//	NSLog(@"FireWire Device Added Notification.");
	io_object_t	thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		Boolean keyExistsAndHasValidFormat;
		if (notificationsArePrimed || CFPreferencesGetAppBooleanValue(CFSTR("ShowExisting"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat)) {
			CFStringRef deviceName = nameForFireWireObject(thisObject);
			// NSLog(@"FireWire Device Attached: %@" , deviceName);
			AppController_fwDidConnect(deviceName);
			CFRelease(deviceName);
		}
		IOObjectRelease(thisObject);
	}
}

static void fwDeviceRemoved(void *refCon, io_iterator_t iterator) {
#pragma unused(refCon)
//	NSLog(@"FireWire Device Removed Notification.");
	io_object_t thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		CFStringRef deviceName = nameForFireWireObject(thisObject);
		// NSLog(@"FireWire Device Removed: %@" , deviceName);
		AppController_fwDidDisconnect(deviceName);
		CFRelease(deviceName);

		IOObjectRelease(thisObject);
	}
}

#pragma mark -

static void registerForFireWireNotifications(void) {
	//http://developer.apple.com/documentation/DeviceDrivers/Conceptual/AccessingHardware/AH_Finding_Devices/chapter_4_section_2.html#//apple_ref/doc/uid/TP30000379/BABEACCJ
	kern_return_t   matchingResult;
	io_iterator_t   addedIterator;
	kern_return_t   removeNoteResult;
	io_iterator_t   removedIterator;
	CFDictionaryRef myFireWireMatchDictionary;

//	NSLog(@"registerForFireWireNotifications");

	//	Setup a matching dictionary.
	myFireWireMatchDictionary = IOServiceMatching("IOFireWireDevice");

	//	Register our notification
	matchingResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
													  kIOPublishNotification,
													  myFireWireMatchDictionary,
													  fwDeviceAdded,
													  NULL,
													  &addedIterator);

	if (matchingResult)
		NSLog(CFSTR("matching notification registration failed: %d)"), matchingResult);

	//	Prime the notifications (And deal with the existing devices)...
	fwDeviceAdded(NULL, addedIterator);

	//	Register for removal notifications.

	//	It seems we have to make a new dictionary...  reusing the old one didn't work.
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

void FireWireNotifier_init(void) {
	notificationsArePrimed = false;
//#warning	kIOMasterPortDefault is only available on 10.2 and above...
	ioKitNotificationPort = IONotificationPortCreate(kIOMasterPortDefault);
	notificationRunLoopSource = IONotificationPortGetRunLoopSource(ioKitNotificationPort);

	CFRunLoopAddSource(CFRunLoopGetCurrent(),
					   notificationRunLoopSource,
					   kCFRunLoopDefaultMode);
	registerForFireWireNotifications();
}

void FireWireNotifier_dealloc(void) {
	if (ioKitNotificationPort) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
		IONotificationPortDestroy(ioKitNotificationPort);
	}
}
