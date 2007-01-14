/*
 *  GrowlLog.h
 *  GrowlTunes
 *
 *  Created by rudy on 1/14/07.
 *  Copyright 2007 The Growl Project. All rights reserved.
 *
 */
#pragma once

#include <CoreFoundation/CoreFoundation.h>
#include <stdarg.h>

extern void CFShow (CFTypeRef obj);

static void GrowlLog(char * format, ...)
{
	#ifdef DEBUG
		va_list args;
		va_start(args, format);
		
		char *string;
		vasprintf(&string, format, args);
		fprintf(stderr, "%s \n", string);
		free(string);
		va_end(args);
	#else
	#pragma unused(format)
	#endif
}
	
static void GrowlShow (CFTypeRef obj)
{	
	#ifdef DEBUG
		CFShow(obj);
	#else
	#pragma unused(obj)
	#endif
}
