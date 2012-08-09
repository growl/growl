//
//  GrowlServerViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlServerViewController.h"
#import "GrowlPreferencesController.h"
#import "GrowlBrowserEntry.h"
#import "GNTPForwarder.h"
#import "GNTPSubscriberEntry.h"
#import "GNTPSubscriptionController.h"
#import "GrowlBonjourBrowser.h"
#import "GrowlNetworkObserver.h"
#import "NSStringAdditions.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@interface GNTPHostAvailableColorTransformer : NSValueTransformer
@end

@implementation GNTPHostAvailableColorTransformer

+ (void)load
{
   if (self == [GNTPHostAvailableColorTransformer class]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self setValueTransformer:[[[self alloc] init] autorelease]
                        forName:@"GNTPHostAvailableColorTransformer"];
      [pool release];
   }
}

+ (Class)transformedValueClass 
{ 
   return [NSColor class];
}
+ (BOOL)allowsReverseTransformation
{
   return NO;
}
- (id)transformedValue:(id)value
{
   return [value boolValue] ? [NSColor blackColor] : [NSColor redColor];
}

@end

@interface GNTPManualEntryImageTransformer : NSValueTransformer
@end

@implementation GNTPManualEntryImageTransformer

+ (void)load
{
   if (self == [GNTPHostAvailableColorTransformer class]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self setValueTransformer:[[[self alloc] init] autorelease]
                        forName:@"GNTPManualEntryImageTransformer"];
      [pool release];
   }
}

+ (Class)transformedValueClass 
{ 
   return [NSImage class];
}
+ (BOOL)allowsReverseTransformation
{
   return NO;
}
- (id)transformedValue:(id)value
{
   return [value boolValue] ? [NSImage imageNamed:NSImageNameNetwork] : [NSImage imageNamed:NSImageNameBonjour];
}

@end

@implementation GrowlServerViewController

@synthesize forwarder;
@synthesize subscriptionController;
@synthesize serviceNameColumn;
@synthesize servicePasswordColumn;
@synthesize networkTableView;
@synthesize subscriptionsTableView;
@synthesize subscriberTableView;
@synthesize subscriptionArrayController;
@synthesize subscriberArrayController;
@synthesize networkConnectionTabView;

@synthesize listenForIncomingNoteLabel;
@synthesize serverPasswordLabel;
@synthesize ipAddressesLabel;
@synthesize forwardingTabTitle;
@synthesize subscriptionsTabTitle;
@synthesize subscribersTabTitle;
@synthesize bonjourDiscoveredLabel;
@synthesize manualEntryLabel;
@synthesize firewallLabel;

@synthesize forwardEnableCheckboxLabel;
@synthesize subscriberEnableCheckboxLabel;
@synthesize useColumnTitle;
@synthesize computerColumnTitle;
@synthesize passwordColumnTitle;
@synthesize validColumnTitle;

@synthesize currentServiceIndex;

@synthesize networkAddressString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane
{
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.listenForIncomingNoteLabel = NSLocalizedString(@"Listen for incoming notifications", @"Label for checkbox enabling incoming network notifications");
      self.serverPasswordLabel = NSLocalizedString(@"Server Password:", @"Label for server password field");
      self.ipAddressesLabel = NSLocalizedString(@"You can connect manually at one of the following addresses:", @"Label for the IP address list");
      self.forwardingTabTitle = NSLocalizedString(@"Forwarding", @"Tab title for forwarding");
      self.subscriptionsTabTitle = NSLocalizedString(@"Subscriptions", @"Tab title for subscriptions tab");
      self.subscribersTabTitle = NSLocalizedString(@"Subscribers", @"Tab title for subscribers tab");
      self.bonjourDiscoveredLabel = NSLocalizedString(@"Indicates a discovered computer using Growl 1.3 or later", @"Info label describing the bonjour icon's use");
      self.manualEntryLabel = NSLocalizedString(@"Indicates a manually entered computer to forward to or subscribe to", @"Info label describing the network icon's use");
      self.firewallLabel = NSLocalizedString(@"Firewall Settings: Network notifications use TCP port 23053", @"Info label for firewall settings");
      
      self.forwardEnableCheckboxLabel = NSLocalizedString(@"Forward notifications to other computers", @"Enable checkbox for forwarding to other computers");
      self.subscriberEnableCheckboxLabel = NSLocalizedString(@"Allow other computers to subscribe to all notifications", @"Enable checkbox for allowing subscribers");
      self.useColumnTitle = NSLocalizedString(@"Use", @"Column title for whether to use the item on the row");
      self.computerColumnTitle = NSLocalizedString(@"Computer Name", @"Column title for a computer entry");
      self.passwordColumnTitle = NSLocalizedString(@"Password", @"Column title for a password");
      self.validColumnTitle = NSLocalizedString(@"Valid until:", @"Column title for how long a subscriber is valid for");
   
      self.subscriptionController = [GNTPSubscriptionController sharedController];
      self.forwarder = [GNTPForwarder sharedController];
      [GrowlNetworkObserver sharedObserver];
   }
   return self;
}

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [networkAddressString release];
   
   [listenForIncomingNoteLabel release];
   [serverPasswordLabel release];
   [ipAddressesLabel release];
   [forwardingTabTitle release];
   [subscriptionsTabTitle release];
   [subscribersTabTitle release];
   [bonjourDiscoveredLabel release];
   [manualEntryLabel release];
   [firewallLabel release];
   
   [forwardEnableCheckboxLabel release];
   [subscriberEnableCheckboxLabel release];
   [useColumnTitle release];
   [computerColumnTitle release];
   [passwordColumnTitle release];
   [validColumnTitle release];
   
   [super dealloc];
}

