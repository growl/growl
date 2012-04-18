//
//  GrowlProcessUtilities.h
//  Growl
//
//  Created by Peter Hosey on 2010-07-05.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#include "GrowlDefines.h"

BOOL Growl_GetPSNForProcessWithBundlePath(NSString *bundlePath, ProcessSerialNumber *outPSN);
BOOL Growl_ProcessExistsWithBundleIdentifier(NSString *bundleID);

BOOL Growl_HelperAppIsRunning(void);
