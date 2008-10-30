//
//  GrowlRegisterGNTPPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlGNTPPacket.h"

typedef enum {
	GrowlRegisterStepRegistrationHeader = 0, /* The first registration part, with app name, icon, and notification count */
	GrowlRegisterStepNotification /* All other parts of the registration which define individual notifications */
} GrowlRegisterStep;

@interface GrowlRegisterGNTPPacket : GrowlGNTPPacket {
	GrowlRegisterStep currentStep;
	
	NSMutableDictionary *registrationDict;
	NSMutableArray		*notifications;
	NSMutableDictionary *currentNotification;
	
	NSString *applicationIconID;
	NSURL *applicationIconURL;
	
	unsigned int numberOfNotifications;
}

@end
