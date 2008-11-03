//
//  GrowlNotificationGNTPPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlGNTPPacket.h"

typedef enum {
	CallbackURLTargetUnknownMethod = 0,
	CallbackURLTargetPostMethod,
	CallbackURLTargetGetMethod
} CallbackURLTargetMethod;

@interface GrowlNotificationGNTPPacket : GrowlGNTPPacket {	
	NSMutableDictionary *notificationDict;

	NSString *iconID;
	NSURL    *iconURL;
	
	CallbackURLTargetMethod callbackTargetMethod;
}

+ (void)getHeaders:(NSArray **)outHeadersArray andBinaryChunks:(NSArray **)outBinaryChunks forNotificationDict:(NSDictionary *)dict;

@end
