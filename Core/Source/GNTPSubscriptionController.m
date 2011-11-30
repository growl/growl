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
      
      self.subscriberID = [preferences objectForKey:@"GNTPSubscriptionID"];
      if(!subscriberID || [subscriberID isEqualToString:@""]) {
         self.subscriberID = [[NSProcessInfo processInfo] globallyUniqueString];
         [preferences setObject:subscriberID forKey:@"GNTPSubscriptionID"];
      }
      
      self.remoteSubscriptions = [NSMutableDictionary dictionary];
      __block NSMutableDictionary *blockRemote = self.remoteSubscriptions;
      NSArray *remoteItems = [preferences objectForKey:@"GrowlRemoteSubscriptions"];
      [remoteItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         //init a subscriber item, check if its still valid, and add it
         GNTPSubscriberEntry *entry = [[GNTPSubscriberEntry alloc] initWithDictionary:obj];
         if([[NSDate date] compare:[NSDate dateWithTimeInterval:[entry timeToLive] sinceDate:[entry initialTime]]] != NSOrderedDescending)
            [blockRemote setValue:entry forKey:[entry uuid]];
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
         if(![[entry uuid] isEqualToString:subscriberID])
            [entry setUuid:subscriberID];
            
         [blockLocal addObject:entry];
         if([entry use]){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
               //attempt to renew the subscription with the remote machine, 
               [entry subscribe];
            });
         }
         [entry release];
      }];
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(appRegistered:)
                                                   name:@"ApplicationRegistered"
                                                 object:nil];
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
   NSMutableArray *saveItems = [NSMutableArray arrayWithCapacity:[toSave count]];
   [toSave enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [saveItems addObject:[obj dictionaryRepresentation]];
   }];
   
   [preferences setObject:saveItems forKey:saveKey];
}

-(BOOL)addRemoteSubscriptionFromPacket:(GrowlSubscribeGNTPPacket*)packet {
   if(![packet isKindOfClass:[GrowlSubscribeGNTPPacket class]])
      return NO;
   
   GNTPSubscriberEntry *entry = [remoteSubscriptions valueForKey:[packet subscriberID]];
   if(entry){
      //We need to update the entry
      [entry updateRemoteWithPacket:packet];
   }else{
      //We need to try creating the entry
      entry = [[GNTPSubscriberEntry alloc] initWithPacket:packet];
      [remoteSubscriptions setValue:entry forKey:[entry uuid]];
   }
   [self saveSubscriptions:YES];
   return YES;
}

-(void)updateLocalSubscriptionWithPacket:(GrowlGNTPPacket*)packet {
   /*
    * Update the appropriate local subscription item with its new TTL, and have it set its timer to fire appropriately
    */
   __block NSString *uuid = nil;
   [[packet customHeaders] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj headerName] caseInsensitiveCompare:GrowlGNTPSubscriberID] == NSOrderedSame){
         uuid = [obj headerValue];
         *stop = YES;
      }
   }];
   if(uuid == nil){
      NSLog(@"Error: Cant find %@ entry for packet %@", GrowlGNTPSubscriberID, packet);
      return;
   }
      
   GNTPSubscriberEntry *entry = [localSubscriptions valueForKey:uuid];
   if(!entry) {
      NSLog(@"Error: Cant find Local subscription entry for uuid: %@", uuid);
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
                                                                        uuid:subscriberID
                                                                      remote:NO
                                                                      manual:YES
                                                                         use:NO
                                                                 initialTime:[NSDate distantPast]
                                                                  timeToLive:0];
   
   [localSubscriptions addObject:newEntry];
}


-(BOOL)removeRemoteSubscriptionForUUID:(NSString*)uuid {
   [remoteSubscriptions removeObjectForKey:uuid];
   [self saveSubscriptions:YES];
   return YES;
}

-(BOOL)removeLocalSubscriptionAtIndex:(NSUInteger)index {
   if(index < [localSubscriptions count])
      return NO;
   
   [localSubscriptions removeObjectAtIndex:index];
   [self saveSubscriptions:NO];
   return YES;
}

#pragma mark Forwarding

-(NSString*)passwordForLocalSubscriber:(NSString*)host {
   __block NSString *password = nil;
   [localSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj addressString] caseInsensitiveCompare:host] == NSOrderedSame){
         password = [obj password];
         password = [password stringByAppendingString:[obj uuid]];
         *stop = YES;
      }
   }];
   return password;
}

-(void)forwardGrowlDict:(NSDictionary*)dict ofType:(GrowlGNTPOutgoingPacketType)type {
   if(![preferences boolForKey:@"SubscriptionAllowed"])
      return;

   [remoteSubscriptions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacketOfType:type
                                                                                      forDict:dict];
      [outgoingPacket setKey:(GNTPKey*)[obj key]];
      dispatch_async(dispatch_get_main_queue(), ^{
         [[GrowlGNTPPacketParser sharedParser] sendPacket:outgoingPacket
                                                toAddress:[obj lastKnownAddress]];
      });
   }];
}

-(void)forwardNotification:(NSDictionary*)noteDict {
   [self forwardGrowlDict:noteDict ofType:GrowlGNTPOutgoingPacket_NotifyType];
}

/* Handle forwarding registrations */
-(void)appRegistered:(NSNotification*)note {
   [self forwardGrowlDict:[note userInfo] ofType:GrowlGNTPOutgoingPacket_RegisterType];
}

@end
