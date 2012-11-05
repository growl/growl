//
//  GrowlWebSocketProxy.h
//  Growl
//
//  Created by Daniel Siemer on 11/4/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCDAsyncSocket;

@interface GrowlWebSocketProxy : NSObject

@property (nonatomic, retain) GCDAsyncSocket *socket;
@property (nonatomic, assign) id delegate;

- (id)initWithSocket:(GCDAsyncSocket*)socket;

- (void)disconnect;

- (NSString *)connectedHost;
- (NSData *)connectedAddress;

- (id)userData;
- (void)setUserData:(id)userInfo;

- (void)readDataToData:(NSData *)data
				withLength:(NSUInteger)length
			  withTimeout:(NSTimeInterval)timeout
						 tag:(long)tag;
- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;

@end