- (void) awakeFromNib {
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self 
          selector:@selector(reloadPrefs:) 
              name:GrowlPreferencesChanged 
            object:nil];
   
   [nc addObserver:self
          selector:@selector(updateAddresses:)
              name:IPAddressesUpdateNotification 
            object:[GrowlNetworkObserver sharedObserver]];
}

+ (NSString*)nibName {
   return @"NetworkPrefs";
}

- (void)viewWillLoad
{
   [[GrowlBonjourBrowser sharedBrowser] startBrowsing];
   [self updateAddresses:nil];
   [super viewWillLoad];
}

- (void)viewDidUnload
{
   [[GrowlBonjourBrowser sharedBrowser] stopBrowsing];
   [super viewDidUnload];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	@autoreleasepool {
        id object = [notification object];
        if(!object || [object isEqualToString:GrowlStartServerKey])
            [self updateAddresses:nil];
	}
}

- (IBAction) removeSelectedForwardDestination:(id)sender
{
   [forwarder removeEntryAtIndex:[networkTableView selectedRow]];
}

- (IBAction)newManualForwader:(id)sender {
   [forwarder newManualEntry];
}

- (IBAction)newManualSubscription:(id)sender
{
   [subscriptionController newManualSubscription];
}

- (IBAction)removeSelectedSubscription:(id)sender
{
   [subscriptionController removeLocalSubscriptionAtIndex:[subscriptionsTableView selectedRow]];
}

- (IBAction)removeSelectedSubscriber:(id)sender
{
   GNTPSubscriberEntry *entry = [[subscriberArrayController arrangedObjects] objectAtIndex:[subscriberTableView selectedRow]];
   [subscriptionController removeRemoteSubscriptionForSubscriberID:[entry subscriberID]];
}

- (void)showNetworkConnectionTab:(NSUInteger)tab
{
   if(tab < 3)
      [networkConnectionTabView selectTabViewItemAtIndex:tab];
}

-(void)updateAddresses:(NSNotification*)note
{
   if([[GrowlPreferencesController sharedController] isGrowlServerEnabled])
      self.networkAddressString = [[GrowlNetworkObserver sharedObserver] routableCombined];
   else
      self.networkAddressString = nil;
}

#pragma mark TableView data source methods

- (NSInteger) numberOfRowsInTableView:(NSTableView*)tableView {
	if(tableView == networkTableView) {
		return [[forwarder destinations] count];
	}
	return 0;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if(aTableColumn == servicePasswordColumn) {
		[[[forwarder destinations] objectAtIndex:rowIndex] setPassword:anObject];
	}
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	// we check to make sure we have the image + text column and then set its image manually
   if (aTableView == networkTableView) {
		return [[forwarder destinations] objectAtIndex:rowIndex];
	} else if(aTableView == subscriptionsTableView && rowIndex < (NSInteger)[[subscriptionArrayController arrangedObjects] count]){
      return [[subscriptionArrayController arrangedObjects] objectAtIndex:rowIndex];
   }

	return nil;
}

@end
