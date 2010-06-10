//
//  GrowlVersionCheck.c
//  Growl
//
//  Created by Peter Hosey on 2009-11-27.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#include "GrowlVersionCheck.h"
#include <CoreServices/CoreServices.h>
#include "CFGrowlAdditions.h"

static const SInt32 minimumOSXVersionForGrowl = 0x1050; //Leopard (10.5.0)

Boolean GrowlCheckOSXVersion(void) {
	SInt32 OSXVersion = 0;
	OSStatus err = Gestalt(gestaltSystemVersion, &OSXVersion);
	if (err != noErr) {
		NSLog(CFSTR("WARNING in GrowlVersionCheck: Could not get Mac OS X version (selector = %x); got error code %li (will show the installation prompt anyway)"), (unsigned)gestaltSystemVersion, (long)err);

		//We proceed anyway, on the theory that it is better to show the installation prompt when inappropriate than to suppress it when not.
		OSXVersion = minimumOSXVersionForGrowl;
	}
	return (OSXVersion >= minimumOSXVersionForGrowl);
}
