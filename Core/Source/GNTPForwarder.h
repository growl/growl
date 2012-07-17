//
//  GNTPForwarder.h
//  Growl
//
//  Created by Daniel Siemer on 11/19/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GrowlCommunicationAttempt.h"

@class GrowlPreferencesController;

@interface GNTPForwarder : NSObject <GrowlCommunicationAttemptDelegate>

@property (nonatomic, assign) GrowlPreferencesController *preferences;
@property (nonatomic, retain) NSMutableArray *destinations;
@property (nonatomic) BOOL alreadyBrowsing;

+ (GNTPForwarder*)sharedController;

- (void)preferencesChanged:(NSNotification*)note;
- (void)clearCachedAddresses;

- (void)newManualEntry;
- (void)removeEntryAtIndex:(NSUInteger)index;
- (void)writeForwardDestinations;

- (void)forwardNotification:(NSDictionary *)dict;
- (void)forwardRegistration:(NSDictionary *)dict;

@end
