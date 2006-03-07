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

static DASessionRef appearSession;
static DASessionRef disappearSession;

static void diskMounted(DADiskRef disk, CFArrayRef keys, void *userInfo) {
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

static void diskUnMounted(DADiskRef disk, CFArrayRef keys, void *userInfo) {
#pragma(userInfo)
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFStringRef name = CFDictionaryGetValue(description, kDADiskDescriptionVolumeNameKey);
	AppController_volumeDidUnmount(name);
	CFRelease(description);
}


void VolumeNotifier_init(void) {
	
	appearSession = DASessionCreate(kCFAllocatorDefault);
	disappearSession = DASessionCreate(kCFAllocatorDefault);
	
	DASessionScheduleWithRunLoop(appearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	DASessionScheduleWithRunLoop(disappearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	DARegisterDiskAppearedCallback(appearSession, kDADiskDescriptionMatchVolumeMountable, diskMounted, NULL);
	DARegisterDiskDisappearedCallback(disappearSession, kDADiskDescriptionMatchVolumeMountable, diskUnMounted, NULL);
}

void VolumeNotifier_dealloc(void) {
	DAUnregisterCallback(appearSession, diskMounted, NULL);
	DAUnregisterCallback(disappearSession, diskUnMounted, NULL);
	DASessionUnscheduleFromRunLoop(appearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	DASessionUnscheduleFromRunLoop(disappearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	CFRelease(appearSession);
	CFRelease(disappearSession);
}
