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
#import "NSStringAdditions.h"

#import <SystemConfiguration/SystemConfiguration.h>
#include <ifaddrs.h>
#include <arpa/inet.h>


/** A reference to the SystemConfiguration dynamic store. */
static SCDynamicStoreRef dynStore;

/** Our run loop source for notification. */
static CFRunLoopSourceRef rlSrc;

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

@implementation GrowlServerViewController

@synthesize forwarder;
@synthesize serviceNameColumn;
@synthesize servicePasswordColumn;
@synthesize networkTableView;

@synthesize currentServiceIndex;

@synthesize networkAddressString;

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
   if (dynStore)
		CFRelease(dynStore);
   [networkAddressString release];
   [super dealloc];
}

- (void) awakeFromNib {
   self.forwarder = [GNTPForwarder sharedController];

   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self selector:@selector(reloadPrefs:)     name:GrowlPreferencesChanged object:nil];
       
   self.networkAddressString = nil;
   
   SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};
   
	dynStore = SCDynamicStoreCreate(kCFAllocatorDefault,
                                   CFBundleGetIdentifier(CFBundleGetMainBundle()),
                                   scCallback,
                                   &context);
	if (!dynStore) {
		NSLog(@"SCDynamicStoreCreate() failed: %s", SCErrorString(SCError()));
	}
   
   const CFStringRef keys[1] = {
		CFSTR("State:/Network/Interface/*"),
	};
	CFArrayRef watchedKeys = CFArrayCreate(kCFAllocatorDefault,
                                          (const void **)keys,
                                          1,
                                          &kCFTypeArrayCallBacks);
	if (!SCDynamicStoreSetNotificationKeys(dynStore,
                                          NULL,
                                          watchedKeys)) {
		NSLog(@"SCDynamicStoreSetNotificationKeys() failed: %s", SCErrorString(SCError()));
		CFRelease(dynStore);
		dynStore = NULL;
	}
	CFRelease(watchedKeys);
   
   rlSrc = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynStore, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
   CFRelease(rlSrc);

   ACImageAndTextCell *imageTextCell = [[[ACImageAndTextCell alloc] init] autorelease];
   [serviceNameColumn setDataCell:imageTextCell];
	[networkTableView reloadData];
}

+ (NSString*)nibName {
   return @"NetworkPrefs";
}

- (void)viewWillLoad
{
   [self startBrowsing];
   [self updateAddresses];
   [super viewWillLoad];
}

- (void)viewDidUnload
{
   [self stopBrowsing];
   [super viewDidUnload];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	@autoreleasepool {
        id object = [notification object];
        if(!object || [object isEqualToString:GrowlStartServerKey])
            [self updateAddresses];
	}
}

- (IBAction) removeSelectedForwardDestination:(id)sender
{
   //[networkTableView noteNumberOfRowsChanged];
   [forwarder removeEntryAtIndex:[networkTableView selectedRow]];
}

- (IBAction)newManualForwader:(id)sender {
   //[networkTableView noteNumberOfRowsChanged];
   [forwarder newManualEntry];
}

-(void)startBrowsing
{
   [forwarder startBrowsing];
}

-(void)stopBrowsing
{
   [forwarder stopBrowsing];
}

-(void)updateAddresses
{
   if(![self.preferencesController isGrowlServerEnabled]){
      self.networkAddressString = nil;
      return;
   }
   NSMutableString *newString = nil;
   struct ifaddrs *interfaces = NULL;
   struct ifaddrs *current = NULL;
   
   if(getifaddrs(&interfaces) == 0)
   {
      current = interfaces;
      while (current != NULL) {
         NSString *currentString = nil;
         
         NSString *interface = [NSString stringWithUTF8String:current->ifa_name];
         
         if(![interface isEqualToString:@"lo0"] && ![interface isEqualToString:@"utun0"])
         {
            if (current->ifa_addr->sa_family == AF_INET) {
               char stringBuffer[INET_ADDRSTRLEN];
               struct sockaddr_in *ipv4 = (struct sockaddr_in *)current->ifa_addr;
               if (inet_ntop(AF_INET, &(ipv4->sin_addr), stringBuffer, INET_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            } else if (current->ifa_addr->sa_family == AF_INET6) {
               char stringBuffer[INET6_ADDRSTRLEN];
               struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)current->ifa_addr;
               if (inet_ntop(AF_INET6, &(ipv6->sin6_addr), stringBuffer, INET6_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            }          
            
            if(currentString && ![currentString isLocalHost]){
               if(!newString)
                  newString = [[currentString mutableCopy] autorelease];
               else
                  [newString appendFormat:@"\n%@", currentString];
            }
         }
         
         current = current->ifa_next;
      }
   }
   if(newString){
      self.networkAddressString = newString;
      NSLog(@"new addresses %@", newString);
   }
   else
      self.networkAddressString = nil;
   
   freeifaddrs(interfaces);
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	GrowlPreferencePane *prefPane = info;
	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
      if (CFStringCompare(key, CFSTR("State:/Network/Interface"), 0) == kCFCompareEqualTo) {
			[prefPane updateAddresses];
		}
	}
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
    }

	return nil;
}

@end
