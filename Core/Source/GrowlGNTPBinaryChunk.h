//
//  GrowlGNTPBinaryChunk.h
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlGNTPBinaryChunk : NSObject {
	NSData   *data;
	NSString *identifier;
}

+ (GrowlGNTPBinaryChunk *)chunkForData:(NSData *)inData withIdentifier:(NSString *)inIdentifier;
- (NSData *)GNTPRepresentation;

- (NSString *)identifier;
- (unsigned int)length;

@end
