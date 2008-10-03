//
//  GrowlNetworkPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 9/6/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlNetworkPacket : NSObject {
	AsyncSocket *socket;
	NSString	*host;

	id delegate;

	NSString *action;
	NSString *encryptionAlgorithm;

	NSMutableDictionary *customHeaders;
	NSMutableSet *pendingBinaryIdentifiers;
	
	NSString *currentBinaryIdentifier;
	unsigned long long currentBinaryLength;
	
	GrowlNetworkPacket *specificPacket;
}

+ (void)networkPacketForSocket:(AsyncSocket *)inSocket;

- (void)setDelegate:(id)inDelegate;

- (NSString *)action;
- (NSString *)encryptionAlgorithm;

@end
