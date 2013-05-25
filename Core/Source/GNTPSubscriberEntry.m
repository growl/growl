//
//  GNTPSubscriberEntry.m
//  Growl
//
//  Created by Daniel Siemer on 11/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GNTPSubscriberEntry.h"
#import "GNTPSubscriptionController.h"
#import "GrowlBonjourBrowser.h"
#import "GNTPKey.h"
#import "GrowlNetworkUtilities.h"
#import "GrowlPreferencesController.h"
#import "GrowlNetworkObserver.h"
#import "NSStringAdditions.h"
#import "GCDAsyncSocket.h"
#import "GNTPPacket.h"
#import "GNTPSubscribePacket.h"
#import "GrowlGNTPSubscriptionAttempt.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@implementation GNTPSubscriberEntry

@synthesize computerName = _computerName;
@synthesize addressString = _addressString;
@synthesize domain = _domain;
@synthesize lastKnownAddress = _lastKnownAddress;
@synthesize password = _password;
@synthesize subscriberID = _subscriberID;
@synthesize uuid = _uuid;
@synthesize key = _key;
@synthesize resubscribeTimer = _resubscribeTimer;

@synthesize initialTime = _initialTime;
@synthesize validTime = _validTime;
@synthesize timeToLive = _timeToLive;
@synthesize subscriberPort = _subscriberPort;
@synthesize remote = _remote;
@synthesize manual = _manual;
@synthesize use = _use;
@synthesize active = _active;
@synthesize alreadyBrowsing = _alreadyBrowsing;
@synthesize attemptingToSubscribe = _attemptingToSubscribe;
@synthesize subscriptionError = _subscriptionError;
@synthesize subscriptionErrorDescription = _subscriptionErrorDescription;

@synthesize subscriptionAttempt;

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
      self.alreadyBrowsing = NO;
      self.computerName = name;
      if(!aDomain || [aDomain isEqualToString:@""])
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
            self.subscriberID = self.uuid;
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
      self.active = self.manual;
      self.subscriptionError = NO;
      self.subscriptionErrorDescription = nil;
      
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
      if(!self.remote)
         self.password = [GrowlKeychainUtilities passwordForServiceName:@"GrowlLocalSubscriber" accountName:self.uuid];
   }
   return self;
}

-(id)initWithPacket:(GNTPSubscribePacket*)packet {
   if((self = [self initWithName:[[packet gntpDictionary] objectForKey:GrowlGNTPSubscriberName]
                   addressString:[packet connectedHost]
                          domain:@"local."
                         address:[packet connectedAddress]
                            uuid:[[NSProcessInfo processInfo] globallyUniqueString]
                    subscriberID:[[packet gntpDictionary] objectForKey:GrowlGNTPSubscriberID]
                          remote:YES
                          manual:NO
                             use:YES
                     initialTime:[NSDate date] 
                      timeToLive:[packet ttl]
                            port:[[[packet gntpDictionary] objectForKey:GrowlGNTPSubscriberPort] integerValue]]))
   {
      /*
       * Setup time out time out timer
       */
      self.active = YES;
   }
   return self;
}

-(void)save
{
    [[GNTPSubscriptionController sharedController] saveSubscriptions:self.remote];
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
      if(!self.remote){
         [self invalidate];
      }
   }
}

-(void)resubscribeTimerStart {
   [self invalidate];
   self.resubscribeTimer = [NSTimer timerWithTimeInterval:(self.timeToLive/2.0)
                                                   target:self
                                                 selector:@selector(resubscribeTimerFire:)
                                                 userInfo:nil
                                                  repeats:NO];
   [[NSRunLoop mainRunLoop] addTimer:self.resubscribeTimer forMode:NSRunLoopCommonModes];
}

-(void)resubscribeTimerFire:(NSTimer*)timer {
   [self subscribe];
   self.resubscribeTimer = nil;
}

-(void)updateRemoteWithPacket:(GNTPSubscribePacket*)packet {
   if(!self.remote)
      return;
   
   self.initialTime = [NSDate date];
   self.timeToLive = [packet ttl];
   self.validTime = [self.initialTime dateByAddingTimeInterval:self.timeToLive];
   self.lastKnownAddress = [packet connectedAddress];
   self.subscriberPort = [[packet gntpDictionary] objectForKey:GrowlGNTPSubscriberPort] ? [[[packet gntpDictionary] objectForKey:GrowlGNTPSubscriberPort] integerValue] : GROWL_TCP_PORT;
   self.active = YES;
   [self save];
}

