//
//  GrowlSafariLoader.m
//  GrowlSafari
//
//  Created by Ingmar Stein on 30.05.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlSafariLoader.h"

@implementation GrowlSafariLoader

+ (void) load {
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Safari"])
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(loadGrowlSafari:)
													 name:NSApplicationWillFinishLaunchingNotification
												   object:nil];
}

+ (void) loadGrowlSafari:(NSNotification *)notification {
#pragma unused(notification)
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	NSBundle *loaderBundle = [NSBundle bundleWithIdentifier:@"com.growl.GrowlSafariLoader"];
	NSString *growlSafariPath = [[loaderBundle builtInPlugInsPath] stringByAppendingPathComponent:@"GrowlSafari.bundle"];
	NSBundle *growlSafariBundle = [NSBundle bundleWithPath:growlSafariPath];
	if (!(growlSafariBundle && [growlSafariBundle load]))
		NSLog(@"GrowlSafariLoader: could not load %@", growlSafariPath);
}

@end
