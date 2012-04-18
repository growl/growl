//
//  GrowlNotificationGNTPPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
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

+ (void)getHeaders:(NSArray **)outHeadersArray binaryChunks:(NSArray **)outBinaryChunks notificationID:(NSString **)outNotificationID forNotificationDict:(NSDictionary *)dict;
+ (GrowlGNTPCallbackBehavior)callbackResultSendBehaviorForHeaders:(NSArray *)headers;

@end
