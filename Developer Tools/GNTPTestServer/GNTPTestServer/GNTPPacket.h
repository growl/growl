//
//  GNTPPacket.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GNTPKey.h"

@class GNTPKey, GNTPPacket, GCDAsyncSocket;

@interface GNTPPacket : NSObject

@property (nonatomic, retain) GNTPKey *key;
@property (nonatomic, retain) NSString* connectedHost;
@property (nonatomic, retain) NSMutableDictionary *gntpDictionary;
@property (nonatomic, retain) NSMutableDictionary *growlDictionary;

+(BOOL)isValidKey:(GNTPKey*)key
		forPassword:(NSString*)password;

+(BOOL)isAuthorizedPacketType:(NSString*)action
							 withKey:(GNTPKey*)key
						  forSocket:(GCDAsyncSocket*)socket
						  errorCode:(GrowlGNTPErrorCode*)errCode
						description:(NSString**)errDescription;

+(GNTPKey*)keyForSecurityHeaders:(NSArray*)headers
							  errorCode:(GrowlGNTPErrorCode*)errCode
							description:(NSString**)errDescription;

-(BOOL)validate;
-(void)parseDataBlock:(NSData*)data;

@end
