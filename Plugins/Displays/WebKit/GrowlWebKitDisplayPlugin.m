//
//  GrowlWebKitDisplayPlugin.h
//  Growl
//
//  Created by JKP on 13/11/2005.
//	Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlNotificationDisplayBridge.h"
#import "GrowlWebKitDisplayPlugin.h"
#import "GrowlWebKitDefines.h"
#import "GrowlWebKitPrefsController.h"

@implementation GrowlWebKitDisplayPlugin

- (id) initWithStyleBundle:(NSBundle *)styleBundle; {
	if ((self = [super initWithBundle:styleBundle])) {
		NSDictionary *styleInfo = [styleBundle infoDictionary];
		style = [[styleInfo valueForKey:@"CFBundleName"] retain];
		prefDomain = [[NSString alloc] initWithFormat:@"%@.%@", GrowlWebKitPrefDomain, style];

		BOOL validBundle = YES;
		NSString *templateFile = [styleBundle pathForResource:@"template" ofType:@"html"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:templateFile])
			validBundle = NO;
		/* NOTE other verification here....does the plist contain all the relevant keys? does the
			bundle contain all the files we need? */

		if (!validBundle) {
			[self release];
			return nil;
		}
	}

	return self;
}

- (void) displayNotification:(GrowlApplicationNotification *)notification {
	Class wcc = NSClassFromString(@"GrowlWebKitWindowController");
	GrowlNotificationDisplayBridge *newBridge = [GrowlNotificationDisplayBridge bridgeWithDisplay:self
																					 notification:notification
																			windowControllerClass:wcc];
	if (queue) {
		if (bridge) {
			//a notification is already up; enqueue the new one
			[queue addObject:newBridge];
		} else {
			//nothing up at the moment; just display it
			[[newBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
			bridge = [newBridge retain];
		}
	} else {
		//no queue; just display it
		[[newBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
		[activeBridges addObject:newBridge];
	}
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane) {
		// load GrowlWebKitPrefsController dynamically so that GHA does not
		// have to link against it and all of its dependencies
		Class prefsController = NSClassFromString(@"GrowlWebKitPrefsController");
		preferencePane = [[prefsController alloc] initWithStyle:style];
	}
	return preferencePane;
}

@end
