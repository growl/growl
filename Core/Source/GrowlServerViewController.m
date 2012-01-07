//
//  GrowlServerViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlServerViewController.h"
#import "ACImageAndTextCell.h"
#import "GrowlPreferencesController.h"
#import "GrowlBrowserEntry.h"
#import "GrowlKeychainUtilities.h"
#import "GNTPForwarder.h"
#import "GNTPSubscriberEntry.h"
#import "GNTPSubscriptionController.h"
#import "GrowlBonjourBrowser.h"
#import "GrowlNetworkObserver.h"
#import "NSStringAdditions.h"

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

@synthesize currentServiceIndex;

@synthesize networkAddressString;

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [networkAddressString release];
   [super dealloc];
}

- (void) awakeFromNib {
   self.forwarder = [GNTPForwarder sharedController];
   self.subscriptionController = [GNTPSubscriptionController sharedController];

   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self 
          selector:@selector(reloadPrefs:) 
              name:GrowlPreferencesChanged 
            object:nil];
   
   [GrowlNetworkObserver sharedObserver];
   
   [nc addObserver:self
          selector:@selector(updateAddresses:)
              name:IPAddressesUpdateNotification 
            object:[GrowlNetworkObserver sharedObserver]];
   
   ACImageAndTextCell *imageTextCell = [[[ACImageAndTextCell alloc] init] autorelease];
   [serviceNameColumn setDataCell:imageTextCell];
	[networkTableView reloadData];
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
   if (aTableColumn == servicePasswordColumn) {
		return [[[forwarder destinations] objectAtIndex:rowIndex] password];
	} else if (aTableColumn == serviceNameColumn) {
        NSCell *cell = [aTableColumn dataCellForRow:rowIndex];
        static NSImage *manualImage = nil;
        static NSImage *bonjourImage = nil;
        if(!manualImage){
            manualImage = [[NSImage imageNamed:NSImageNameNetwork] retain];
            bonjourImage = [[NSImage imageNamed:NSImageNameBonjour] retain];
            NSSize imageSize = NSMakeSize([cell cellSize].height, [cell cellSize].height);
            [manualImage setSize:imageSize];
            [bonjourImage setSize:imageSize];
        }
        GrowlBrowserEntry *entry = [[forwarder destinations] objectAtIndex:rowIndex];
        if([entry manualEntry])
            [cell setImage:manualImage];
        else
            [cell setImage:bonjourImage];
   } else if(aTableView == subscriptionsTableView && rowIndex < (NSInteger)[[subscriptionArrayController arrangedObjects] count]){
      return [[subscriptionArrayController arrangedObjects] objectAtIndex:rowIndex];
   }

	return nil;
}

@end
