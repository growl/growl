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

#include <tcl.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSImage.h>
#include <GrowlDefines.h>

static NSString *appName = nil; // Stores the registered name of the Tcl application.

/*
 * GrowlCmd
 * Handles the Tcl 'growl' command.
 */
int GrowlCmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	/* Return value; set success explicitly. */
	int e = TCL_ERROR;

	/* Action: 'register' or 'post'. */
	NSString *action;

	/* For register only. */
	NSArray *allNotifications = nil;

	/* For post only. */
	NSString *notificationType = nil;
	NSString *notificationTitle = nil;
	NSString *notificationDescription = nil;

	/* Notification icon. */
	NSString *iconFile;
	NSImage *notificationIcon = nil;

	/* Notification information. */
	NSDistributedNotificationCenter *distCenter = nil;
	NSString *notificationName = nil;
	NSDictionary *userInfo = nil;

	++objv, --objc;

	if (objc) {
		distCenter = [NSDistributedNotificationCenter defaultCenter];

		action = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
		++objv, --objc;

		if ([action isEqualToString:@"register"]) {
			if (appName == nil && objc == 3) {
				appName = [[NSString stringWithUTF8String:Tcl_GetString(*objv)] retain];
				++objv, --objc;

				allNotifications = [[NSString stringWithUTF8String:Tcl_GetString(*objv)] componentsSeparatedByString:@" "];
				++objv, --objc;

				iconFile = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
				notificationIcon = [[NSImage alloc] initWithContentsOfFile:iconFile];
				++objv, --objc;

				notificationName = GROWL_APP_REGISTRATION;
				userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					appName, GROWL_APP_NAME,
					[notificationIcon TIFFRepresentation], GROWL_APP_ICON,
					allNotifications, GROWL_NOTIFICATIONS_ALL,
					allNotifications, GROWL_NOTIFICATIONS_DEFAULT,
					nil];
				e = TCL_OK;
			}
		} else if ([action isEqualToString:@"post"]) {
			if (objc == 3 || objc == 4) {
				notificationType = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
				++objv, --objc;

				notificationTitle = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
				++objv, --objc;

				notificationDescription = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
				++objv, --objc;

				if (objc) {
					iconFile = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
					notificationIcon = [[NSImage alloc] initWithContentsOfFile:iconFile];
					++objv, --objc;
				}

				notificationName = GROWL_NOTIFICATION;
				userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					notificationType, GROWL_NOTIFICATION_NAME,
					appName, GROWL_APP_NAME,
					notificationTitle, GROWL_NOTIFICATION_TITLE,
					notificationDescription, GROWL_NOTIFICATION_DESCRIPTION,
					notificationIcon ? [notificationIcon TIFFRepresentation] : nil, GROWL_NOTIFICATION_ICON,
					nil];
				e = TCL_OK;
			}
		}

		if (userInfo != nil) {
			[distCenter postNotificationName:notificationName object:nil userInfo:userInfo];
		}

		if (notificationIcon != nil) {
			[notificationIcon release];
		}
	}

	[pool release];
	return e;
}

/* Growl_Init
 * Initialize the Tcl package, registering the 'growl' command.
 */
int Growl_Init(Tcl_Interp *interp)
{
	if (Tcl_InitStubs(interp, "8.4", 0) == NULL) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(interp, "growl", GrowlCmd, NULL, NULL);

	if (Tcl_PkgProvide(interp, "growl", "1.0") != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}
