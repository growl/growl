//
//  GrowlSmokeDisplay.m
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "GrowlSmokeDisplay.h"
#import "GrowlSmokeWindowController.h"
#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"

static NSString *SmokeAuthor      = @"Matthew Walton";
static NSString *SmokeName        = @"Smoke";
static NSString *SmokeDescription = @"Dark translucent notifications";
static NSString *SmokeVersion     = @"1.0";

static unsigned smokeDepth = 0U;

@implementation GrowlSmokeDisplay

- (id) init {
	if ( (self = [super init] ) ) {
		preferencePane = [[GrowlSmokePrefsController alloc] initWithBundle:[NSBundle bundleForClass:[GrowlSmokePrefsController class]]];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector( _smokeGone: ) 
													 name:@"SmokeGone"
												   object:nil];
	}
	return self;
}

- (void)loadPlugin {
}

- (NSString *)version {
	return SmokeVersion;
}

- (NSString *) author {
	return SmokeAuthor;
}

- (NSString *) name {
	return SmokeName;
}

- (NSString *) userDescription {
	return SmokeDescription;
}

- (void) unloadPlugin {
}

- (NSDictionary *) pluginInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		SmokeName,        @"Name",
		SmokeAuthor,      @"Author",
		SmokeVersion,     @"Version",
		SmokeDescription, @"Description",
		nil];
}

- (NSPreferencePane *) preferencePane {
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	//NSLog(@"Smoke: displayNotificationWithInfo");
	GrowlSmokeWindowController *controller = [GrowlSmokeWindowController notifyWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
		      text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			  icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
          priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]
			 depth:smokeDepth];
	
	[controller setTarget:self];
	[controller setAction:@selector(_smokeClicked:)];
	[controller setAppName:[noteDict objectForKey:GROWL_APP_NAME]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:[[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]];
	
	// update the depth for the next notification with the depth given by this new one
	// which will take into account the new notification's height
	smokeDepth = [controller depth] + GrowlSmokePadding;
	[controller startFadeIn];
}

- (void) _smokeGone:(NSNotification *)note {
	unsigned notifiedDepth = [[[note userInfo] objectForKey:@"Depth"] intValue];
	//NSLog(@"Received notification of departure with depth %u, my depth is %u\n", notifiedDepth, smokeDepth);
	if (smokeDepth > notifiedDepth) {
		smokeDepth = notifiedDepth;
	}
	//NSLog(@"My depth is now %u\n", smokeDepth);
}

- (void) _smokeClicked:(GrowlSmokeWindowController *)smoke
{
	id clickContext;
	
	if ( (clickContext = [smoke clickContext]) ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED	
															object:[smoke appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[smoke setClickContext:nil];
	}
}

@end
