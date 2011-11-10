//
//  GrowlServerViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@interface GrowlServerViewController : GrowlPrefsViewController <NSNetServiceBrowserDelegate>

@property (nonatomic, retain) NSMutableArray *services;
@property (nonatomic, retain) NSNetServiceBrowser *browser;
@property (nonatomic, assign) IBOutlet NSTableColumn *serviceNameColumn;
@property (nonatomic, assign) IBOutlet NSTableColumn *servicePasswordColumn;
@property (nonatomic, assign) IBOutlet NSTableView *networkTableView;

@property (nonatomic) int currentServiceIndex;

@property (nonatomic, retain) NSString *networkAddressString;

- (void)updateAddresses;
- (void)startBrowsing;
- (void)stopBrowsing;
- (IBAction) removeSelectedForwardDestination:(id)sender;
- (IBAction)newManualForwader:(id)sender;
- (void) writeForwardDestinations;

@end
