/*
 *  GTPPlugin.h
 *  GrowlTunes
 *
 *  Created by rudy on 7/15/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

CFStringRef GTP_Init(void);
CFDataRef GTP_IconData(CFStringRef artist, CFStringRef title, CFStringRef album, CFStringRef composer, Boolean compilation);
Boolean GTP_Dealloc(void);
