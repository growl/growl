//
//  GrowlSMSDisplay.h
//  Growl Display Plugins
//
//  Copyright 2005 Diggory Laycock All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSPreferencePane;

@interface GrowlSMSDisplay: NSObject <GrowlDisplayPlugin>
{
	NSPreferencePane	*prefPane;
	
	
	NSMutableArray		*commandQueue;
	NSData				*responseData;
	NSXMLParser			*responseParser;	
	NSMutableString		*xmlHoldingStringValue;

	float				creditBalance;

	bool				waitingForResponse;
	bool				inBalanceResponseElement;
	bool				inMessageSendResponseElement;
	
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict;


- (NSData *)responseData;
- (void)setResponseData:(NSData *)newResponseData;

- (void) sendXMLCommand: (NSString*) commandString;

- (void) processQueue;

@end
