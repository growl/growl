//
//  GrowlBrushedDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlBrushedDisplay.h"
#import "GrowlBrushedWindowController.h"
#import "GrowlBrushedPrefsController.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"

static NSString *BrushedAuthor      = @"Ingmar Stein";
static NSString *BrushedName        = @"Brushed";
static NSString *BrushedDescription = @"Aqua/Brushed metal notifications";
static NSString *BrushedVersion     = @"1.0";

static unsigned brushedDepth = 0U;

@implementation GrowlBrushedDisplay

- (id) init {
	NSLog(@"GrowlBrushedDisplay");
	if ( (self = [super init] ) ) {
		preferencePane = [[GrowlBrushedPrefsController alloc] initWithBundle:[NSBundle bundleForClass:[GrowlBrushedPrefsController class]]];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector( _brushedGone: ) 
													 name:@"BrushedGone"
												   object:nil];
	}
	return self;
}

- (void)loadPlugin {
}

- (NSString *)version {
	return BrushedVersion;
}

- (NSString *) author {
	return BrushedAuthor;
}

- (NSString *) name {
	return BrushedName;
}

- (NSString *) userDescription {
	return BrushedDescription;
}

- (void) unloadPlugin {
}

- (NSDictionary *) pluginInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		BrushedName,        @"Name",
		BrushedAuthor,      @"Author",
		BrushedVersion,     @"Version",
		BrushedDescription, @"Description",
		nil];
}

- (NSPreferencePane *) preferencePane {
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	//NSLog(@"Brushed: displayNotificationWithInfo");
	GrowlBrushedWindowController *controller
		= [GrowlBrushedWindowController notifyWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
												   text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
												   icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
											   priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
												 sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]
												  depth:brushedDepth];

	[controller setTarget:self];
	[controller setAction:@selector(_brushedClicked:)];
	[controller setAppName:[noteDict objectForKey:GROWL_APP_NAME]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:[[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]];

	// update the depth for the next notification with the depth given by this new one
	// which will take into account the new notification's height
	brushedDepth = [controller depth] + GrowlBrushedPadding;
	[controller startFadeIn];
}

- (void) _brushedGone:(NSNotification *)note {
	unsigned notifiedDepth = [[[note userInfo] objectForKey:@"Depth"] intValue];
	//NSLog(@"Received notification of departure with depth %u, my depth is %u\n", notifiedDepth, brushedDepth);
	if (brushedDepth > notifiedDepth) {
		brushedDepth = notifiedDepth;
	}
	//NSLog(@"My depth is now %u\n", brushedDepth);
}

- (void) _brushedClicked:(GrowlBrushedWindowController *)brushed
{
	id clickContext;

	if ( (clickContext = [brushed clickContext]) ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED	
															object:[brushed appName]
														  userInfo:clickContext];

		//Avoid duplicate click messages by immediately clearing the clickContext
		[brushed setClickContext:nil];
	}
}

@end
