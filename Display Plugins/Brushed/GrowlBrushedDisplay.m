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

static NSString *BrushedAuthor      = @"Ingmar Stein";
static NSString *BrushedName        = @"Brushed";
static NSString *BrushedDescription = @"Brushed metal notifications";
static NSString *BrushedVersion     = @"1.0";

static unsigned BrushedDepth = 0;

@implementation GrowlBrushedDisplay

- (id) init {
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
	GrowlBrushedWindowController *controller = [GrowlBrushedWindowController notifyWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
		      text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			  icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
          priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]
			 depth:BrushedDepth];
	// update the depth for the next notification with the depth given by this new one
	// which will take into account the new notification's height
	BrushedDepth = [controller depth] + GrowlBrushedPadding;
	[controller startFadeIn];
}

- (void) _brushedGone:(NSNotification *)note {
	unsigned notifiedDepth = [[[note userInfo] objectForKey:@"Depth"] intValue];
	//NSLog(@"Received notification of departure with depth %u, my depth is %u\n", notifiedDepth, BrushedDepth);
	if (BrushedDepth > notifiedDepth) {
		BrushedDepth = notifiedDepth;
	}
	//NSLog(@"My depth is now %u\n", BrushedDepth);
}

@end
