//
//  GrowlIdleStatusController.c
//  Growl
//
//  Created by Ingmar Stein on 17.06.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#include "GrowlIdleStatusController.h"
#include "GrowlPreferencesController.h"
#include <ApplicationServices/ApplicationServices.h>

//Idle monitoring code from Adium X ( http://www.adiumx.com ), used with permission

//Poll every 30 seconds when the user is active
#define MACHINE_ACTIVE_POLL_INTERVAL	30
//Poll every second when the user is idle
#define MACHINE_IDLE_POLL_INTERVAL		1

static int					idleThreshold;
static Boolean				isIdle;
static CFTimeInterval		lastSeenIdle;
static CFRunLoopTimerRef	idleTimer;

/*!
 * @brief Returns the current machine idle time
 *
 * Returns the current number of seconds the machine has been idle. The machine
 * is idle when there are no input events from the user (such as mouse movement
 * or keyboard input). In addition to this method, the status controller sends
 * out notifications when the machine becomes idle, stays idle, and returns to
 * an active state.
 */
static CFTimeInterval currentIdleTime(void) {
	CFTimeInterval idleTime = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateHIDSystemState, kCGAnyInputEventType);

	/* On MDD Powermacs, the above function will return a large value when the
	 * machine is active (perhaps a -1?).
	 * Here we check for that value and correctly return a 0 idle time.
	 */
	if (idleTime >= 18446744000.0) idleTime = 0.0;

	return idleTime;
}

/*!
 * @brief Sets the machine as idle or not
 */
static void setIdle(Boolean inIdle) {
	isIdle = inIdle;

	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
										 CFSTR("GrowlIdleStatus"),
										 isIdle ? CFSTR("Idle") : CFSTR("Returned"),
										 /*userInfo*/ NULL,
										 /*deliverImmediately*/ false);
}

/*!
 * @brief Timer that checks for machine idle
 *
 * This timer periodically checks the machine for inactivity. When the machine
 * has been inactive for at least idleThreshold seconds, a notification
 * is broadcast.
 *
 * When the machine is active, this timer is called infrequently. It's not
 * important to notice that the user went idle immediately, so we relax our CPU
 * usage while waiting for an idle state to begin.
 *
 * When the machine is idle, the timer is called frequently. It's important to
 * notice immediately when the user returns.
 */
static void idleTimerCallback(CFRunLoopTimerRef timer, void *info) {
	CFTimeInterval currentIdle = currentIdleTime();
	if (isIdle) {
		/* If the machine is less idle than the last time we recorded, it means
		 * that activity has occured and the user is no longer idle.
		 */
		if (currentIdle < lastSeenIdle) setIdle(false);
	} else {
		//If machine inactivity is over the threshold, the user has gone idle.
		if (currentIdle > idleThreshold) setIdle(true);
	}

	//Update our timer interval for either idle or active polling
	CFRunLoopTimerSetNextFireDate(timer, CFAbsoluteTimeGetCurrent() + (isIdle ? MACHINE_IDLE_POLL_INTERVAL : MACHINE_ACTIVE_POLL_INTERVAL));

	lastSeenIdle = currentIdle;
}

void GrowlIdleStatusController_setThreshold(int idle){
    if(idle > 0)
        idleThreshold = idle;
    else
        idleThreshold = MACHINE_IDLE_THRESHOLD;
}

void GrowlIdleStatusController_init(void) {
	CFNumberRef value = GrowlPreferencesController_objectForKey(CFSTR("IdleThreshold"));
	if (value)
		CFNumberGetValue(value, kCFNumberIntType, &idleThreshold);
	else
		idleThreshold = MACHINE_IDLE_THRESHOLD;

	idleTimer = CFRunLoopTimerCreate(kCFAllocatorDefault,
									 CFAbsoluteTimeGetCurrent() + MACHINE_ACTIVE_POLL_INTERVAL,
									 MACHINE_ACTIVE_POLL_INTERVAL,
									 0, 0,
									 idleTimerCallback,
									 NULL);
	CFRunLoopAddTimer(CFRunLoopGetCurrent(), idleTimer, kCFRunLoopCommonModes);
}

void GrowlIdleStatusController_dealloc(void) {
	CFRunLoopTimerInvalidate(idleTimer);
	CFRelease(idleTimer);
}

/*!
 * @brief Returns if the machine is currently considered idle or not.
 */
Boolean GrowlIdleStatusController_isIdle(void) {
	return isIdle;
}
