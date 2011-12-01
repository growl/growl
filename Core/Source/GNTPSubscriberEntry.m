//
//  GNTPSubscriberEntry.m
//  Growl
//
//  Created by Daniel Siemer on 11/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GNTPSubscriberEntry.h"
#import "GrowlGNTPPacket.h"
#import "GrowlErrorGNTPPacket.h"
#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlSubscribeGNTPPacket.h"
#import "GNTPKey.h"
#import "GCDAsyncSocket.h"
#import "GrowlKeychainUtilities.h"
#import "GrowlNetworkUtilities.h"

@implementation GNTPSubscriberEntry

@synthesize computerName;
@synthesize addressString;
@synthesize domain;
@synthesize lastKnownAddress;
@synthesize password;
@synthesize uuid;
@synthesize key;
@synthesize resubscribeTimer;

@synthesize initialTime;
@synthesize timeToLive;
@synthesize subscriberPort;
@synthesize remote;
@synthesize manual;
@synthesize use;
@synthesize subscriptionError;

-(id)initWithName:(NSString*)name
    addressString:(NSString*)addrString
           domain:(NSString*)aDomain
          address:(NSData*)addrData
             uuid:(NSString*)aUUID
           remote:(BOOL)isRemote
           manual:(BOOL)isManual
              use:(BOOL)shouldUse
      initialTime:(NSDate*)date
       timeToLive:(NSInteger)ttl
             port:(NSInteger)port
{
   if((self = [super init])){
      self.computerName = name;
      if(!domain || [domain isEqualToString:@""])
         self.domain = @"local.";
      else
         self.domain = aDomain;
      self.addressString = addrString;
      self.lastKnownAddress = addrData;
      
      if(!aUUID || [aUUID isEqualToString:@""])
         self.uuid = [[NSProcessInfo processInfo] globallyUniqueString];
      else
         self.uuid = aUUID;
      
      self.remote = isRemote;
      self.manual = isManual;
      self.use = shouldUse;
      
      self.initialTime = date;
      self.timeToLive = ttl;
      
      if (port > 0)
         self.subscriberPort = port;
      else
         self.subscriberPort = GROWL_TCP_PORT;
   }
   return self;
}

-(id)initWithDictionary:(NSDictionary*)dict {
   if((self = [self initWithName:[dict valueForKey:@"computerName"]
                   addressString:[dict valueForKey:@"addressString"]
                          domain:[dict valueForKey:@"domain"]
                         address:[dict valueForKey:@"address"]
                            uuid:[dict valueForKey:@"uuid"]
                          remote:[[dict valueForKey:@"remote"] boolValue]
                          manual:[[dict valueForKey:@"manual"] boolValue]
                             use:[[dict valueForKey:@"use"] boolValue]
                     initialTime:[dict valueForKey:@"initialTime"]
                      timeToLive:[[dict valueForKey:@"timeToLive"] integerValue]
                            port:[[dict valueForKey:@"subscriberPort"] integerValue]]))
   {
      if(!remote)
         self.password = [GrowlKeychainUtilities passwordForServiceName:@"GrowlLocalSubscriber" accountName:uuid];
   }
   return self;
}

-(id)initWithPacket:(GrowlSubscribeGNTPPacket*)packet {
   if((self = [self initWithName:[packet subscriberName]
                   addressString:[packet connectedHost]
                          domain:@"local."
                         address:[[packet socket] connectedAddress]
                            uuid:[packet subscriberID]
                          remote:YES
                          manual:NO
                             use:YES
                     initialTime:[NSDate date] 
                      timeToLive:[packet ttl]
                            port:[packet subscriberPort]]))
   {
      //and store the password
      /*
       * Setup time out time out timer
       */
   }
   return self;
}

-(void)resubscribeTimerStart {
   [self invalidate];
   self.resubscribeTimer = [NSTimer timerWithTimeInterval:(timeToLive/2.0)
                                                   target:self
                                                 selector:@selector(resubscribeTimerFire:)
                                                 userInfo:nil
                                                  repeats:NO];
   [[NSRunLoop mainRunLoop] addTimer:resubscribeTimer forMode:NSRunLoopCommonModes];
}

