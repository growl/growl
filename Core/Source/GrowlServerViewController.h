//
//  GrowlServerViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GNTPForwarder;

@interface GrowlServerViewController : GrowlPrefsViewController

@property (nonatomic, assign) GNTPForwarder *forwarder;
@property (nonatomic, assign) IBOutlet NSTableColumn *serviceNameColumn;
@property (nonatomic, assign) IBOutlet NSTableColumn *servicePasswordColumn;
@property (nonatomic, assign) IBOutlet NSTableView *networkTableView;

@property (nonatomic) int currentServiceIndex;

@property (nonatomic, retain) NSString *networkAddressString;

- (void)updateAddresses;
- (void)startBrowsing;
- (void)stopBrowsing;
- (IBAction)removeSelectedForwardDestination:(id)sender;
- (IBAction)newManualForwader:(id)sender;

@end
