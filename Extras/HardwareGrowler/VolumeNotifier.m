//
//  VolumeNotifier.m
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "VolumeNotifier.h"

static void diskDescriptionChanged(DADiskRef disk, CFArrayRef keys, void *delegate) {
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFStringRef name = CFDictionaryGetValue(description, kDADiskDescriptionVolumeNameKey);
	CFURLRef pathURL = CFDictionaryGetValue(description, kDADiskDescriptionVolumePathKey);
	if (pathURL) {
		CFStringRef path = CFURLCopyPath(pathURL);
		[(id)delegate volumeDidMount:(NSString *)name atPath:(NSString *)path];
		CFRelease(path);
	} else {
		[(id)delegate volumeDidUnmount:(NSString *)name];
	}
	CFRelease(description);
}

@implementation VolumeNotifier

- (id) initWithDelegate:(id)delegate {
	if ((self = [super init])) {
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
		DARegisterDiskDescriptionChangedCallback(session, filter, kDADiskDescriptionWatchVolumePath, diskDescriptionChanged, delegate);

		CFRelease(filter);
	}

	return self;
}

- (void) dealloc {
	DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	CFRelease(session);

	[super dealloc];
}

@end
