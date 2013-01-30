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
	if([dictionary valueForKey:GROWL_NOTIFICATION_INTERNAL_ID])
		[response appendFormat:@"Notification-ID: %@\r\n", [dictionary valueForKey:GROWL_NOTIFICATION_INTERNAL_ID]];
	[response appendFormat:@"Notification-Callback-Result: %@\r\n", clicked ? @"CLICKED" : @"TIMEOUT"];
	
	static ISO8601DateFormatter *_dateFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dateFormatter = [[ISO8601DateFormatter alloc] init];
	});
	[response appendFormat:@"Notification-Callback-Timestamp: %@\r\n", [_dateFormatter stringFromDate:[NSDate date]]];
	
	//Append where this came from
	[response appendString:[GNTPPacket originString]];
	
	NSString *contextType = [dictionary valueForKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
	id context = [dictionary valueForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	NSString *contextString = nil;
	if([context isKindOfClass:[NSString class]]){
		//Go ahead and set it regardless
		contextString = context;
	}else{
/*		if([contextType caseInsensitiveCompare:@"PLIST"] == NSOrderedSame){
			if([NSPropertyListSerialization propertyList:context isValidForFormat:kCFPropertyListXMLFormat_v1_0]){
				NSData *propertyListData = [NSPropertyListSerialization dataWithPropertyList:context
																											 format:kCFPropertyListXMLFormat_v1_0
																											options:0
																											  error:NULL];
				if(propertyListData){
					contextString = [[[NSString alloc] initWithData:propertyListData encoding:NSUTF8StringEncoding] autorelease];
				}
			}
			if(!contextString){
				NSLog(@"Error generating context string from supposed plist: %@\r\n", context);
			}
		}*/
	}
	if(contextString){
		//If we can't get a context formed into a string, this isn't worth sending
		[response appendFormat:@"Notification-Callback-Context-Type: %@\r\n", contextType];
		[response appendFormat:@"Notification-Callback-Context: %@\r\n", contextString];
		[response appendString:@"\r\n\r\n"];
		//NSLog(@"%@", response);
		feedbackData = [NSData dataWithBytes:[response UTF8String] length:[response length]];
	}
	return feedbackData;
}

+(id)convertedObjectFromGrowlObject:(id)obj forGNTPKey:(NSString *)gntpKey {
	id converted = [super convertedObjectFromGrowlObject:obj forGNTPKey:gntpKey];
	if(converted)
		return converted;
	
	if([gntpKey caseInsensitiveCompare:GrowlGNTPNotificationCallbackTarget] == NSOrderedSame){
		if([obj isKindOfClass:[NSURL class]])
			converted = [obj absoluteString];
	}else if([gntpKey caseInsensitiveCompare:GrowlGNTPNotificationSticky] == NSOrderedSame){
		if([obj boolValue])
		{
			converted = @"True";
		}else {
			converted = @"False";
		}
   }else if ([gntpKey caseInsensitiveCompare:GrowlGNTPXNotificationAlreadyShown] == NSOrderedSame) {
		if([obj boolValue])
		{
			converted = @"True";
		}else {
			converted = @"False";
		}
	}else if([gntpKey caseInsensitiveCompare:GrowlGNTPNotificationPriority] == NSOrderedSame){
		converted = [NSString stringWithFormat:@"%ld", [obj integerValue]];
	} 
	return converted;
}

+(NSMutableDictionary*)gntpDictFromGrowlDict:(NSDictionary *)dict {
	NSMutableDictionary *converted = [super gntpDictFromGrowlDict:dict];
	
	//We wont bother checking the context type we stored unless the context is not stored as a string
	NSString *contextType = nil;
	id context = [dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	NSString *contextString = nil;
	if(context){
		if([context isKindOfClass:[NSString class]]){
			contextString = context;
			if([dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE])
				contextType = [dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
			else
				contextType = @"String";
		}else if([NSPropertyListSerialization propertyList:context isValidForFormat:NSPropertyListXMLFormat_v1_0]){
			NSError *error = nil;
			NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:context
                                                                        format:NSPropertyListXMLFormat_v1_0
                                                                       options:0
                                                                         error:&error];
			if(plistData){
				contextString = [[[NSString alloc] initWithData:plistData encoding:NSUTF8StringEncoding] autorelease];
			}else{
				NSLog(@"There was an error: %@ generating serialized property list from context: %@", error, context);
			}
			contextType = @"Plist";
		}else if([context isKindOfClass:[NSURL class]]){
			contextString = [context absoluteString];
			contextType = @"URL";
		}
		if(contextString && contextType){
			[converted setObject:contextType forKey:GrowlGNTPNotificationCallbackContextType];
			[converted setObject:contextString forKey:GrowlGNTPNotificationCallbackContext];
		}else{
			NSLog(@"Context %@ was not converted to a string, and was not sent, check that it is an NSString, NSURL or is seriazable to XML PList with NSPropertyListSerialization", context);
		}
	}
	
	return converted;
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
		result = (result < 15.0) ? 15.0 : result;
	return result;
}

-(NSMutableDictionary*)convertedGrowlDict {
	NSMutableDictionary *convertedDict = [[super convertedGrowlDict] retain];
	if(self.callbackString){
		id convertedContext = nil;
		if(self.callbackType){
			//We can easily add support here for other types
/*			if([self.callbackType caseInsensitiveCompare:@"PLIST"] == NSOrderedSame){
				//Convert to a plist and check
				convertedContext = [NSPropertyListSerialization propertyListWithData:[self.callbackString dataUsingEncoding:NSUTF8StringEncoding]
																								 options:0
																								  format:NULL
																									error:nil];
			}else if([self.callbackType caseInsensitiveCompare:@"URL"] == NSOrderedSame){
				convertedContext = [NSURL URLWithString:self.callbackString];
			}*/
		}
		
		//We dont really know the type, or couldn't convert it, just the stuff the string back in
		if(!convertedContext){
			[convertedDict setObject:self.callbackString forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
		}else{
			[convertedDict setObject:convertedContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
		}
      if(self.callbackType)
         [convertedDict setObject:self.callbackType forKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
      else
         [convertedDict setObject:@"String" forKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
	}
   	
	return [convertedDict autorelease];
}

@end
