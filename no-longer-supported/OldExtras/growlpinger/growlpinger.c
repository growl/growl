/*
 * Project:     growlpinger
 * File:        growlpinger.m
 * Author:      Andrew Wellington
 *
 * License:
 * Copyright (C) 2005 Andrew Wellington.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#include "GrowlDefines.h"

static const char usage[] =
"Usage: %s [-h] [-t timeout]\n"
"Options:\n"
"    -h		display this help\n"
"    -t		timeout before we give up\n"
"    -v		prints verbose information\n";

static int verbose = 0;
static int code = EXIT_SUCCESS;

static void sendPing(CFRunLoopTimerRef timer, void *info) {
#pragma unused(timer,info)
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 GROWL_PING,
										 NULL,
										 NULL,
										 true);
}

static void receivedPong(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
#pragma unused(center,observer,name,object,userInfo)
	if (verbose)
		fputs("Growl is alive: received pong\n", stdout);
	code = EXIT_SUCCESS;
	CFRunLoopStop(CFRunLoopGetCurrent());
}

static void receivedReady(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
#pragma unused(center,observer,name,object,userInfo)
	if (verbose)
		fputs("Growl is alive: received startup notification\n", stdout);
	code = EXIT_SUCCESS;
	CFRunLoopStop(CFRunLoopGetCurrent());
}

static void timeoutCallback(CFRunLoopTimerRef timer, void *info) {
#pragma unused(timer,info)
	if (verbose)
		fputs("Growl is dead: timed out\n", stdout);
	code = EXIT_FAILURE;
	CFRunLoopStop(CFRunLoopGetCurrent());
}

int main (int argc, char *argv[]) {
	CFTimeInterval timeout = 0.0;

	//options
	int ch;

	while ((ch = getopt(argc, argv, "ht:v")) != -1) {
		switch (ch) {
			case '?':
			case 'h':
			default:
				printf(usage, argv[0]);
				exit(EXIT_FAILURE);
				break;
			case 't':
				timeout = strtod(optarg, NULL);
				if (timeout <= 0) {
					printf("Timeout value invalid\n");
					printf(usage, argv[0]);
					exit(EXIT_FAILURE);
				}
				break;
			case 'v':
				verbose = 1;
				break;
		}
	}
	argc -= optind;
	argv += optind;

	CFNotificationCenterRef distCenter = CFNotificationCenterGetDistributedCenter();
	CFNotificationCenterAddObserver(distCenter,
									"GrowlPinger",
									receivedPong,
									GROWL_PONG,
									NULL,
									CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(distCenter,
									"GrowlPinger",
									receivedReady,
									GROWL_IS_READY,
									NULL,
									CFNotificationSuspensionBehaviorDeliverImmediately);

	CFRunLoopTimerRef timeoutTimer, pingTimer;
	CFRunLoopRef rl = CFRunLoopGetCurrent();
	if (timeout) {
		timeoutTimer = CFRunLoopTimerCreate(kCFAllocatorDefault,
											CFAbsoluteTimeGetCurrent()+timeout,
											0.0, 0, 0,
											timeoutCallback,
											NULL);
		CFRunLoopAddTimer(rl, timeoutTimer, kCFRunLoopCommonModes);
	} else {
		timeoutTimer = NULL;
	}

	pingTimer = CFRunLoopTimerCreate(kCFAllocatorDefault,
									 CFAbsoluteTimeGetCurrent(),
									 0.5, 0, 0,
									 sendPing,
									 NULL);
	CFRunLoopAddTimer(rl, pingTimer, kCFRunLoopCommonModes);

	CFRunLoopRun();

	if (timeoutTimer) {
		CFRunLoopTimerInvalidate(timeoutTimer);
		CFRelease(timeoutTimer);
	}
	if (pingTimer) {
		CFRunLoopTimerInvalidate(pingTimer);
		CFRelease(pingTimer);
	}

    return code;
}
