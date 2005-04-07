//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import <GrowlDefinesInternal.h>
#ifdef CAN_HAVE_SCREENSHOT_MODE
//see below.
#import "GrowlController.h"
#endif

@implementation GrowlSpeechDisplay
- (void) dealloc {
	[prefPane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!prefPane) {
		prefPane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlSpeechPrefs class]]];
	}
	return prefPane;
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	NSString *voice = [NSSpeechSynthesizer defaultVoice];

	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);

	NSString *desc = [noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];

	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
	[syn startSpeakingString:desc];

#ifdef CAN_HAVE_SCREENSHOT_MODE
	/*it is not currently possible to use GrowlController here without linking
	 *	it into the plug-in, and it is not possible to link it into the plug-in
	 *	without also adding entirely too much of GHA (in fact, pretty much all
	 *	of it.)
	 *this section can be enabled upon the completion of #114, or possibly #116.
	 */

	if([[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]) {
		GrowlController *growlController = [GrowlController standardController];
		NSString *path = [[[growlController screenshotsDirectory] stringByAppendingPathComponent:[growlController nextScreenshotName]] stringByAppendingPathExtension:@"aiff"];
		NSURL *URL = [NSURL fileURLWithPath:path];
		[syn startSpeakingString:desc toURL:URL];
	}
#endif

	[syn autorelease];
}
@end
