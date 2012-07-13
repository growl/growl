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

@protocol GNTPServerDelegate <NSObject>

-(void)registerWithDictionary:(NSDictionary*)dictionary;
-(GrowlNotificationResult)notifyWithDictionary:(NSDictionary*)dictionary;
//-(void)subscribeWithDictionary:(NSDictionary*)dictionary;

@end

@interface GNTPServer : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, assign) id<GNTPServerDelegate> delegate;

-(id)initWithInterface:(NSString*)interface;

-(BOOL)startServer;
-(void)stopServer;

-(void)notificationClicked:(NSDictionary*)dictionary;
-(void)notificationTimedOut:(NSDictionary*)dictionary;

@end
