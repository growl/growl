//
//  main.m
//  GrowlTunes
//
//  Created by Nelson Elhage on Mon Jun 21 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlTunesController.h"

int main() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];
	
	GrowlTunesController *growlTunes = [[GrowlTunesController alloc] init];
	
	NSString *itunesPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
	if ([[[NSBundle bundleWithPath:itunesPath] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] floatValue] > 4.6) {
		[growlTunes setPolling:NO];
	} else {
		[growlTunes setPolling:YES];
	}
	
	[NSApp setDelegate:growlTunes];
	[NSApp run];
	
	[growlTunes release];
	[NSApp release];
	[pool release];
	
	return EXIT_SUCCESS;
}