-(void)updateLocalWithPacket:(GrowlGNTPSubscriptionAttempt*)packet error:(BOOL)wasError {
   if(self.remote)
      return;

	NSDictionary *dict = [packet callbackHeaderItems];
   self.attemptingToSubscribe = NO;
   if(!wasError){
      self.addressString = [GCDAsyncSocket hostFromAddress:[packet addressData]];
      self.initialTime = [NSDate date];
		NSInteger time = [dict objectForKey:GrowlGNTPResponseSubscriptionTTL] ? [[dict objectForKey:GrowlGNTPResponseSubscriptionTTL] integerValue] : 100;
      self.timeToLive = time;
      self.validTime = [self.initialTime dateByAddingTimeInterval:self.timeToLive];
      self.subscriptionError = NO;
      self.subscriptionErrorDescription = nil;
      [self resubscribeTimerStart];
   }else{
      self.addressString = nil;
      self.initialTime = [NSDate distantPast];
      self.timeToLive = 0;
      self.subscriptionError = YES;
		GrowlGNTPErrorCode reason = (GrowlGNTPErrorCode)[[dict objectForKey:@"Error-Code"] integerValue];
		NSString *description = [dict objectForKey:@"Error-Description"];
      self.subscriptionErrorDescription = [NSString stringWithFormat:NSLocalizedString(@"There was an error subscribing to the remote machine:\ncode: %d\ndescription: %@", 
                                                                                       @"Error description format for subscription error returned display"),
																													reason, 
                                                                                       description];
      self.validTime = nil;
      [self invalidate];
   }
   [self save];
}

-(void)dealloc 
{
   [self removeObserver:self forKeyPath:@"use"];
   [self removeObserver:self forKeyPath:@"computerName"];
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [_computerName release];
   [_addressString release];
   [_domain release];
   [_lastKnownAddress release];
   [_password release];
   [_subscriberID release];
   [_uuid release];
   [_key release];
   [_resubscribeTimer invalidate];
   [_resubscribeTimer release];
   self.resubscribeTimer = nil;
   [_initialTime release];
   [super dealloc];
}

-(void)setActive:(BOOL)flag {
   if(!self.manual){
		_active = flag;
      if(self.active && self.use && !self.remote)
         [self subscribe];
   }else{
      _active = YES;
   }
}

-(void)setUse:(BOOL)flag {
   _use = flag;
   if(self.use && !self.remote){
      [self subscribe];
      if(!self.alreadyBrowsing && !self.manual){
         [[GrowlBonjourBrowser sharedBrowser] startBrowsing];
         self.alreadyBrowsing = YES;
      }
   }
   if(!self.use && !self.remote){
      self.lastKnownAddress = nil;
      self.subscriptionAttempt = nil;
      self.attemptingToSubscribe = NO;
      self.subscriptionError = NO;
      self.subscriptionErrorDescription = nil;
      self.initialTime = [NSDate distantPast];
      self.timeToLive = 0;
      self.validTime = nil;
      
      if(self.alreadyBrowsing && !self.manual){
         [[GrowlBonjourBrowser sharedBrowser] startBrowsing];
         self.alreadyBrowsing = NO;
      }
   }
}

-(void)setComputerName:(NSString *)name
{
   if(_computerName)
      [_computerName release];
   _computerName = [name retain];

   self.lastKnownAddress = nil;
   
   //If this is a manual computer, we should try subscribing after updating the name
   if(self.manual)
      [self subscribe];
}

-(void)setPassword:(NSString *)pass {
   if(pass == _password || [pass isEqualToString:self.password]) {
      return;
   }
   if(_password)
      [_password release];
   _password = [pass copy];
   NSString *type = self.remote ? @"GrowlRemoteSubscriber" : @"GrowlLocalSubscriber";
   [GrowlKeychainUtilities setPassword:self.password forService:type accountName:self.uuid];
   self.key = [[[GNTPKey alloc] initWithPassword:self.password hashAlgorithm:GNTPSHA512 encryptionAlgorithm:GNTPNone] autorelease];
   
   //We should try subscribing
   [self subscribe];
}

- (void) setLastKnownAddress:(NSData *)address {
   //If someone is trying to set the address data and we aren't allowed to do caching at the moment, nil it
   //Unlike forwarding, we do have a situation where we must have address data stored, subscribed machines we must know their address data to send
   if(!self.remote && ![[GrowlPreferencesController sharedController] boolForKey:@"AddressCachingEnabled"] && address)
      address = nil;
   if(_lastKnownAddress)
      [_lastKnownAddress release];
   _lastKnownAddress = [address retain];
}

-(void)subscribe {
   //Lets not fire this instantly or repeatedly, just to be certain
   [GNTPSubscriberEntry cancelPreviousPerformRequestsWithTarget:self selector:@selector(subscribeDelay) object:nil];
   [self performSelector:@selector(subscribeDelay)
              withObject:nil
              afterDelay:.2];
}

