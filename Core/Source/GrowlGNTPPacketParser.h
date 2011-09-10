//
//  GrowlGNTPPacketParser.h
//  Growl
//
//  Created by Evan Schoenberg on 9/5/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"
#import "GrowlGNTPPacket.h"

@protocol GrowlGNTPPacketDelegate;

@class GrowlGNTPOutgoingPacket;

typedef enum {
  GrowlGNTPPacketSocketUserData_None = 0,
	GrowlGNTPPacketSocketUserData_WasInitiatedLocally
} GrowlGNTPPacketSocketUserData;

@interface GrowlGNTPPacketParser : NSObject <GrowlGNTPPacketDelegate> {
	NSMutableDictionary *currentNetworkPackets;
}

+ (GrowlGNTPPacketParser *)sharedParser;
- (void)sendPacket:(GrowlGNTPOutgoingPacket *)packet toAddress:(NSData *)destAddress;
- (void)didAcceptNewSocket:(GCDAsyncSocket *)socket;

- (void)growlNotificationDict:(NSDictionary *)growlNotificationDict didCloseViaNotificationClick:(BOOL)viaClick;

@end
