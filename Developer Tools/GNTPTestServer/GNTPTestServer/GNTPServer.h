//
//  GNTPServer.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "GrowlDefinesInternal.h"

@class GNTPSubscribePacket, GNTPServer;

@protocol GNTPServerDelegate <NSObject>

-(void)server:(GNTPServer*)server registerWithDictionary:(NSDictionary*)dictionary;
-(GrowlNotificationResult)server:(GNTPServer*)server notifyWithDictionary:(NSDictionary*)dictionary;
-(void)server:(GNTPServer*)server subscribeWithDictionary:(GNTPSubscribePacket*)packet;

@optional
-(NSUInteger)totalSocketCount;

@end

@interface GNTPServer : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, assign) id<GNTPServerDelegate> delegate;

-(id)initWithInterface:(NSString*)interface;

-(BOOL)startServer;
-(void)stopServer;

-(void)notificationClicked:(NSDictionary*)dictionary;
-(void)notificationTimedOut:(NSDictionary*)dictionary;

-(NSUInteger)socketCount;

@end
