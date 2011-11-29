//
//  GNTPSubscriberEntry.h
//  Growl
//
//  Created by Daniel Siemer on 11/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GNTPKey, GrowlGNTPPacket, GrowlOkGNTPPacket, GrowlSubscribeGNTPPacket;

@interface GNTPSubscriberEntry : NSObject

@property (nonatomic, retain) NSString *computerName;
@property (nonatomic, retain) NSString *addressString;
@property (nonatomic, retain) NSString *domain;
@property (nonatomic, retain) NSData *lastKnownAddress;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) GNTPKey *key;
@property (nonatomic, retain) NSTimer *resubscribeTimer;

@property (nonatomic, retain) NSDate *initialTime;
@property (nonatomic) NSInteger timeToLive;
@property (nonatomic) BOOL remote;
@property (nonatomic) BOOL manual;
@property (nonatomic) BOOL use;

@property (nonatomic) BOOL subscriptionError;

-(id)initWithName:(NSString*)name
    addressString:(NSString*)addrString
           domain:(NSString*)aDomain
          address:(NSData*)addrData
             uuid:(NSString*)aUUID
           remote:(BOOL)isRemote
           manual:(BOOL)isManual
              use:(BOOL)shouldUse
      initialTime:(NSDate*)date
       timeToLive:(NSInteger)ttl;

-(id)initWithDictionary:(NSDictionary*)dict;
-(id)initWithPacket:(GrowlSubscribeGNTPPacket*)packet;

-(void)updateRemoteWithPacket:(GrowlSubscribeGNTPPacket*)packet;
-(void)updateLocalWithPacket:(GrowlGNTPPacket*)packet;
-(void)subscribe;

-(void)invalidate;
-(NSDictionary*)dictionaryRepresentation;

@end
