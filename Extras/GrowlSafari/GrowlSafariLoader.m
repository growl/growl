//
//  GrowlSafariLoader.m
//  GrowlSafari
//
//  Created by Peter Hosey on 2009-06-14.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "GrowlSafariLoader.h"


@interface GrowlSafariLoader ()

- (void) workspaceDidLaunchApplication:(NSNotification *)notification;

@end

#define SAFARI_BUNDLE_ID @"com.apple.Safari"

@implementation GrowlSafariLoader

- (id) init {
	if((self = [super init])) {
		workspace = [[NSWorkspace sharedWorkspace] retain];
		NSNotificationCenter *nc = [workspace notificationCenter];
		NSLog(@"Adding %@ as an observer on %@ for %@ with object %@", self, nc, NSWorkspaceDidLaunchApplicationNotification, workspace);
		[nc addObserver:self
			   selector:@selector(workspaceDidLaunchApplication:)
				   name:NSWorkspaceDidLaunchApplicationNotification
				 object:nil];
		
#if defined(__x86_64__)
		OSStatus err;
		SInt32 majorSystemVersion = 10, minorSystemVersion = 0;
		err = Gestalt(gestaltSystemVersionMajor, &majorSystemVersion);
		if (err != noErr) {
			NSLog(@"Could not get major system version number: %i/%s", err, GetMacOSStatusCommentString(err));
			NSLog(@"GrowlSafari will now quit.");
			[[NSApplication sharedApplication] terminate:nil];
		}
		err = Gestalt(gestaltSystemVersionMinor, &minorSystemVersion);
		if (err != noErr) {
			NSLog(@"Could not get minor system version number: %i/%s", err, GetMacOSStatusCommentString(err));
			NSLog(@"GrowlSafari will now quit.");
			[[NSApplication sharedApplication] terminate:nil];
		}

		//Safari does not exist in 64-bit on Leopard, so GrowlSafari cannot work in 64-bit on Leopard.
		//Since this is the 64-bit version, if we're running on Leopard, quit.
		if (majorSystemVersion == 10 && minorSystemVersion == 5) {
			NSLog(@"GrowlSafari cannot inject into Safari when running in 64-bit on Leopard. GrowlSafari will now quit.");
			[[NSApplication sharedApplication] terminate:nil];
		}
#endif
	}
	return self;
}

- (void) dealloc {
	NSNotificationCenter *nc = [workspace notificationCenter];
	[nc removeObserver:self
				  name:NSWorkspaceDidLaunchApplicationNotification
				object:workspace];
	[workspace release];

	[super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
	//Scan for running Safari instances, and send ourselves messages as if NSWorkspace had posted notifications about them.
	NSEnumerator *appsEnum = [[workspace launchedApplications] objectEnumerator];
	NSDictionary *appDict;
	while ((appDict = [appsEnum nextObject])) {
		NSNotification *notification = [NSNotification notificationWithName:NSWorkspaceDidLaunchApplicationNotification object:workspace userInfo:appDict];
		[self workspaceDidLaunchApplication:notification];
	}
}

- (void) workspaceDidLaunchApplication:(NSNotification *)notification {
	NSDictionary *launchedProcessInfo = [notification userInfo];
	NSString *bundleID = [launchedProcessInfo objectForKey:@"NSApplicationBundleIdentifier"];
	if (bundleID && [bundleID caseInsensitiveCompare:SAFARI_BUNDLE_ID] == NSOrderedSame) {
		NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"GrowlSafari" ofType:@"bundle"];
		if (bundlePath) {
			NSNumber *PIDNum = [launchedProcessInfo objectForKey:@"NSApplicationProcessIdentifier"];
			pid_t pid = [PIDNum intValue];
			
			NSArray *arguments = [NSArray arrayWithObject:[NSString stringWithFormat:@"%d", pid]];
			NSTask *task = [[[NSTask alloc] init] autorelease];
			[task setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForAuxiliaryExecutable:@"GrowlSafariHelper"]];
			[task setArguments:arguments];
			[task launch];
		}
	}
}

@end
