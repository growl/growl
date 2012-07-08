//
//  GNTPNotifyPacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/7/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPNotifyPacket.h"

/*
 * We dont need to override the state machine for a Notification Packet
 * We do need to override handling certain header keys
 * in both reading and converting the dictionary
 */

@interface GNTPNotifyPacket ()

@property (nonatomic, retain) NSString *callbackString;
@property (nonatomic, retain) NSString *callbackType;
@property (nonatomic, retain) NSString *callbackURL;

@end

@implementation GNTPNotifyPacket

@synthesize callbackString = _callbackString;
@synthesize callbackType = _callbackType;
@synthesize callbackURL = _callbackURL;

-(void)parseHeaderKey:(NSString *)headerKey value:(NSString *)stringValue {
	/* 
	 * Special cases in a notification: 
	 * click context
	 * click context type
	 * callback url
	 */
	if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCallbackContext] == NSOrderedSame){
		self.callbackString = stringValue;
	}else if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCallbackContextType] == NSOrderedSame){
		self.callbackType = stringValue;
	}else if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCallbackTarget] == NSOrderedSame){
		self.callbackURL = stringValue;
	}else
		[super parseHeaderKey:headerKey value:stringValue];
}

-(BOOL)validate {
	return [super validate];
}

-(NSDictionary*)convertedGrowlDict {
	NSMutableDictionary *convertedDict = [[[super convertedGrowlDict] mutableCopy] autorelease];
	if(self.callbackString){
		BOOL insertAsIs = YES;
		if(self.callbackType){
			if([self.callbackType caseInsensitiveCompare:@"PLIST"] == NSOrderedSame){
				//Convert to a plist and check
				id clickContext = [NSPropertyListSerialization propertyListWithData:[self.callbackType dataUsingEncoding:NSUTF8StringEncoding]
																								options:0
																								 format:NULL
																								  error:nil];
				if(clickContext){
					insertAsIs = NO;
					[convertedDict setObject:clickContext forKey:@"NotificationClickContext"];
				}
			}
			//We can easily add support here for other types
		}
		
		if(insertAsIs){
			//We dont really know the type, just the stuff the string back in
			[convertedDict setObject:self.callbackString forKey:@"NotificationClickContext"];
			[convertedDict setObject:self.callbackType forKey:GrowlGNTPNotificationCallbackContextType];
		}
	}
	if(self.callbackURL)
		[convertedDict setObject:self.callbackURL forKey:@"NotificationCallbackURLTarget"];
	
	return [[convertedDict copy] autorelease];
}

@end
