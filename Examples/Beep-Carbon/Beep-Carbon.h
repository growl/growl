/*
 *  Beep.h
 *  Growl
 *
 *  Created by Mac-arena the Bored Zo on Fri Jun 11 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef BEEP_H

#include <Carbon/Carbon.h>
#include <QuickTime/QuickTime.h>
#include "GrowlDefinesCarbon.h"
#include "Beep-Carbon-ControlIDs.h"

enum {
	appSignature = 'BEEP'
};

enum {
	registerNotificationCmd   = 'ADDN',
	unregisterNotificationCmd = 'DELN',
	registerWithGrowlCmd	  = 'REGD', //as in the Registered checkbox
};

OSStatus updateSendEnabledState(Boolean enabled);
OSStatus updateDeleteEnabledState(Boolean enabled);

#define BEEP_H 1
#endif //ndef BEEP_H