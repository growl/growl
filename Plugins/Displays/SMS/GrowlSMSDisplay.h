//
//  GrowlSMSDisplay.h
//  Growl Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005-2006 The Growl Project All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlSMSDisplay: GrowlDisplayPlugin<NSXMLParserDelegate> {
	NSMutableArray		*commandQueue;
	NSData				*responseData;
	NSXMLParser			*responseParser;
	NSMutableString		*xmlHoldingStringValue;

	CGFloat				creditBalance;

	BOOL				waitingForResponse;
	BOOL				inBalanceResponseElement;
	BOOL				inMessageSendResponseElement;
}

- (void) displayNotification:(GrowlNotification *)notification;

- (NSData *)responseData;
- (void)setResponseData:(NSData *)newResponseData;

- (void) sendXMLCommand: (NSString *)commandString;

- (void) processQueue;

@end
