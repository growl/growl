//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlBezelDisplay.h"
#import "GrowlBezelWindowController.h"
#import "GrowlBezelPrefs.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlBezelDisplay

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlBezelWindowController");
		self.prefDomain = GrowlBezelPrefDomain;
	}
	return self;
}

- (void) dealloc {
	[preferencePane    release];
	[super dealloc];
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBezelPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Bezel"]];
	return preferencePane;
}

//we implement requiresPositioning entirely because it was added as a requirement for doing 1.1 plugins, however
//we don't really care if positioning is required or not, because we have our own fixed positions
- (BOOL)requiresPositioning {
	return NO;
}

@end
