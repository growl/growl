//
//  VolumeNotifier.h
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>

struct VolumeNotifierCallbacks {
	void (*volumeDidMount)(CFStringRef name, CFStringRef path);
	void (*volumeDidUnmount)(CFStringRef name);
};

void VolumeNotifier_init(const struct VolumeNotifierCallbacks *c);
void VolumeNotifier_dealloc(void);
