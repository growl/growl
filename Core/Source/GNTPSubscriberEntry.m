//
//  GNTPSubscriberEntry.m
//  Growl
//
//  Created by Daniel Siemer on 11/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GNTPSubscriberEntry.h"
#import "GNTPSubscriptionController.h"
#import "GrowlGNTPPacket.h"
#import "GrowlErrorGNTPPacket.h"
#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlSubscribeGNTPPacket.h"
#import "GNTPKey.h"
#import "GCDAsyncSocket.h"
#import "GrowlKeychainUtilities.h"
#import "GrowlNetworkUtilities.h"
#import "GrowlPreferencesController.h"
#import "GrowlNetworkObserver.h"
#import "NSStringAdditions.h"

@implementation GNTPSubscriberEntry

@synthesize computerName;
@synthesize addressString;
@synthesize domain;
@synthesize lastKnownAddress;
@synthesize password;
@synthesize subscriberID;
@synthesize uuid;
@synthesize key;
@synthesize resubscribeTimer;

@synthesize initialTime;
@synthesize timeToLive;
@synthesize subscriberPort;
@synthesize remote;
@synthesize manual;
@synthesize use;
@synthesize active;
@synthesize attemptingToSubscribe;
@synthesize subscriptionError;
@synthesize subscriptionErrorDescription;

-(id)initWithName:(NSString*)name
    addressString:(NSString*)addrString
           domain:(NSString*)aDomain
          address:(NSData*)addrData
             uuid:(NSString*)aUUID
     subscriberID:(NSString*)subID
           remote:(BOOL)isRemote
           manual:(BOOL)isManual
              use:(BOOL)shouldUse
      initialTime:(NSDate*)date
       timeToLive:(NSInteger)ttl
             port:(NSInteger)port
{
   if((self = [super init])){
      computerName = [name retain];
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
      
      if(!subID || [subID isEqualToString:@""]){
         if(isRemote)
            self.subscriberID = uuid;
         else
            self.subscriberID = [[GrowlPreferencesController sharedController] GNTPSubscriberID];
      }else
         self.subscriberID = subID;
      
      self.remote = isRemote;
      self.manual = isManual;
      self.use = shouldUse;
      
      self.initialTime = date;
      self.timeToLive = ttl;
      
      if (port > 0)
         self.subscriberPort = port;
      else
         self.subscriberPort = GROWL_TCP_PORT;
      
      self.attemptingToSubscribe = NO;
      self.active = NO;
      self.subscriptionError = NO;
      self.subscriptionErrorDescription = nil;
      self.lastKnownAddress = nil;
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(primaryIPChanged:)
                                                   name:PrimaryIPChangeNotification
                                                 object:[GrowlNetworkObserver sharedObserver]];
      
      [self addObserver:self 
             forKeyPath:@"use" 
                options:NSKeyValueObservingOptionNew 
                context:self];
      [self addObserver:self 
             forKeyPath:@"computerName" 
                options:NSKeyValueObservingOptionNew 
                context:self];
   }
   return self;
}

-(id)initWithDictionary:(NSDictionary*)dict {
   if((self = [self initWithName:[dict valueForKey:@"computerName"]
                   addressString:[dict valueForKey:@"addressString"]
                          domain:[dict valueForKey:@"domain"]
                         address:[dict valueForKey:@"address"]
                            uuid:[dict valueForKey:@"uuid"]
                    subscriberID:[dict valueForKey:@"subscriberID"]
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
                            uuid:[[NSProcessInfo processInfo] globallyUniqueString]
                    subscriberID:[packet subscriberID]
                          remote:YES
                          manual:NO
                             use:YES
                     initialTime:[NSDate date] 
                      timeToLive:[packet ttl]
                            port:[packet subscriberPort]]))
   {
      /*
       * Setup time out time out timer
       */
      active = YES;
   }
   return self;
}

-(void)save
{
    [[GNTPSubscriptionController sharedController] saveSubscriptions:remote];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"use"] ||
       [keyPath isEqualToString:@"computerName"])
        [self save];
}

-(void)primaryIPChanged:(NSNotification*)note
{
   self.lastKnownAddress = nil;
   if([[GrowlNetworkObserver sharedObserver] primaryIP]){
      //If we have a primary IP, we need to try resubscribing
      [self subscribe];
   }else{
      //We don't have a primary IP, we should cancel out anything going on, we will try again when we do
      if(!remote){
         [self invalidate];
      }
   }
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
   active = YES;
   [self save];
}

-(void)updateLocalWithPacket:(GrowlGNTPPacket*)packet {
   if(remote)
      return;
   
   self.attemptingToSubscribe = NO;
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
      if(time == 0)
         time = 100;
      self.timeToLive = time;
      self.subscriptionError = NO;
      self.subscriptionErrorDescription = nil;
      [self resubscribeTimerStart];
   }else if([packet isKindOfClass:[GrowlErrorGNTPPacket class]]){
      /*Note the error to the user somehow*/
      self.addressString = nil;
      self.initialTime = [NSDate distantPast];
      self.timeToLive = 0;
      self.subscriptionError = YES;
      self.subscriptionErrorDescription = [NSString stringWithFormat:NSLocalizedString(@"There was an error subscribing to the remote machine:\ncode: %d\ndescription: %@", 
                                                                                       @"Error description format for subscription error returned display"),
                                                                                       [(GrowlErrorGNTPPacket*)packet errorCode], 
                                                                                       [(GrowlErrorGNTPPacket*)packet errorDescription]];
      [self invalidate];
   }
   [self save];
}

