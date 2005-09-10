//
//  VolumeNotifier.c
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#include "VolumeNotifier.h"
#include "AppController.h"
#include <DiskArbitration/DiskArbitration.h>

extern void NSLog(CFStringRef format, ...);

static DASessionRef session;

static void diskDescriptionChanged(DADiskRef disk, CFArrayRef keys, void *userInfo) {
#pragma(userInfo)
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFStringRef name = CFDictionaryGetValue(description, kDADiskDescriptionVolumeNameKey);
	CFURLRef pathURL = CFDictionaryGetValue(description, kDADiskDescriptionVolumePathKey);
	if (pathURL) {
		CFStringRef path = CFURLCopyFileSystemPath(pathURL, kCFURLPOSIXPathStyle);
		AppController_volumeDidMount(name, path);
		CFRelease(path);
	} else
		AppController_volumeDidUnmount(name);
	CFRelease(description);
}

void VolumeNotifier_init(void) {
	session = DASessionCreate(kCFAllocatorDefault);
	DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	/* We use the disk description changed callback and not the disk
	 * appeared callback because we need volume path to find the icon.
	 * The volume path is not available at the time the disk appears, it
	 * is set at a later point in time and the disk description changed
	 * callback is fired.
	 */
	DARegisterDiskDescriptionChangedCallback(session, kDADiskDescriptionMatchVolumeMountable, kDADiskDescriptionWatchVolumePath, diskDescriptionChanged, NULL);
}

void VolumeNotifier_dealloc(void) {
	DAUnregisterCallback(session, diskDescriptionChanged, NULL);
	DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	CFRelease(session);
}
