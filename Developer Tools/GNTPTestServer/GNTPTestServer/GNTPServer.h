//
//  GNTPServer.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol GNTPServerDelegate <NSObject>

-(void)registerWithDictionary:(NSDictionary*)dictionary;
-(void)notifyWithDictionary:(NSDictionary*)dictionary;
-(void)subscribeWithDictionary:(NSDictionary*)dictionary;

-(BOOL)isNoteRegistered:(NSString*)noteName forApp:(NSString*)appName onHost:(NSString*)host;

@end

@interface GNTPServer : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, assign) id<GNTPServerDelegate> delegate;

+ (NSData*)doubleCLRF;

-(void)startServer;
-(void)stopServer;

-(void)notificationClicked:(NSDictionary*)dictionary;
-(void)notificationTimedOut:(NSDictionary*)dictionary;

@end