-(void)dealloc 
{
   [self removeObserver:self forKeyPath:@"use"];
   [self removeObserver:self forKeyPath:@"computerName"];
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [computerName release];
   [addressString release];
   [domain release];
   [lastKnownAddress release];
   [password release];
   [subscriberID release];
   [uuid release];
   [key release];
   [resubscribeTimer invalidate];
   [resubscribeTimer release];
   resubscribeTimer = nil;
   [initialTime release];
   [super dealloc];
}

-(void)setActive:(BOOL)flag {
   active = flag;
   if(active && use && !remote)
      [self subscribe];
}

-(void)setUse:(BOOL)flag {
   use = flag;
   if(use && !remote)
      [self subscribe];
}

-(void)setComputerName:(NSString *)name
{
   if(computerName)
      [computerName release];
   computerName = [name retain];
   
   //If this is a manual computer, we should try subscribing after updating the name
   if(manual)
      [self subscribe];
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
   
   //We should try subscribing
   [self subscribe];
}

-(void)subscribe {
   //Can't subscribe if this is a remote entry
   //Can't subscribe if this entry isn't set to be used
   //Can't subscribe without a computer name
   //Can't subscribe to a bonjour entry if it isn't active
   if(remote || !use || !computerName || (!manual && !active)){
      timeToLive = 0;
      self.initialTime = [NSDate distantPast];
      self.subscriptionError = YES;
      self.attemptingToSubscribe = NO;
      if(remote){
         self.subscriptionErrorDescription = NSLocalizedString(@"This should never happen! -(void)subscribe should only ever be called on local entries", @"");
      }else if(!use){
         self.subscriptionError = NO;
      }else if(!computerName){
         self.subscriptionErrorDescription = NSLocalizedString(@"A destination (IP Address or Domain name) is needed to be able to subscribe", @"");
      }else if((!manual && !active)){
         self.subscriptionErrorDescription = NSLocalizedString(@"Bonjour configured entry, not presently findable", @"");
      }
      return;
   }
   
   self.attemptingToSubscribe = YES;
   /*
    * Send out a subscription packet
    */
   __block GNTPSubscriberEntry *blockSelf = self;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSDictionary *dict = [NSDictionary dictionaryWithObject:[blockSelf subscriberID] forKey:GrowlGNTPSubscriberID];
      GrowlGNTPOutgoingPacket *packet = [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_SubscribeType forDict:dict];
      [packet setKey:[blockSelf key]];
      
      NSData *destAddress = lastKnownAddress;
      if(!destAddress){
         destAddress = [GrowlNetworkUtilities addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[blockSelf computerName] withDomain:[blockSelf domain]];
         self.lastKnownAddress = destAddress;
      }
      [blockSelf setAddressString:[GCDAsyncSocket hostFromAddress:destAddress]];
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
   if(!subscriberID || !uuid)
      return nil;
   
   NSMutableDictionary *buildDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:subscriberID, @"subscriberID", 
                                                                                      uuid, @"uuid", nil];
   if(computerName)     [buildDict setValue:computerName forKey:@"computerName"];
   if(addressString)    [buildDict setValue:addressString forKey:@"addressString"];
   if(domain)           [buildDict setValue:domain forKey:@"domain"];
   if(lastKnownAddress) [buildDict setValue:lastKnownAddress forKey:@"address"];
   if(computerName)     [buildDict setValue:computerName forKey:@"computerName"];
   if(initialTime)      [buildDict setValue:initialTime forKey:@"initialTime"];
   [buildDict setValue:[NSNumber numberWithBool:remote] forKey:@"remote"];
   [buildDict setValue:[NSNumber numberWithBool:manual] forKey:@"manual"];   
   [buildDict setValue:[NSNumber numberWithInteger:timeToLive] forKey:@"timeToLive"];
   [buildDict setValue:[NSNumber numberWithInteger:subscriberPort] forKey:@"subscriberPort"];   
   return [[buildDict copy] autorelease];
}

-(BOOL)validateValue:(id *)ioValue forKey:(NSString *)inKey error:(NSError **)outError
{
   if(![inKey isEqualToString:@"computerName"])
      return [super validateValue:ioValue forKey:inKey error:outError];
   
   NSString *newString = (NSString*)*ioValue;
   if(([newString Growl_isLikelyIPAddress] || [newString Growl_isLikelyDomainName]) && 
      ![newString isLocalHost]){
      return YES;
   }
   
   NSString *description;
   if([newString isLocalHost]){
      NSLog(@"Error, don't enter localhost in any of its forms");
      description = NSLocalizedString(@"Please do not enter localhost, Growl does not support subscribing to itself.", @"Localhost in a subscription destination is not allowed");
   }else{
      NSLog(@"Error, enter a valid host name or IP");
      description = NSLocalizedString(@"Please enter a valid IPv4 or IPv6 address, or a valid domain name", @"A valid IP or domain is needed to subscribe to");
   }
   
   NSDictionary *eDict = [NSDictionary dictionaryWithObject:description
                                                     forKey:NSLocalizedDescriptionKey];
   if(outError != NULL)
      *outError = [[[NSError alloc] initWithDomain:@"GrowlNetworking" code:2 userInfo:eDict] autorelease];
   return NO;
}

@end
