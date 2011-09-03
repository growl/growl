//
//  GrowlGNTPCommunicationAttempt.h
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlCommunicationAttempt.h"

@class GrowlGNTPOutgoingPacket;
@class GCDAsyncSocket;

@interface GrowlGNTPCommunicationAttempt : GrowlCommunicationAttempt
{
	GrowlGNTPOutgoingPacket *packet;
	GCDAsyncSocket *socket;
	NSString *responseParseErrorString, *bogusResponse;
	NSString *callbackType;
	NSMutableArray *callbackHeaderItems;
	BOOL attemptSucceeded;
   int responseReadType;
}

//Lazily constructs the packet for self.dictionary.
- (GrowlGNTPOutgoingPacket *) packet;

//Returns NO. Subclasses may overrido to conditionally or unconditionally return YES.
- (BOOL) expectsCallback;

- (void)parseError;
- (void)parseFeedback;

@end