-(void)subscribeDelay {
   //Can't subscribe if this is a remote entry
   //Can't subscribe if this entry isn't set to be used
   //Can't subscribe without a computer name
   //Can't subscribe to a bonjour entry if it isn't active
   if(self.remote || !self.use || !self.computerName || (!self.manual && !self.active)){
      self.timeToLive = 0;
      self.initialTime = [NSDate distantPast];
      self.subscriptionError = YES;
      self.attemptingToSubscribe = NO;
		self.subscriptionAttempt = nil;
      if(self.remote){
         self.subscriptionErrorDescription = NSLocalizedString(@"This should never happen! -(void)subscribe should only ever be called on local entries", @"");
      }else if(!self.use){
         self.subscriptionError = NO;
      }else if(!self.computerName){
         self.subscriptionErrorDescription = NSLocalizedString(@"A destination (IP Address or Domain name) is needed to be able to subscribe", @"");
      }else if((!self.manual && !self.active)){
         self.subscriptionErrorDescription = NSLocalizedString(@"Bonjour configured entry, not presently findable", @"");
      }
      return;
   }
   
   if(self.attemptingToSubscribe)
      return;
   
   self.attemptingToSubscribe = YES;
   /*
    * Send out a subscription packet
    */
   __block GNTPSubscriberEntry *blockSelf = self;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSData *destAddress = nil;//[[GrowlPreferencesController sharedController] boolForKey:@"AddressCachingEnabled"] ? blockSelf.lastKnownAddress : nil;
      if(!destAddress){
         destAddress = [GrowlNetworkUtilities addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[blockSelf computerName] withDomain:[blockSelf domain]];
         self.lastKnownAddress = destAddress;
      }
		if(destAddress){
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[blockSelf subscriberID], GrowlGNTPSubscriberID,
										 [GrowlNetworkUtilities localHostName], GrowlGNTPSubscriberName, nil];
			self.subscriptionAttempt = [[[GrowlGNTPSubscriptionAttempt alloc] initWithDictionary:dict] autorelease];
			[self.subscriptionAttempt setPassword:self.password];
			[self.subscriptionAttempt setAddressData:destAddress];
			[self.subscriptionAttempt setDelegate:self];
			
			self.addressString = [GCDAsyncSocket hostFromAddress:destAddress];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.subscriptionAttempt begin];
			});
		}else{
			self.timeToLive = 0;
			self.initialTime = [NSDate distantPast];
			self.subscriptionError = YES;
			self.attemptingToSubscribe = NO;
			self.subscriptionErrorDescription = @"Unable to resolve address";
			self.subscriptionAttempt = nil;
		}
   });
}

-(void)invalidate {
   if(!self.remote){
      if(self.resubscribeTimer){
         [self.resubscribeTimer invalidate];
         self.resubscribeTimer = nil;
      }
   }
}

-(NSDictionary*)dictionaryRepresentation {
   if(!self.subscriberID || !self.uuid)
      return nil;
   
   NSMutableDictionary *buildDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.subscriberID, @"subscriberID", 
                                                                                      self.uuid, @"uuid", nil];
   if(self.computerName)     [buildDict setValue:self.computerName forKey:@"computerName"];
   if(self.addressString)    [buildDict setValue:self.addressString forKey:@"addressString"];
   if(self.domain)           [buildDict setValue:self.domain forKey:@"domain"];
   if(self.initialTime)      [buildDict setValue:self.initialTime forKey:@"initialTime"];
   //We only need last known address if this is a remote host, local entries can redo lookup
   if(self.lastKnownAddress && self.remote) [buildDict setValue:self.lastKnownAddress forKey:@"address"];
   [buildDict setValue:[NSNumber numberWithBool:self.use] forKey:@"use"];
   [buildDict setValue:[NSNumber numberWithBool:self.remote] forKey:@"remote"];
   [buildDict setValue:[NSNumber numberWithBool:self.manual] forKey:@"manual"];   
   [buildDict setValue:[NSNumber numberWithInteger:self.timeToLive] forKey:@"timeToLive"];
   [buildDict setValue:[NSNumber numberWithInteger:self.subscriberPort] forKey:@"subscriberPort"];   
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

#pragma mark GrowlCommunicationAttemptDelegate

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
	__block GNTPSubscriberEntry *blockSubscriber = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[blockSubscriber updateLocalWithPacket:(GrowlGNTPSubscriptionAttempt*)attempt error:NO];
	});
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
	__block GNTPSubscriberEntry *blockSubscriber = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[blockSubscriber updateLocalWithPacket:(GrowlGNTPSubscriptionAttempt*)attempt error:YES];
	});
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt {
	__block GNTPSubscriberEntry *blockSubscriber = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		blockSubscriber.subscriptionAttempt = nil;
	});
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt {
	//Do nothing!
}

//Sent after success
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context {
	//Send click
}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context {
	//Send timeout
}
- (void) notificationClosed:(GrowlCommunicationAttempt *)attempt context:(id)context {
   //send closed
}

@end
