//
//  GrowlMusicVideoDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlMusicVideoDisplay.h"
#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoPrefs.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlMusicVideoDisplay

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlMusicVideoWindowController");
		self.prefDomain = GrowlMusicVideoPrefDomain;
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.MusicVideo"]];
	return preferencePane;
}

- (BOOL) requiresPositioning {
	return NO;
}

@end
