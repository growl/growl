//
//  GrowlGNTPPacketParser.h
//  Growl
//
//  Created by Evan Schoenberg on 9/5/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AsyncSocket.h"
#import "GrowlGNTPPacket.h"

typedef enum {
	GrowlHeaderError
} GrowlGNTPPacketErrorType;

@protocol GrowlGNTPPacketDelegate;

@interface GrowlGNTPPacketParser : NSObject <GrowlGNTPPacketDelegate> {
	NSMutableDictionary *currentNetworkPackets;
}

- (void)didAcceptNewSocket:(AsyncSocket *)socket;

@end
