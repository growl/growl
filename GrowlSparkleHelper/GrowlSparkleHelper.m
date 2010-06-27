//
//  GrowlSparkleHelper.m
//  Growl
//
//  Created by Rudy Richter on 9/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GrowlSparkleHelper.h"
#import "Sparkle/Sparkle.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPathUtilities.h"

@interface GrowlSparkleHelper(Private)
- (void) silentUpdateCheck:(NSNotification*)note;
@end

@implementation GrowlSparkleHelper

- (id) init {
	if( (self = [super init]) ) {
		shouldNotifyOfUpdate = NO;

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector(silentUpdateCheck:) 
																name:SPARKLE_HELPER_INTERVAL_INITIATED 
															  object:nil 
												  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector(checkForUpdates:) 
																name:SPARKLE_HELPER_USER_INITIATED
															  object:nil 
												  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector(die:) 
																name:SPARKLE_HELPER_DIE
															  object:nil 
												  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
		[self silentUpdateCheck:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) silentUpdateCheck:(NSNotification*)note {
#pragma unused(note)
	NSLog(@"%s", __FUNCTION__);
	shouldNotifyOfUpdate = YES;
	SUUpdater *updater = [SUUpdater updaterForBundle:[GrowlPathUtilities growlPrefPaneBundle]];
	[updater setDelegate:self];
	[updater checkForUpdateInformation];
}

- (void) checkForUpdates:(NSNotification*)note {
#pragma unused(note)
	NSLog(@"%s", __FUNCTION__);
	shouldNotifyOfUpdate = NO;
	SUUpdater *updater = [SUUpdater updaterForBundle:[GrowlPathUtilities growlPrefPaneBundle]];
	[updater setDelegate:self];
	[updater checkForUpdates:nil];
}

- (void) die:(NSNotification*)note {
#pragma unused(note)
	NSLog(@"%s", __FUNCTION__);
	[NSApp terminate:nil];
}

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {
#pragma unused(updater, update)
	NSLog(@"%s", __FUNCTION__);
	if(shouldNotifyOfUpdate) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:SPARKLE_HELPER_UPDATE_AVAILABLE object:GROWL_HELPERAPP_BUNDLE_IDENTIFIER userInfo:NULL deliverImmediately:YES];
		shouldNotifyOfUpdate = NO;
	}
}

- (void) updaterDidNotFindUpdate:(SUUpdater *)update {
#pragma unused(update)
	NSLog(@"%s", __FUNCTION__);
	[self die:nil];
}

- (void)sparkleDidFinish:(SUUpdater*)updater {
#pragma unused(updater)
	NSLog(@"%s", __FUNCTION__);
	[self die:nil];
}

// so far only called when it is not installing an update
- (void)updaterAlertDidFinishWithReturnCode:(NSUInteger)returnCode;
{
#pragma unused(returnCode)
	NSLog(@"%s", __FUNCTION__);
	[self die:nil];
}

@end
