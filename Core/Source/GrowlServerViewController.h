//
//  GrowlServerViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GNTPForwarder, GNTPSubscriptionController;

@interface GrowlServerViewController : GrowlPrefsViewController

@property (nonatomic, assign) GNTPForwarder *forwarder;
@property (nonatomic, assign) GNTPSubscriptionController *subscriptionController;
@property (nonatomic, assign) IBOutlet NSTableColumn *serviceNameColumn;
@property (nonatomic, assign) IBOutlet NSTableColumn *servicePasswordColumn;
@property (nonatomic, assign) IBOutlet NSTableView *networkTableView;
@property (nonatomic, assign) IBOutlet NSTableView *subscriptionsTableView;
@property (nonatomic, assign) IBOutlet NSTableView *subscriberTableView;
@property (nonatomic, assign) IBOutlet NSArrayController *subscriptionArrayController;
@property (nonatomic, assign) IBOutlet NSArrayController *subscriberArrayController;
@property (nonatomic, assign) IBOutlet NSTabView *networkConnectionTabView;

@property (nonatomic) int currentServiceIndex;

@property (nonatomic, retain) NSString *networkAddressString;

- (void)updateAddresses:(NSNotification*)note;
- (void)showNetworkConnectionTab:(NSUInteger)tab;
- (IBAction)removeSelectedForwardDestination:(id)sender;
- (IBAction)newManualForwader:(id)sender;

- (IBAction)newManualSubscription:(id)sender;
- (IBAction)removeSelectedSubscription:(id)sender;

- (IBAction)removeSelectedSubscriber:(id)sender;

@end
