/*
 *  HelperMain.m
 *  Growl
 *
 *  Created by Karl Adam on Thu Apr 22 2004.
 *  Copyright (c) 2004 The Growl Project. All rights reserved.
 *
 */

#import "GrowlApplicationController.h"
#import "GrowlApplication.h"

int main(int argc, const char *argv[]) {
#pragma unused (argc)
#pragma unused (argv)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[GrowlApplication sharedApplication];
	[NSApp setDelegate:[GrowlApplicationController sharedInstance]];
#ifdef __LP64__
	// So that we can calculate the main menu's height later on:
	// (This is 64-bit only because the 32-bit API has NSMenuView, and the -menuBarHeight method is a recent addition.)
	[NSApp setMainMenu:[[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease]];
#endif
	[pool release];

	[NSApp run];

	return EXIT_SUCCESS;
}


