//
//  GrowlStatusController.m
//  Growl
//
//  Created by Ingmar Stein on 17.06.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlStatusController.h"
#import "GrowlApplicationController.h"
#import "GrowlApplicationBridge.h"

//Idle monitoring code from Adium X ( http://www.adiumx.com ), used with permission

//30 seconds of inactivity is considered idle
#define MACHINE_IDLE_THRESHOLD			30
//Poll every 30 seconds when the user is active
#define MACHINE_ACTIVE_POLL_INTERVAL	30
//Poll every second when the user is idle
#define MACHINE_IDLE_POLL_INTERVAL		1

//Private idle function
extern double CGSSecondsSinceLastInputEvent(unsigned long eventType);

static void idleTimerCallback(CFRunLoopTimerRef timer, void *info) {
	[(GrowlStatusController *)info idleCheckTimer:timer];
}

@implementation GrowlStatusController
- (id) init {
	if ((self = [super init])) {
		CFRunLoopTimerContext context = {0, self, NULL, NULL, NULL};
		idleTimer = CFRunLoopTimerCreate(kCFAllocatorDefault,
										 CFAbsoluteTimeGetCurrent() + MACHINE_ACTIVE_POLL_INTERVAL,
										 MACHINE_ACTIVE_POLL_INTERVAL,
										 0, 0,
										 idleTimerCallback,
										 &context);
	}
	return self;
}

- (void) dealloc {
	CFRunLoopTimerInvalidate(idleTimer);
	CFRelease(idleTimer);
	[super dealloc];
}

/*!
 * @brief Returns the current machine idle time
 *
 * Returns the current number of seconds the machine has been idle. The machine
 * is idle when there are no input events from the user (such as mouse movement
 * or keyboard input). In addition to this method, the status controller sends
 * out notifications when the machine becomes idle, stays idle, and returns to
 * an active state.
 */
- (double) currentIdleTime {
	double idleTime = CGSSecondsSinceLastInputEvent(-1);

	/* On MDD Powermacs, the above function will return a large value when the
	 * machine is active (perhaps a -1?).
	 * Here we check for that value and correctly return a 0 idle time.
	 */
	if (idleTime >= 18446744000.0) idleTime = 0.0;

	return idleTime;
}

/*!
 * @brief Timer that checks for machine idle
 *
 * This timer periodically checks the machine for inactivity. When the machine
 * has been inactive for at least MACHINE_IDLE_THRESHOLD seconds, a notification
 * is broadcast.
 *
 * When the machine is active, this timer is called infrequently. It's not
 * important to notice that the user went idle immediately, so we relax our CPU
 * usage while waiting for an idle state to begin.
 *
 * When the machine is idle, the timer is called frequently. It's important to
 * notice immediately when the user returns.
 */
- (void) idleCheckTimer:(CFRunLoopTimerRef)timer {
	double currentIdle = [self currentIdleTime];

	if (isIdle) {
		/* If the machine is less idle than the last time we recorded, it means
		 * that activity has occured and the user is no longer idle.
		 */
		if (currentIdle < lastSeenIdle) [self setIdle:NO];
	} else {
		//If machine inactivity is over the threshold, the user has gone idle.
		if (currentIdle > MACHINE_IDLE_THRESHOLD) [self setIdle:YES];
	}

	//Update our timer interval for either idle or active polling
	CFRunLoopTimerSetNextFireDate(timer, CFAbsoluteTimeGetCurrent() + (isIdle ? MACHINE_IDLE_POLL_INTERVAL : MACHINE_ACTIVE_POLL_INTERVAL));

	lastSeenIdle = currentIdle;
}

/*!
 * @brief Returns if the machine is currently considered idle or not.
 */
- (BOOL) isIdle {
	return isIdle;
}

/*!
 * @brief Sets the machine as idle or not
 */
- (void) setIdle:(BOOL)inIdle {
	isIdle = inIdle;

	if (isIdle) {
		NSString *description = [NSString stringWithFormat:NSLocalizedString(@"No activity for more than %d seconds.", /*comment*/ nil), MACHINE_IDLE_THRESHOLD];
		if ([[GrowlPreferencesController sharedController] stickyWhenAway])
			description = [description stringByAppendingString:NSLocalizedString(@" New notifications will be sticky.", /*comment*/ nil)];
		[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"User went idle", /*comment*/ nil)
									description:description
							   notificationName:@"User went idle"
									   iconData:[[GrowlApplicationController sharedController] applicationIconDataForGrowl]
									   priority:-1
									   isSticky:NO
								   clickContext:nil
									 identifier:nil];
	} else {
		[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"User returned", /*comment*/ nil)
									description:NSLocalizedString(@"User activity detected. New notifications will not be sticky by default.", /*comment*/ nil)
							   notificationName:@"User returned"
									   iconData:[[GrowlApplicationController sharedController] applicationIconDataForGrowl]
									   priority:-1
									   isSticky:NO
								   clickContext:nil
									 identifier:nil];
	}
}

@end
