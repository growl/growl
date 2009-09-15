//
//  GrowlSafariLoader.m
//  GrowlSafari
//
//  Created by Peter Hosey on 2009-06-14.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "GrowlSafariLoader.h"

#import "InterestingBundleIdentifiers.h"

@interface GrowlSafariLoader ()

- (void) workspaceDidLaunchApplication:(NSNotification *)notification;

@end

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

- (BOOL) isOnSnowLeopardOrLater {
	OSStatus err;

	SInt32 majorOSVersion = 10, minorOSVersion = 0;
	err = Gestalt(gestaltSystemVersionMajor, &majorOSVersion);
	NSAssert2(err == noErr, @"Could not get operating-system major version number: %li/%s", (long)err, GetMacOSStatusCommentString(err));
	err = Gestalt(gestaltSystemVersionMinor, &minorOSVersion);
	NSAssert2(err == noErr, @"Could not get operating-system minor version number: %li/%s", (long)err, GetMacOSStatusCommentString(err));

	return (majorOSVersion == 10 && minorOSVersion >= 6) || (majorOSVersion > 10);
}

- (void) workspaceDidLaunchApplication:(NSNotification *)notification {
	NSDictionary *launchedProcessInfo = [notification userInfo];
	NSString *bundleID = [launchedProcessInfo objectForKey:@"NSApplicationBundleIdentifier"];
	if (bundleID && ([bundleID caseInsensitiveCompare:SAFARI_BUNDLE_ID] == NSOrderedSame) || ([bundleID caseInsensitiveCompare:WEBKIT_LAUNCHER_BUNDLE_ID] == NSOrderedSame)) {
		NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"GrowlSafari" ofType:@"bundle"];
		if (bundlePath) {
			NSNumber *PIDNum = [launchedProcessInfo objectForKey:@"NSApplicationProcessIdentifier"];
			pid_t pid = [PIDNum intValue];
			
			NSArray *arguments = [NSArray arrayWithObjects:
				@"-arch",
#if defined(__i386__)
				@"i386",
#elif defined(__x86_64__)
				//Safari did not exist in x86_64 before Snow Leopard, so, on older versions of Mac OS X, run the helper as i386.
				[self isOnSnowLeopardOrLater] ? @"x86_64" : @"i386",
#elif defined(__ppc__)
				@"ppc",
#else
#error Unsupported architecture
#endif
				[[NSBundle bundleForClass:[self class]] pathForAuxiliaryExecutable:@"GrowlSafariHelper"],
				[NSString stringWithFormat:@"%d", pid],
				nil];
			NSTask *task = [[[NSTask alloc] init] autorelease];
			[task setLaunchPath:@"/usr/bin/arch"];
			[task setArguments:arguments];
			[task launch];
		}
	}
}

@end
