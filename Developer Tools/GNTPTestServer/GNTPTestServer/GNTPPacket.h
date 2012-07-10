//
//  GNTPPacket.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GNTPKey.h"

typedef  BOOL(^GNTPHeaderBlock)(NSString *headerKey, NSString *headerValue);

@class GNTPKey, GNTPPacket, GCDAsyncSocket;

@interface GNTPPacket : NSObject

@property (nonatomic, retain) GNTPKey *key;
@property (nonatomic, retain) NSString *connectedHost;
@property (nonatomic, retain) NSString *action;
@property (nonatomic, retain) NSDictionary *growlDict;
@property (nonatomic, retain) NSMutableDictionary *gntpDictionary;
@property (nonatomic, retain) NSMutableArray *dataBlockIdentifiers;
@property (nonatomic, assign) NSInteger state;
@property (nonatomic, assign) BOOL keepAlive;

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

+(NSString*)headerKeyFromHeader:(NSString*)header;
+(NSString*)headerValueFromHeader:(NSString*)header;
+(void)enumerateHeaders:(NSString*)headersString 
				  withBlock:(GNTPHeaderBlock)headerBlock;

+(NSDictionary*)gntpToGrowlMatchingDict;
+(NSString*)growlDictKeyForGNTPKey:(NSString*)gntpKey;

-(NSInteger)parsePossiblyEncryptedDataBlock:(NSData*)data;
-(NSInteger)parseDataBlock:(NSData*)data;
-(void)parseHeaderKey:(NSString*)headerKey value:(NSString*)stringValue;
-(void)receivedResourceDataBlock:(NSData*)data forIdentifier:(NSString*)identifier;

-(BOOL)validate;
-(NSData*)responseData;
-(NSTimeInterval)requestedTimeAlive;
//DO NOT TOUCH, FOR SUBCLASSES, USE @property growlDict
-(NSMutableDictionary*)convertedGrowlDict;

@end
