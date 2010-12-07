//
//  GrowlMailUUIDPatcherAppDelegate.m
//  GrowlMailUUIDPatcher
//
//  Created by Rudy Richter on 7/10/10.
//  Copyright 2010 Beware Reactor. All rights reserved.
//

#import "GrowlMailUUIDPatcherAppDelegate.h"

#import "GrowlMailUUIDPatcher.h"

@implementation GrowlMailUUIDPatcherAppDelegate

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification {
	patcher = [[GrowlMailUUIDPatcher alloc] init];
}

- (void) dealloc {
	[patcher release];
	[super dealloc];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

@end
