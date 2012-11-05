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

@interface GNTPPacket : NSObject {
	GNTPKey *_key;
	NSString *_connectedHost;
	NSData *_connectedAddress;
	NSString *_guid;
	NSString *_action;
	NSDictionary *_growlDict;
	NSMutableDictionary *_gntpDictionary;
	NSMutableArray *_dataBlockIdentifiers;
	NSInteger _state;
	BOOL _keepAlive;
	
	NSString *_incomingDataIdentifier;
	NSUInteger _incomingDataLength;
	BOOL _incomingDataHeaderRead;
}

@property (nonatomic, retain) GNTPKey *key;
@property (nonatomic, retain) NSString *connectedHost;
@property (nonatomic, retain) NSData *connectedAddress;
@property (nonatomic, retain) NSString *guid;
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
						  originKey:(GNTPKey*)originKey
						  forSocket:(GCDAsyncSocket*)socket
						  errorCode:(GrowlGNTPErrorCode*)errCode
						description:(NSString**)errDescription;

+(GNTPKey*)keyForSecurityHeaders:(NSArray*)headers
							  errorCode:(GrowlGNTPErrorCode*)errCode
							description:(NSString**)errDescription;

#pragma mark Conversion Methods
+(NSDictionary*)gntpToGrowlMatchingDict;
+(NSString*)growlDictKeyForGNTPKey:(NSString*)gntpKey;
+(id)convertedObjectFromGNTPObject:(id)obj forGrowlKey:(NSString*)growlKey;
+(NSDictionary*)growlToGNTPMatchingDict;
+(NSString*)gntpKeyForGrowlDictKey:(NSString*)growlKey;
+(id)convertedObjectFromGrowlObject:(id)obj forGNTPKey:(NSString*)gntpKey;
+(NSData*)convertedDataForIconObject:(id)obj;

#pragma mark Packet Building

+(NSMutableDictionary*)gntpDictFromGrowlDict:(NSDictionary*)dict;
+(NSString*)headersForGNTPDictionary:(NSDictionary*)dict;
+(NSData*)gntpDataFromGrowlDictionary:(NSDictionary*)dict 
										 ofType:(NSString*)type
										withKey:(GNTPKey*)encryptionKey;
+ (NSString *)identifierForBinaryData:(NSData *)data;

#pragma mark Packet
-(NSInteger)parsePossiblyEncryptedDataBlock:(NSData*)data;
-(NSInteger)parseDataBlock:(NSData*)data;
-(void)parseHeaderKey:(NSString*)headerKey value:(NSString*)stringValue;
-(void)receivedResourceDataBlock:(NSData*)data forIdentifier:(NSString*)identifier;

-(BOOL)validate;
-(NSString*)responseString;
-(NSData*)responseData;
-(NSTimeInterval)requestedTimeAlive;
//DO NOT TOUCH, FOR SUBCLASSES, USE @property growlDict
-(NSMutableDictionary*)convertedGrowlDict;

@end
