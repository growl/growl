//
//  GrowlGNTPBinaryChunk.h
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GrowlTCPPathway.h"

@interface GrowlGNTPBinaryChunk : NSObject <GNTPOutgoingItem> {
	NSData   *_data;
	NSString *_identifier;
}

+ (GrowlGNTPBinaryChunk *)chunkForData:(NSData *)inData withIdentifier:(NSString *)inIdentifier;
+ (NSString *)identifierForBinaryData:(NSData *)data;
- (NSData *)GNTPRepresentation;

- (NSString *)identifier;
- (NSUInteger)length;

@property (retain) NSData *data;
@property (retain) NSString *identifier;
@end
