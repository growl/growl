//
//  GrowlGNTPOutgoingPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GrowlGNTPHeaderItem.h"
#import "GrowlGNTPBinaryChunk.h"

@interface GrowlGNTPOutgoingPacket : NSObject {
	NSMutableArray *headerItems;
	NSMutableArray *binaryChunks;
	NSString *action;
}

+ (GrowlGNTPOutgoingPacket *)outgoingPacket;

- (void)setAction:(NSString *)action;

- (void)addHeaderItem:(GrowlGNTPHeaderItem *)inItem;
- (void)addHeaderItems:(NSArray *)inItems;

- (void)addBinaryChunk:(GrowlGNTPBinaryChunk *)inChunk;
- (void)addBinaryChunks:(NSArray *)inItems;

- (void)writeToSocket:(AsyncSocket *)socket;

- (BOOL)needsPersistentConnectionForCallback;

@end
