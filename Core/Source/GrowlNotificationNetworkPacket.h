//
//  GrowlNotificationNetworkPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlNetworkPacket.h"

typedef enum {
	CallbackURLTargetUnknownMethod = 0,
	CallbackURLTargetPostMethod,
	CallbackURLTargetGetMethod
} CallbackURLTargetMethod;

@interface GrowlNotificationNetworkPacket : GrowlNetworkPacket {
	NSString *applicationName;
	NSString *notificationName;
	NSString *title;
	NSString *notificationIdentifier;
	NSString *text;
	BOOL sticky;

	NSString *iconID;
	NSURL    *iconURL;
	
	NSString *callbackContext;
	NSURL	 *callbackTarget;
	CallbackURLTargetMethod callbackTargetMethod;
}

@end
