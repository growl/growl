//
//  GNTPServer.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface GNTPServer : NSObject <GCDAsyncSocketDelegate>

-(void)startServer;
-(void)stopServer;

+ (NSData*)doubleCLRF;

@end
