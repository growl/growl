/*
 *  Beep-Carbon-DataBrowser.h
 *  Growl
 *
 *  Created by Mac-arena the Bored Zo on Fri Jun 11 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include "Beep-Carbon.h"
#include <Carbon/Carbon.h>

//property IDs for the notifications list.
enum {
	dataBrowserNotificationNameProperty = 'NAME'
};

OSStatus SetUpDataBrowser(WindowRef window, UInt32 controlIDnum);
