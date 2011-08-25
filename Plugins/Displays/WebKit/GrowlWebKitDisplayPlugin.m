//
//  GrowlWebKitDisplayPlugin.h
//  Growl
//
//  Created by JKP on 13/11/2005.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlNotificationDisplayBridge.h"
#import "GrowlWebKitDisplayPlugin.h"
#import "GrowlWebKitDefines.h"
#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitWindowController.h"
#import "GrowlDefines.h"

@implementation GrowlWebKitDisplayPlugin

- (id) initWithStyleBundle:(NSBundle *)styleBundle {
	if ((self = [super initWithBundle:styleBundle])) {
		NSDictionary *styleInfo = [styleBundle infoDictionary];
		style = [[styleInfo valueForKey:@"CFBundleName"] retain];
		prefDomain = [[NSString alloc] initWithFormat:@"%@.%@", GrowlWebKitPrefDomain, style];
		windowControllerClass = NSClassFromString(@"GrowlWebKitWindowController");

		BOOL validBundle = YES;
		/* NOTE verification here....does the plist contain all the relevant keys? does the
			bundle contain all the files we need? */

		if (!validBundle) {
			[self release];
			return nil;
		}
	}

	return self;
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

- (BOOL)requiresPositioning {
	return YES;
}

@end
