//
//  GrowlApplicationBridge.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Based on GrowlApplicationBridge.m by Evan Schoenberg.
//

#include <Carbon/Carbon.h>

#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	CFSTR("com.growl.prefpanel")

typedef void (*GrowlLaunchCallback)(void *context);

Boolean LaunchGrowlIfInstalled(GrowlLaunchCallback callback, void *context);
