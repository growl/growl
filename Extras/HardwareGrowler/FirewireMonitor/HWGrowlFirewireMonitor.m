//
//  HWGrowlFirewireMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/5/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlFirewireMonitor.h"
#include <IOKit/IOKitLib.h>

@interface HWGrowlFirewireMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign) BOOL notificationsArePrimed;

@property (nonatomic, assign) IONotificationPortRef ioKitNotificationPort;
@property (nonatomic, assign)	CFRunLoopSourceRef notificationRunLoopSource;

@end

@implementation HWGrowlFirewireMonitor

@synthesize delegate;
@synthesize notificationsArePrimed;
@synthesize ioKitNotificationPort;
@synthesize notificationRunLoopSource;

-(id)init {
	if((self = [super init])){
		self.notificationsArePrimed = NO;
		//#warning	kIOMasterPortDefault is only available on 10.2 and above...
		self.ioKitNotificationPort = IONotificationPortCreate(kIOMasterPortDefault);
		self.notificationRunLoopSource = IONotificationPortGetRunLoopSource(ioKitNotificationPort);
		
		CFRunLoopAddSource(CFRunLoopGetCurrent(),
								 notificationRunLoopSource,
								 kCFRunLoopDefaultMode);
	}
	return self;
}

-(void)dealloc {
	if (ioKitNotificationPort) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
		IONotificationPortDestroy(ioKitNotificationPort);
	}
	[super dealloc];
}

-(void)postRegistrationInit {
	[self registerForFireWireNotifications];
}

-(NSString*)nameForFireWireObject:(io_object_t)thisObject {
	//	This works with USB devices...
	//	but apparently not firewire
	kern_return_t	nameResult;
	io_name_t		deviceNameChars;
	
	nameResult = IORegistryEntryGetName(thisObject, deviceNameChars);
	if (nameResult != KERN_SUCCESS) {
		NSLog(@"Could not get name for FireWire object: IORegistryEntryGetName returned 0x%x", nameResult);
		return NULL;
	}

	NSString* tempDeviceName = [NSString stringWithCString:deviceNameChars encoding:NSASCIIStringEncoding];
	if (tempDeviceName) {
		if ([tempDeviceName compare:@"IOFireWireDevice"] != NSOrderedSame)
			return tempDeviceName;
	}
	
	tempDeviceName = IORegistryEntrySearchCFProperty(thisObject,
																	 kIOFireWirePlane,
																	 CFSTR("FireWire Product Name"),
																	 nil,
																	 kIORegistryIterateRecursively);
	
	if (tempDeviceName)
		return tempDeviceName;
	
	tempDeviceName = IORegistryEntrySearchCFProperty(thisObject,
																	 kIOFireWirePlane,
																	 CFSTR("FireWire Vendor Name"),
																	 nil,
																	 kIORegistryIterateRecursively);
	
	if (tempDeviceName)
		return tempDeviceName;
	
	return NSLocalizedString(@"Unnamed FireWire Device", @"");
}

#pragma mark Callbacks

-(void)fwDeviceName:(NSString*)deviceName added:(BOOL)added {
	NSString *title = added ? NSLocalizedString(@"Firewire Connection", @"") : NSLocalizedString(@"Firewire Disconnection", @"");
	
	[delegate notifyWithName:added ? @"FirewireConnected" : @"FireDisconnected"
							 title:title
					 description:deviceName
							  icon:nil
			  identifierString:deviceName
				  contextString:nil
							plugin:self];
}

-(void)fwDeviceAdded:(io_iterator_t)iterator {
	io_object_t	thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		if (notificationsArePrimed || [delegate onLaunchEnabled]) {
			NSString *deviceName = [self nameForFireWireObject:thisObject];
			[self fwDeviceName:deviceName added:YES];
		}
		IOObjectRelease(thisObject);
	}
}

static void fwDeviceAdded(void *refCon, io_iterator_t iterator) {
	HWGrowlFirewireMonitor *monitor = (HWGrowlFirewireMonitor*)refCon;
	[monitor fwDeviceAdded:iterator];
}

-(void)fwDeviceRemvoed:(io_iterator_t)iterator {
	io_object_t thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		NSString *deviceName = [self nameForFireWireObject:thisObject];
		[self fwDeviceName:deviceName added:NO];		
		IOObjectRelease(thisObject);
	}
}

static void fwDeviceRemoved(void *refCon, io_iterator_t iterator) {
	HWGrowlFirewireMonitor *monitor = (HWGrowlFirewireMonitor*)refCon;
	[monitor fwDeviceRemvoed:iterator];
}

#pragma mark -

-(void)registerForFireWireNotifications {
	//http://developer.apple.com/documentation/DeviceDrivers/Conceptual/AccessingHardware/AH_Finding_Devices/chapter_4_section_2.html#//apple_ref/doc/uid/TP30000379/BABEACCJ
	kern_return_t   matchingResult;
	io_iterator_t   addedIterator;
	kern_return_t   removeNoteResult;
	io_iterator_t   removedIterator;
	CFDictionaryRef myFireWireMatchDictionary;
	
	//	NSLog(@"registerForFireWireNotifications");
	
	//	Setup a matching dictionary.
	myFireWireMatchDictionary = IOServiceMatching("IOFireWireDevice");
	
	//	Register our notification
	matchingResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
																	  kIOPublishNotification,
																	  myFireWireMatchDictionary,
																	  fwDeviceAdded,
																	  self,
																	  &addedIterator);
	
	if (matchingResult)
		NSLog(@"matching notification registration failed: %d)", matchingResult);
	
	//	Prime the notifications (And deal with the existing devices)...
	[self fwDeviceAdded:addedIterator];
	
	//	Register for removal notifications.
	
	//	It seems we have to make a new dictionary...  reusing the old one didn't work.
	myFireWireMatchDictionary = IOServiceMatching("IOFireWireDevice");
	removeNoteResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
																		 kIOTerminatedNotification,
																		 myFireWireMatchDictionary,
																		 fwDeviceRemoved,
																		 self,
																		 &removedIterator);
	
	// Matching notification must be "primed" by iterating over the
	// iterator returned from IOServiceAddMatchingNotification(), so
	// we call our device removed method here...
	//
	if (kIOReturnSuccess != removeNoteResult)
		NSLog(@"Couldn't add device removal notification");
	else
		[self fwDeviceRemvoed:removedIterator];
	
	self.notificationsArePrimed = YES;
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return @"Firewire Monitor";
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"FirewireConnected", @"FirewireDisconnected", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Firewire Connected", @"FirewireConnected",
			  @"Firewire Disconnected", @"FirewireDisconnected", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Sent when a Firewire Device is connected", @"FirewireConnected",
			  @"Sent when a Firewire Device is disconnected", @"FirewireDisconnected", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"FirewireConnected", @"FirewireDisconnected", nil];
}

@end
