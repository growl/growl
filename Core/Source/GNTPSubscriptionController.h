//
//  GNTPSubscriptionController.h
//  Growl
//
//  Created by Daniel Siemer on 11/21/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlCommunicationAttempt.h"

@class GrowlPreferencesController, GNTPSubscribePacket, GrowlGNTPPacket;

@interface GNTPSubscriptionController : NSObject <GrowlCommunicationAttemptDelegate>

//Remote are those that have subscribed to us
//Local are those that we subscribe to
@property (nonatomic, retain) NSMutableDictionary *remoteSubscriptions;
@property (nonatomic, retain) NSMutableArray *localSubscriptions;
@property (nonatomic, retain) NSString *subscriberID;

@property (nonatomic, assign) GrowlPreferencesController *preferences;

+(GNTPSubscriptionController*)sharedController;

-(void)saveSubscriptions:(BOOL)remote;

#pragma mark Updates from the packet system
-(BOOL)addRemoteSubscriptionFromPacket:(GNTPSubscribePacket*)packet;
-(NSString*)passwordForLocalSubscriber:(NSString*)host;

#pragma mark UI related
-(void)newManualSubscription;
-(BOOL)removeRemoteSubscriptionForSubscriberID:(NSString*)subID;
-(BOOL)removeLocalSubscriptionAtIndex:(NSUInteger)index;

#pragma mark Forwarding
-(void)forwardDictionary:(NSDictionary*)dict isRegistration:(BOOL)registration toEntryIDs:(NSArray*)entryIDs;
-(void)forwardNotification:(NSDictionary*)noteDict;

#pragma mark Bindings accessor
-(NSArray*)remoteSubscriptionsArray;

@end
