//
//  GNTPSubscriptionController.m
//  Growl
//
//  Created by Daniel Siemer on 11/21/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GNTPSubscriptionController.h"
#import "GrowlPreferencesController.h"
#import "GrowlGNTPPacket.h"
#import "GrowlSubscribeGNTPPacket.h"
#import "GNTPSubscriberEntry.h"

#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlGNTPDefines.h"
#import "GrowlNetworkUtilities.h"
#import "NSStringAdditions.h"
#import "GrowlBonjourBrowser.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@implementation GNTPSubscriptionController

@synthesize remoteSubscriptions;
@synthesize localSubscriptions;
@synthesize subscriberID;

@synthesize preferences;

+ (GNTPSubscriptionController*)sharedController {
   static GNTPSubscriptionController *instance;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
   });
   return instance;
}

-(id)init {
   if((self = [super init])) {
      self.preferences = [GrowlPreferencesController sharedController];
      
      self.subscriberID = [preferences GNTPSubscriberID];
      if(!subscriberID || [subscriberID isEqualToString:@""]) {
         self.subscriberID = [[NSProcessInfo processInfo] globallyUniqueString];
         [preferences setGNTPSubscriberID:subscriberID];
      }
      
      self.remoteSubscriptions = [NSMutableDictionary dictionary];
      __block NSMutableDictionary *blockRemote = self.remoteSubscriptions;
      NSArray *remoteItems = [preferences objectForKey:@"GrowlRemoteSubscriptions"];
      [remoteItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         //init a subscriber item, check if its still valid, and add it
         GNTPSubscriberEntry *entry = [[GNTPSubscriberEntry alloc] initWithDictionary:obj];
         if([[NSDate date] compare:[NSDate dateWithTimeInterval:[entry timeToLive] sinceDate:[entry initialTime]]] != NSOrderedDescending)
            [blockRemote setValue:entry forKey:[entry subscriberID]];
         else
            [entry invalidate];
         [entry release];
      }];
      
      //We had some subscriptions that have lapsed, remove them
      if([[remoteSubscriptions allValues] count] < [remoteItems count])
         [self saveSubscriptions:YES];
      
      NSArray *localItems = [preferences objectForKey:@"GrowlLocalSubscriptions"];
      self.localSubscriptions = [NSMutableArray arrayWithCapacity:[localItems count]];
      __block NSMutableArray *blockLocal = self.localSubscriptions;
      [localItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         GNTPSubscriberEntry *entry = [[GNTPSubscriberEntry alloc] initWithDictionary:obj];
         
         //If someone deleted the GNTPSubscriptionID key in the plist, this will make sure they got updated
         if(![[entry subscriberID] isEqualToString:subscriberID])
            [entry setSubscriberID:subscriberID];
            
         [blockLocal addObject:entry];
         if([entry use]){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
               //attempt to renew the subscription with the remote machine, 
               [entry subscribe];
            });
         }
         [entry release];
      }];
      
      NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
      [center addObserver:self
                 selector:@selector(appRegistered:)
                     name:@"ApplicationRegistered"
                   object:nil];
      
      [center addObserver:self 
                 selector:@selector(serviceFound:) 
                     name:GNTPServiceFoundNotification 
                   object:[GrowlBonjourBrowser sharedBrowser]];
      [center addObserver:self 
                 selector:@selector(serviceRemoved:) 
                     name:GNTPServiceRemovedNotification 
                   object:[GrowlBonjourBrowser sharedBrowser]];
      [center addObserver:self 
                 selector:@selector(browserStopped:) 
                     name:GNTPBrowserStopNotification 
                   object:[GrowlBonjourBrowser sharedBrowser]];
   }
   return self;
}

-(void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [self saveSubscriptions:YES];
   [self saveSubscriptions:NO];
   [localSubscriptions release];
   [remoteSubscriptions release];
   [subscriberID release];
   [super dealloc];
}

-(void)saveSubscriptions:(BOOL)remote {
   NSString *saveKey;
   NSArray *toSave;
   if(remote) {
      toSave = [[[remoteSubscriptions allValues] copy] autorelease];
      saveKey = @"GrowlRemoteSubscriptions";
   } else {
      toSave = [[localSubscriptions copy] autorelease];
      saveKey = @"GrowlLocalSubscriptions";
   }
   __block NSMutableArray *saveItems = [NSMutableArray arrayWithCapacity:[toSave count]];
   [toSave enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSDictionary *dict = [obj dictionaryRepresentation];
      if(dict)
         [saveItems addObject:dict];
   }];
   
   [preferences setObject:saveItems forKey:saveKey];
}

