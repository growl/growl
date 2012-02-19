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

@property (nonatomic, retain) NSString *listenForIncomingNoteLabel;
@property (nonatomic, retain) NSString *serverPasswordLabel;
@property (nonatomic, retain) NSString *ipAddressesLabel;
@property (nonatomic, retain) NSString *forwardingTabTitle;
@property (nonatomic, retain) NSString *subscriptionsTabTitle;
@property (nonatomic, retain) NSString *subscribersTabTitle;
@property (nonatomic, retain) NSString *bonjourDiscoveredLabel;
@property (nonatomic, retain) NSString *manualEntryLabel;
@property (nonatomic, retain) NSString *firewallLabel;

@property (nonatomic, retain) NSString *forwardEnableCheckboxLabel;
@property (nonatomic, retain) NSString *subscriberEnableCheckboxLabel;
@property (nonatomic, retain) NSString *useColumnTitle;
@property (nonatomic, retain) NSString *computerColumnTitle;
@property (nonatomic, retain) NSString *passwordColumnTitle;
@property (nonatomic, retain) NSString *validColumnTitle;

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
