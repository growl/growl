//
//  GrowlNotifyScriptCommand.m
//  Growl
//
//  Created by Patrick Linskey on Tue Aug 10 2004.
//  Copyright (c) 2004 Patrick Linskey. All rights reserved.
//

/*
 *  To do:
 *		- change the name of GrowlHelperApp to just Growl, so you can 'tell application "Growl"'
 */

/*
 *  Some sample scripts:
 *	tell application "GrowlHelperApp"
 *		notify with title "test" description "test description" icon of application "Mail.app"
 *	end tell
 *
 *	tell application "GrowlHelperApp"
 *		notify with title "test" description "test description" icon of file "file:///Applications" sticky yes
 *	end tell
 */

#import "GrowlNotifyScriptCommand.h"
#import "GrowlApplicationBridge.h"
#import "GrowlController.h"
#import "NSGrowlAdditions.h"

#define KEY_TITLE				@"title"
#define KEY_DESC				@"description"
#define KEY_STICKY				@"sticky"
#define KEY_IMAGE_URL			@"imageFromURL"
#define KEY_ICON_APP_NAME		@"iconOfApplication"
#define KEY_ICON_FILE			@"iconOfFile"
#define KEY_IMAGE				@"image"
#define KEY_PICTURE				@"pictImage"
#define KEY_APP_NAME			@"appName"
#define KEY_NOTIFICATION_NAME	@"notificationName"

#define ERROR_EXCEPTION						1
#define ERROR_NOT_FILE_URL					2
#define ERROR_ICON_OF_FILE_PATH_INVALID		3

static const NSSize iconSize = {128.f, 128.f};

@implementation GrowlNotifyScriptCommand

-(id)performDefaultImplementation
{
	NSDictionary* args = [self evaluatedArguments];

	// should validate params better!
	NSString *title = [args valueForKey:KEY_TITLE];
	NSString *desc = [args valueForKey:KEY_DESC];
	NSNumber *sticky = [args valueForKey:KEY_STICKY];
	NSString *imageUrl = [args valueForKey:KEY_IMAGE_URL];
	NSString *iconOfFile = [args valueForKey:KEY_ICON_FILE];
	NSString *iconOfApplication = [args valueForKey:KEY_ICON_APP_NAME];
	NSData *imageData = [args valueForKey:KEY_IMAGE];
	NSData *pictureData = [args valueForKey:KEY_PICTURE];
	NSString *appName = [args valueForKey:KEY_APP_NAME];
	NSString *notifName = [args valueForKey:KEY_NOTIFICATION_NAME];

	NSMutableDictionary* noteDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		appName, GROWL_APP_NAME,
		notifName, GROWL_NOTIFICATION_NAME,
		title, GROWL_NOTIFICATION_TITLE,
		desc, GROWL_NOTIFICATION_DESCRIPTION,
		sticky, GROWL_NOTIFICATION_STICKY,
		nil];

	NS_DURING
		NSImage* icon = nil;
		if (imageUrl != nil) {
			NSURL *url = [NSURL URLWithString:imageUrl];
			if (!url || ![url isFileURL] || [[url host] length]) {
				[self setError:ERROR_NOT_FILE_URL];
				NS_VALUERETURN(nil,id);
			}
			icon = [[[NSImage alloc] initWithContentsOfURL:url] autorelease];
		} else if (iconOfFile != nil) {
			NSURL *url = [NSURL URLWithString:iconOfFile];
			if (!url || ![url isFileURL] || [[url host] length]) {
				[self setError:ERROR_ICON_OF_FILE_PATH_INVALID];
				NS_VALUERETURN(nil,id);
			}
			icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
		} else if (iconOfApplication != nil) {
			icon = [[NSWorkspace sharedWorkspace] iconForApplication:iconOfApplication];
		} else if (imageData != nil){
			icon = [[[NSImage alloc] initWithData:imageData] autorelease];
		} else if (pictureData != nil){
			icon = [[[NSImage alloc] initWithData:pictureData] autorelease];
			[icon setScalesWhenResized: YES];
		}
		
		if (icon != nil) {
			[icon setSize:iconSize];
			[noteDict setObject:[icon TIFFRepresentation] forKey:GROWL_NOTIFICATION_ICON];
		}

		[[GrowlController singleton] dispatchNotificationWithDictionary:noteDict];
	NS_HANDLER
		NSLog (@"error processing AppleScript request: %@", localException);
		[self setError:ERROR_EXCEPTION failure:localException];
	NS_ENDHANDLER

	return nil;
}

- (void)setError:(int)errorCode
{
	[self setError:errorCode failure:nil];
}

- (void)setError:(int)errorCode failure:(id)failure
{
	[self setScriptErrorNumber:errorCode];
	NSString* str;
	switch (errorCode) {
		case ERROR_EXCEPTION:
			str = [NSString stringWithFormat:@"Exception raised while processing: %@", failure];
			break;
		case ERROR_NOT_FILE_URL:
			str = @"'image of file' parameter value must start with 'file:///'";
			break;
		case ERROR_ICON_OF_FILE_PATH_INVALID:
			str = @"'image from URL' parameter value must start with 'file:///'";
			break;
		default:
			str = nil;
	}
	if (str != nil) {
		[self setScriptErrorString:str];
	}
}

@end
