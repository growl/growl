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

@protocol GrowlGNTPPacketDelegate;

@class GrowlGNTPOutgoingPacket;

@interface GrowlGNTPPacketParser : NSObject <GrowlGNTPPacketDelegate> {
	NSMutableDictionary *currentNetworkPackets;
}

+ (GrowlGNTPPacketParser *)sharedParser;
- (void)sendPacket:(GrowlGNTPOutgoingPacket *)packet toAddress:(NSData *)destAddress;
- (void)didAcceptNewSocket:(AsyncSocket *)socket;

@end
