/*
 * growl.m
 *
 * Copyright (c) 2004, Toby Peterson <toby@opendarwin.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Growl project nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "GrowlDefines.h"

#include <tcl.h>

NSString *appName;

int GrowlCmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// "register" or "post"
	NSString *action;

	// for "register"
	NSArray *allNotifications;

	// for "post"
	NSString *notificationType, *notificationTitle, *notificationDescription;

	// info to actually send teh message
	NSDistributedNotificationCenter *distCenter;
	NSString *notificationName;
	NSDictionary *userInfo;

	++objv, --objc;

	if (!objc) {
		return TCL_ERROR;
	}

	distCenter = [NSDistributedNotificationCenter defaultCenter];

	action = [NSString stringWithCString:Tcl_GetString(*objv)];
	++objv, --objc;

	if ([action isEqualToString:@"register"]) {
		if (appName != nil) {
			return TCL_ERROR;
		}

		if (objc != 2) {
			return TCL_ERROR;
		}

		appName = [[NSString stringWithCString:Tcl_GetString(*objv)] retain];
		++objv, --objc;

		allNotifications = [[NSString stringWithCString:Tcl_GetString(*objv)] componentsSeparatedByString:@" "];
		++objv, --objc;

		notificationName = GROWL_APP_REGISTRATION;
		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			appName, GROWL_APP_NAME,
			allNotifications, GROWL_NOTIFICATIONS_ALL,
			allNotifications, GROWL_NOTIFICATIONS_DEFAULT,
			nil];
	} else if ([action isEqualToString:@"post"]) {
		if (objc != 3) {
			return TCL_ERROR;
		}

		notificationType = [NSString stringWithCString:Tcl_GetString(*objv)];
		++objv, --objc;

		notificationTitle = [NSString stringWithCString:Tcl_GetString(*objv)];
		++objv, --objc;

		notificationDescription = [NSString stringWithCString:Tcl_GetString(*objv)];
		++objv, --objc;

		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			notificationType, GROWL_NOTIFICATION_NAME,
			appName, GROWL_APP_NAME,
			notificationTitle, GROWL_NOTIFICATION_TITLE,
			notificationDescription, GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		
		notificationName = GROWL_NOTIFICATION;
	} else {
		return TCL_ERROR;
	}

	[distCenter postNotificationName:notificationName object:nil userInfo:userInfo];

	[pool release];
	return TCL_OK;
}

int Growl_Init(Tcl_Interp *interp)
{
	if(Tcl_InitStubs(interp, "8.4", 0) == NULL) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(interp, "growl", GrowlCmd, NULL, NULL);

	if(Tcl_PkgProvide(interp, "growl", "1.0") != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}
