//
//  GrowlSMSDisplay.h
//  Growl Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005–2011 The Growl Project All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GrowlPlugins/GrowlActionPlugin.h>

#define keychainServiceName "GrowlSMS"
#define keychainAccountName "SMSWebServicePassword"

#define GrowlSMSPrefDomain		@"com.Growl.SMS"
#define accountNameKey			@"SMS - Account Name"
#define accountAPIIDKey			@"SMS - Account API ID"
#define destinationNumberKey	@"SMS - Destination Number"

@class GrowlNotification;
@interface GrowlSMSDisplay: GrowlActionPlugin<GrowlDispatchNotificationProtocol, NSXMLParserDelegate> {
	NSMutableArray		*commandQueue;
	NSData				*responseData;
	NSXMLParser			*responseParser;
	NSMutableString		*xmlHoldingStringValue;

	CGFloat				creditBalance;

	BOOL				waitingForResponse;
	BOOL				inBalanceResponseElement;
	BOOL				inMessageSendResponseElement;
}

- (NSData *)responseData;
- (void)setResponseData:(NSData *)newResponseData;

- (void) sendXMLCommand: (NSString *)commandString;

- (void) processQueue;

@end
