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

#import "ISO8601DateFormatter.h"

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

+(NSData*)feedbackData:(BOOL)clicked forGrowlDictionary:(NSDictionary*)dictionary {
	NSData *feedbackData = nil;
	
	//Build a feedback response
	//This should support encrypting replies at some point
	NSMutableString *response = [NSMutableString stringWithString:@"GNTP/1.0 -CALLBACK NONE\r\n"];
	[response appendFormat:@"Application-Name: %@\r\n", [dictionary valueForKey:GROWL_APP_NAME]];
	if([dictionary valueForKey:GROWL_NOTIFICATION_IDENTIFIER])
		[response appendFormat:@"Notification-ID: %@\r\n", [dictionary valueForKey:GROWL_NOTIFICATION_IDENTIFIER]];
	[response appendFormat:@"Notification-Callback-Result: %@\r\n", clicked ? @"CLICKED" : @"TIMEOUT"];
	
	static ISO8601DateFormatter *_dateFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dateFormatter = [[ISO8601DateFormatter alloc] init];
	});
	[response appendFormat:@"Notification-Callback-Timestamp: %@\r\n", [_dateFormatter stringFromDate:[NSDate date]]];
	
	NSString *contextType = [dictionary valueForKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
	id context = [dictionary valueForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	NSString *contextString = nil;
	if([context isKindOfClass:[NSString class]]){
		//Go ahead and set it regardless
		contextString = context;
	}else{
		if([contextType caseInsensitiveCompare:@"PLIST"]){
			if([NSPropertyListSerialization propertyList:context isValidForFormat:kCFPropertyListXMLFormat_v1_0]){
				NSData *propertyListData = [NSPropertyListSerialization dataWithPropertyList:context
																											 format:kCFPropertyListXMLFormat_v1_0
																											options:0
																											  error:NULL];
				if(propertyListData){
					contextString = [NSString stringWithUTF8String:[propertyListData bytes]];
				}
			}
			if(!contextString){
				NSLog(@"Error generating context string from supposed plist: %@\r\n", context);
			}
		}
	}
	if(contextString){
		//If we can't get a context formed into a string, this isn't worth sending
		[response appendFormat:@"Notification-Callback-Context-Type: %@\r\n", contextType];
		[response appendFormat:@"Notification-Callback-Context: %@\r\n", contextString];
		[response appendString:@"\r\n"];
		feedbackData = [NSData dataWithBytes:[response UTF8String] length:[response length]];
	}
	return feedbackData;
}

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

-(NSTimeInterval)requestedTimeAlive {
	//determine what type of feedback we are expecting to send
	NSTimeInterval result = [super requestedTimeAlive];
	//Crude
	if(self.callbackString && ![self.gntpDictionary valueForKey:GrowlGNTPNotificationCallbackTarget])
		result = (result < 10.0) ? 10.0 : result;
	return result;
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
		
		//We dont really know the type, or couldn't convert it, just the stuff the string back in
		if(insertAsIs){
			[convertedDict setObject:self.callbackString forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
		}
		[convertedDict setObject:self.callbackType forKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
	}
	
	return [convertedDict autorelease];
}

@end