-(void)resubscribeTimerFire:(NSTimer*)timer {
   [self subscribe];
   self.resubscribeTimer = nil;
}

-(void)updateRemoteWithPacket:(GrowlSubscribeGNTPPacket*)packet {
   if(!remote)
      return;
   
   self.initialTime = [NSDate date];
   self.timeToLive = [packet ttl];
   self.lastKnownAddress = [[packet socket] connectedAddress];
   self.subscriberPort = [packet subscriberPort];
}

-(void)updateLocalWithPacket:(GrowlGNTPPacket*)packet {
   if(remote)
      return;
   
   if([packet isKindOfClass:[GrowlOkGNTPPacket class]]){
      self.addressString = [packet connectedHost];
      self.initialTime = [NSDate date];
      __block NSInteger time = 0;
      [[packet customHeaders] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if([[obj headerName] caseInsensitiveCompare:GrowlGNTPResponseSubscriptionTTL] == NSOrderedSame){
            time = [[obj headerValue] integerValue];
            *stop = YES;
         }
      }];
      self.timeToLive = time;
      self.subscriptionError = NO;
      
      [self resubscribeTimerStart];
   }else if([packet isKindOfClass:[GrowlErrorGNTPPacket class]]){
      /*Note the error to the user somehow*/
      self.initialTime = [NSDate distantPast];
      self.timeToLive = 0;
      self.subscriptionError = YES;
      [self invalidate];
   }
}

-(void)dealloc 
{
   [computerName release];
   [addressString release];
   [domain release];
   [lastKnownAddress release];
   [password release];
   [uuid release];
   [key release];
   [resubscribeTimer invalidate];
   [resubscribeTimer release];
   resubscribeTimer = nil;
   [initialTime release];
   [super dealloc];
}

-(void)setPassword:(NSString *)pass {
   if(pass == password || [pass isEqualToString:password]) {
      return;
   }
   if(password)
      [password release];
   password = [pass copy];
   NSString *type = remote ? @"GrowlRemoteSubscriber" : @"GrowlLocalSubscriber";
   [GrowlKeychainUtilities setPassword:password forService:type accountName:uuid];
   self.key = [[[GNTPKey alloc] initWithPassword:password hashAlgorithm:GNTPSHA512 encryptionAlgorithm:GNTPNone] autorelease];
}

-(void)subscribe {
   if(remote)
      return;
   
   //Can't connect without a computer name
   if(!computerName)
      return;
   /*
    * Send out a subscription packet
    */
   
   __block GNTPSubscriberEntry *blockSelf = self;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSDictionary *dict = [NSDictionary dictionaryWithObject:[blockSelf uuid] forKey:GrowlGNTPSubscriberID];
      GrowlGNTPOutgoingPacket *packet = [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_SubscribeType forDict:dict];
      [packet setKey:[blockSelf key]];
      
      NSData *destAddress = [GrowlNetworkUtilities addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[blockSelf computerName] withDomain:[blockSelf domain]];
      
      dispatch_async(dispatch_get_main_queue(), ^{
         [[GrowlGNTPPacketParser sharedParser] sendPacket:packet
                                                toAddress:destAddress];
      });
   });
}

-(void)invalidate {
   if(!remote){
      if(resubscribeTimer){
         [resubscribeTimer invalidate];
         self.resubscribeTimer = nil;
      }
   }
}

-(NSDictionary*)dictionaryRepresentation {
   NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:computerName, @"computerName", 
                                                                   addressString, @"addressString",
                                                                   domain, @"domain",
                                                                   lastKnownAddress, @"address",
                                                                   uuid, @"uuid",
                                                                   [NSNumber numberWithBool:remote], @"remote",
                                                                   [NSNumber numberWithBool:manual], @"manual",
                                                                   initialTime, @"initialTime",
                                                                   [NSNumber numberWithInteger:timeToLive], @"timeToLive",
                                                                   [NSNumber numberWithInteger:subscriberPort], @"subscriberPort", nil];
   return dict;
}

@end