-(BOOL)addRemoteSubscriptionFromPacket:(GrowlSubscribeGNTPPacket*)packet {
   if(![packet isKindOfClass:[GrowlSubscribeGNTPPacket class]])
      return NO;
   
   GNTPSubscriberEntry *entry = [remoteSubscriptions valueForKey:[packet subscriberID]];
   if(entry){
      //We need to update the entry
      [self willChangeValueForKey:@"remoteSubscriptionsArray"];
      [entry updateRemoteWithPacket:packet];
      [self didChangeValueForKey:@"remoteSubscriptionsArray"];
   }else{
      //We need to try creating the entry
      entry = [[GNTPSubscriberEntry alloc] initWithPacket:packet];
      [self willChangeValueForKey:@"remoteSubscriptionsArray"];
      [remoteSubscriptions setValue:entry forKey:[entry subscriberID]];
      [entry updateRemoteWithPacket:packet];
      [self didChangeValueForKey:@"remoteSubscriptionsArray"];
      [entry release];
   }
   [self saveSubscriptions:YES];
   return YES;
}

-(void)updateLocalSubscriptionWithPacket:(GrowlGNTPPacket*)packet {
   /*
    * Update the appropriate local subscription item with its new TTL, and have it set its timer to fire appropriately
    */   
   __block GNTPSubscriberEntry *entry = nil;
   [localSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj addressString] caseInsensitiveCompare:[packet connectedHost]] == NSOrderedSame){
         entry = obj;
      }
   }];
   
   if(!entry) {
      NSLog(@"Error: Cant find Local subscription entry for host: %@", [packet connectedHost]);
      return;
   }
   
   [entry updateLocalWithPacket:packet];
   [self saveSubscriptions:NO];
}

#pragma mark UI Related

-(void)newManualSubscription {
   GNTPSubscriberEntry *newEntry = [[GNTPSubscriberEntry alloc] initWithName:nil
                                                               addressString:nil
                                                                      domain:@"local."
                                                                     address:nil
                                                                        uuid:[[NSProcessInfo processInfo] globallyUniqueString]
                                                                subscriberID:subscriberID
                                                                      remote:NO
                                                                      manual:YES
                                                                         use:NO
                                                                 initialTime:[NSDate distantPast]
                                                                  timeToLive:0
                                                                        port:GROWL_TCP_PORT];
   [self willChangeValueForKey:@"localSubscriptions"];
   [localSubscriptions addObject:newEntry];
   [self didChangeValueForKey:@"localSubscriptions"];
   [newEntry release];
}


-(BOOL)removeRemoteSubscriptionForSubscriberID:(NSString *)subID {
   [self willChangeValueForKey:@"remoteSubscriptionsArray"];
   [remoteSubscriptions removeObjectForKey:subID];
   [self didChangeValueForKey:@"remoteSubscriptionsArray"];
   [self saveSubscriptions:YES];
   return YES;
}

-(BOOL)removeLocalSubscriptionAtIndex:(NSUInteger)index {
   if(index >= [localSubscriptions count])
      return NO;
   [self willChangeValueForKey:@"localSubscriptions"];
   [GrowlKeychainUtilities removePasswordForService:@"GrowlLocalSubscriber" accountName:[[localSubscriptions objectAtIndex:index] uuid]];
   [localSubscriptions removeObjectAtIndex:index];
   [self didChangeValueForKey:@"localSubscriptions"];
   [self saveSubscriptions:NO];
   return YES;
}

#pragma mark Forwarding

-(NSString*)passwordForLocalSubscriber:(NSString*)host {
   __block NSString *password = nil;
   [localSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj addressString] caseInsensitiveCompare:host] == NSOrderedSame){
         password = [obj password];
         //We do this so that the password will stick around long enough to be used by the caller
         password = [[password stringByAppendingString:[obj subscriberID]] retain];
         *stop = YES;
      }
   }];
   //However, it should still be autoreleased, just in the right area
   return [password autorelease];
}

