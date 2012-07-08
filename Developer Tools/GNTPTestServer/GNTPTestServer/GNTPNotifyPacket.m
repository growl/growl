//
//  GNTPNotifyPacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/7/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPNotifyPacket.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"

/*
 * We dont need to override the state machine for a Notification Packet
 * We do need to override handling certain header keys
 * in both reading and converting the dictionary
 */

@interface GNTPNotifyPacket ()

@property (nonatomic, retain) NSString *callbackString;
@property (nonatomic, retain) NSString *callbackType;

@end

@implementation GNTPNotifyPacket

@synthesize callbackString = _callbackString;
@synthesize callbackType = _callbackType;

-(void)parseHeaderKey:(NSString *)headerKey value:(NSString *)stringValue {
	/* 
	 * Special cases in a notification: 
	 * click context
	 * click context type
	 */
	if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCallbackContext] == NSOrderedSame){
		self.callbackString = stringValue;
	}else if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCallbackContextType] == NSOrderedSame){
		self.callbackType = stringValue;
	}else
		[super parseHeaderKey:headerKey value:stringValue];
}

-(BOOL)validate {
	return [super validate];
}

-(NSMutableDictionary*)convertedGrowlDict {
	NSMutableDictionary *convertedDict = [[super convertedGrowlDict] retain];
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
					[convertedDict setObject:clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
				}
			}
			//We can easily add support here for other types
		}
		
		//We dont really know the type, just the stuff the string back in
		if(insertAsIs){
			[convertedDict setObject:self.callbackString forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
		}
		[convertedDict setObject:self.callbackType forKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
	}
	
	return [convertedDict autorelease];
}

@end
