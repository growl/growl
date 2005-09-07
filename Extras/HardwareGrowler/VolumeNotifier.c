//
//  VolumeNotifier.m
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#include "VolumeNotifier.h"
#include <DiskArbitration/DiskArbitration.h>

extern void NSLog(CFStringRef format, ...);

static DASessionRef session;
static struct VolumeNotifierCallbacks callbacks;

static void diskDescriptionChanged(DADiskRef disk, CFArrayRef keys, void *userInfo) {
#pragma(userInfo)
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFStringRef name = CFDictionaryGetValue(description, kDADiskDescriptionVolumeNameKey);
	CFURLRef pathURL = CFDictionaryGetValue(description, kDADiskDescriptionVolumePathKey);
	if (pathURL) {
		if (callbacks.volumeDidMount) {
			CFStringRef path = CFURLCopyFileSystemPath(pathURL, kCFURLPOSIXPathStyle);
			callbacks.volumeDidMount(name, path);
			CFRelease(path);
		}
	} else if (callbacks.volumeDidUnmount) {
		callbacks.volumeDidUnmount(name);
	}
	CFRelease(description);
}

void VolumeNotifier_init(const struct VolumeNotifierCallbacks *c) {
	callbacks = *c;
	session = DASessionCreate(kCFAllocatorDefault);
	DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	/* we only want to be notified for volumes that are mountable and ejectable */
	CFTypeRef keys[2] = {kDADiskDescriptionVolumeMountableKey, kDADiskDescriptionMediaEjectableKey};
	CFTypeRef values[2] = {kCFBooleanTrue, kCFBooleanTrue};
	CFDictionaryRef filter = CFDictionaryCreate(kCFAllocatorDefault,
												keys,
												values,
												2,
												&kCFTypeDictionaryKeyCallBacks,
												&kCFTypeDictionaryValueCallBacks);

	/* We use the disk description changed callback and not the disk
	 * appeared callback because we need volume path to find the icon.
	 * The volume path is not available at the time the disk appears, it
	 * is set at a later point in time and the disk description changed
	 * callback is fired.
	 */
	DARegisterDiskDescriptionChangedCallback(session, filter, kDADiskDescriptionWatchVolumePath, diskDescriptionChanged, NULL);

	CFRelease(filter);
}

void VolumeNotifier_dealloc(void) {
	DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	CFRelease(session);
}