-(void)forwardGrowlDict:(NSDictionary*)dict ofType:(GrowlGNTPOutgoingPacketType)type {
   if(![preferences isSubscriptionAllowed])
      return;

   [remoteSubscriptions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      if([[obj validTime] compare:[NSDate date]] == NSOrderedAscending)
         return;
      
      GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacketOfType:type
                                                                                      forDict:dict];
      GNTPKey *cryptoKey = [[[GNTPKey alloc] initWithPassword:[NSString stringWithFormat:@"%@%@", [preferences remotePassword], [obj subscriberID]]
                                               hashAlgorithm:GNTPSHA512
                                         encryptionAlgorithm:GNTPNone] autorelease];
      [outgoingPacket setKey:cryptoKey];
      NSData *coercedAddress = [GrowlNetworkUtilities addressData:[obj lastKnownAddress] coercedToPort:[obj subscriberPort]];
      dispatch_async(dispatch_get_main_queue(), ^{
         [[GrowlGNTPPacketParser sharedParser] sendPacket:outgoingPacket
                                                toAddress:coercedAddress];
      });
   }];
}

-(void)forwardNotification:(NSDictionary*)noteDict {
   [self forwardGrowlDict:noteDict ofType:GrowlGNTPOutgoingPacket_NotifyType];
}

/* Hande forwarding registrations */
-(void)appRegistered:(NSNotification*)note {
   [self forwardGrowlDict:[note userInfo] ofType:GrowlGNTPOutgoingPacket_RegisterType];
}

#pragma mark Table bindings accessor

-(NSArray*)remoteSubscriptionsArray
{
    return [remoteSubscriptions allValues];
}

#pragma mark Bonjour Browser notification methods

-(void)browserStopped:(NSNotification*)note
{
   /* Clean up any entries which we wont be saving, as well as turning the active flag off on all entries */
   NSArray *currentNames = [[self.preferences objectForKey:@"GrowlLocalSubscriptions"] valueForKey:@"computerName"];
   __block NSMutableArray *toRemove = [NSMutableArray array];
   [localSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GNTPSubscriberEntry class]])
         return;
      if(![obj manual])
         [obj setActive:NO];
      
      if(![obj use] && ![obj password] && ![currentNames containsObject:[obj computerName]])
         [toRemove addObject:obj];
   }];
   if([toRemove count] > 0){
      [self willChangeValueForKey:@"localSubscriptions"];
      [localSubscriptions removeObjectsInArray:toRemove];
      [self didChangeValueForKey:@"localSubscriptions"];
      [self saveSubscriptions:NO];
   }
}

-(void)serviceFound:(NSNotification*)note
{
	// check if a computer with this name has already been added
   NSNetService *aNetService = [[note userInfo] valueForKey:GNTPServiceKey];
	NSString *name = [aNetService name];
	__block GNTPSubscriberEntry *entry = nil;
   [localSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GNTPSubscriberEntry class]])
         return;
		if ([[obj computerName] caseInsensitiveCompare:name] == NSOrderedSame) {
			[obj setActive:YES];
         entry = obj;
			return;
		}
   }];
   
   if(entry)
      return;
   
	// don't add the local machine    
   if([name isLocalHost])
      return;
   
	// add a new entry at the end
	entry = [[GNTPSubscriberEntry alloc] initWithName:name
                                       addressString:nil
                                              domain:[aNetService domain]
                                             address:nil
                                                uuid:[[NSProcessInfo processInfo] globallyUniqueString]
                                        subscriberID:subscriberID
                                              remote:NO
                                              manual:NO
                                                 use:NO
                                         initialTime:[NSDate distantPast]
                                          timeToLive:0
                                                port:GROWL_TCP_PORT];   
   [self willChangeValueForKey:@"localSubscriptions"];
	[localSubscriptions addObject:entry];
   [self didChangeValueForKey:@"localSubscriptions"];
	[entry release];
}

-(void)serviceRemoved:(NSNotification*)note
{
   NSNetService *aNetService = [[note userInfo] valueForKey:GNTPServiceKey];
   NSArray *destinationNames = [[self.preferences objectForKey:@"GrowlLocalSubscriptions"] valueForKey:@"computerName"];
	__block GNTPSubscriberEntry *toRemove = nil;
	NSString *name = [aNetService name];
   [localSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GNTPSubscriberEntry class]])
         return;
      
		if ([[obj computerName] isEqualToString:name]) {
			[obj setActive:NO];
         
         /* If we dont need this one anymore, get rid of it */
         if(![obj use] && ![obj password] && ![destinationNames containsObject:[obj computerName]])
            toRemove = obj;
			*stop = YES;
         return;
		}
   }];
   
   if(toRemove){
      [self willChangeValueForKey:@"localSubscriptions"];
      [localSubscriptions removeObject:toRemove];
      [self didChangeValueForKey:@"localSubscriptions"];
   }
}


@end
