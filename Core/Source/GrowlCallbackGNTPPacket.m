//
//  GrowlCallbackGNTPPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 11/3/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import "GrowlCallbackGNTPPacket.h"
#import "GrowlGNTPHeaderItem.h"
#import "GrowlDefines.h"

@implementation GrowlCallbackGNTPPacket
- (id)init
{
	if ((self = [super init])) {
		callbackDict = [[NSMutableDictionary alloc] init];
	} 
	return self;
}
- (void)dealloc
{
	[callbackDict release]; callbackDict = nil;
	
	[super dealloc];
}

- (NSString *)identifier
{
	return [callbackDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID];
}
- (void)setIdentifier:(NSString *)string
{
	[callbackDict setObject:string
						 forKey:GROWL_NOTIFICATION_INTERNAL_ID];

	/* Now update our identifier and our delegate GrowlGNTPPacket's identifier */
	[self setPacketID:string];
}

- (GrowlGNTPCallbackType)callbackType
{
	return callbackType;
}
- (void)setCallbackType:(GrowlGNTPCallbackType)inType
{
	callbackType = inType;
}

- (GrowlReadDirective)receivedHeaderItem:(GrowlGNTPHeaderItem *)headerItem
{
	NSString *name = [headerItem headerName];
	NSString *value = [headerItem headerValue];

	if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
		if ([self identifier]) {
			return GrowlReadDirective_PacketComplete;
		} else {
			[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
											   code:GrowlGNTPCallbackPacketError
										   userInfo:[NSDictionary dictionaryWithObject:@"Notification-ID header is required in a callback response"
																				forKey:NSLocalizedFailureReasonErrorKey]]];
			return GrowlReadDirective_Error;
		}
	}

	if ([name caseInsensitiveCompare:GrowlGNTPNotificationID] == NSOrderedSame) {
		[self setIdentifier:value];
	} else if ([name caseInsensitiveCompare:GrowlGNTPNotificationCallbackResult] == NSOrderedSame) {
		if ([value caseInsensitiveCompare:@"CLICKED"] == NSOrderedSame || [value caseInsensitiveCompare:@"CLICK"] == NSOrderedSame) {
			[self setCallbackType:GrowlGNTPCallback_Clicked];
		} else {
			[self setCallbackType:GrowlGNTPCallback_Closed];			
		}
	} else if ([name caseInsensitiveCompare:GrowlGNTPNotificationCallbackContext] == NSOrderedSame) {
      id clickContext = nil;
      NSString *type = [callbackDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
      if(type && [type caseInsensitiveCompare:@"PList"]){
         clickContext = [NSPropertyListSerialization propertyListWithData:[value dataUsingEncoding:NSUTF8StringEncoding]
                                                                  options:0
                                                                   format:NULL
                                                                    error:nil];
      }else
         clickContext = value;
      
		[callbackDict setObject:clickContext
							 forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];

	} else if ([name caseInsensitiveCompare:GrowlGNTPNotificationCallbackContextType] == NSOrderedSame) {
		[callbackDict setObject:value
							 forKey:GROWL_NOTIFICATION_CLICK_CONTENT_TYPE];
      NSString *context = [callbackDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
      if(context && [context isKindOfClass:[NSString class]] && [value caseInsensitiveCompare:@"PList"] == NSOrderedSame)
      {
         id newContext = [NSPropertyListSerialization propertyListWithData:[context dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:0
                                                                    format:NULL
                                                                     error:nil];
         
         [callbackDict setObject:newContext
                          forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
      }
	} else if ([name caseInsensitiveCompare:GrowlGNTPApplicationNameHeader] == NSOrderedSame) {
		[callbackDict setValue:value forKey:GROWL_APP_NAME];
	} else if ([name caseInsensitiveCompare:GrowlGNTPApplicationPIDHeader] == NSOrderedSame) {
		[callbackDict setObject:value
						 forKey:GROWL_APP_PID];
	} else if ([name rangeOfString:GrowlGNTPExtensionPrefix options:(NSLiteralSearch | NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound) {
		[self addCustomHeader:headerItem];
	}

	return GrowlReadDirective_Continue;
}

/*!
 * @brief Return a Growl notification dictionary good enough to respond to a callbacl
 */
- (NSDictionary *)growlDictionary
{
	NSMutableDictionary *growlDictionary = [[[super growlDictionary] mutableCopy] autorelease];
	
	[growlDictionary addEntriesFromDictionary:callbackDict];
	
	return growlDictionary;
}

/*!
 * @brief Headers to be returned via the -OK success result
 */
- (NSArray *)headersForResult
{
	NSMutableArray *headersForResult = [[[super headersForResult] mutableCopy] autorelease];
	if (!headersForResult) headersForResult = [NSMutableArray array];
	[headersForResult addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-ID" value:[self identifier]]];
	[headersForResult addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Notification-Callback-Result"
																		 value:([self callbackType] == GrowlGNTPCallback_Clicked ?
																				@"CLICKED" :
																				@"CLOSED")]];

	return headersForResult;
}

@end
