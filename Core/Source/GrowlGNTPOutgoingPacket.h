//
//  GrowlGNTPOutgoingPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GrowlGNTPHeaderItem.h"

@interface GrowlGNTPOutgoingPacket : NSObject {
	NSMutableArray *headerItems;
	NSMutableArray *binaryChunks;
	NSString *action;
}

+ (GrowlGNTPOutgoingPacket *)outgoingPacket;

+ (NSString *)identifierForBinaryData:(NSData *)data;
- (void)setAction:(NSString *)action;
- (void)addHeaderItem:(GrowlGNTPHeaderItem *)inItem;
- (void)addHeaderItems:(NSArray *)inItems;
- (void)addBinaryData:(NSData *)inData withIdentifier:(NSString *)inIdentifier;

- (void)writeToSocket:(AsyncSocket *)socket;

@end
