//
//  GrowlProcessUtilities.h
//  Growl
//
//  Created by Peter Hosey on 2010-07-05.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#include "GrowlDefines.h"

bool Growl_GetPSNForProcessWithBundlePath(STRING_TYPE bundlePath, ProcessSerialNumber *outPSN);
bool Growl_ProcessExistsWithBundleIdentifier(STRING_TYPE bundleID);

bool Growl_HelperAppIsRunning(void);
