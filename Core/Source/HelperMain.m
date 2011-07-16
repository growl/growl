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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[GrowlApplication sharedApplication];
	[NSApp setDelegate:[GrowlApplicationController sharedInstance]];

	int status = NSApplicationMain(argc, argv);

	[pool release];

	return status;
}


