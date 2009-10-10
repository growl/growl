/*	GSLMain.m
 *	GrowlSafari
 *
 *	Created by Peter Hosey on 2009-06-14.
 *	Copyright 2009 Peter Hosey. All rights reserved.
 */

//Main program for the GrowlSafariLoader application. Instantiates the GrowlSafariLoader object, sets it as the application delegate, and runs the application.

#import "GrowlSafariLoader.h"

int main(int argc, char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	GrowlSafariLoader *loader = [[GrowlSafariLoader alloc] init];

	NSApplication *app = [NSApplication sharedApplication];
	[app setDelegate:loader];

	int status = NSApplicationMain(argc, (const char **)argv);

	[pool drain];
	return status;
}
