//
//  HWGrowlThunderboltMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/5/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlThunderboltMonitor.h"
#include <IOKit/IOKitLib.h>

@interface HWGrowlThunderboltMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign) BOOL notificationsArePrimed;

@property (nonatomic, assign) IONotificationPortRef ioKitNotificationPort;
@property (nonatomic, assign)	CFRunLoopSourceRef notificationRunLoopSource;

@end

@implementation HWGrowlThunderboltMonitor

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
	[self registerForThunderboltNotifications];
}

-(NSString*)nameForThunderboltObject:(io_object_t)thisObject {
	kern_return_t	nameResult;
	io_name_t		deviceNameChars;
	uint32_t size;

	nameResult = IORegistryEntryGetProperty(thisObject, "IOName", deviceNameChars, &size);
	if (nameResult != KERN_SUCCESS) {
		NSLog(@"Could not get name for Thunderbolt object: IORegistryEntryGetName returned 0x%x", nameResult);
		return NULL;
	}
	
	NSString* tempDeviceName = [NSString stringWithCString:deviceNameChars encoding:NSASCIIStringEncoding];
	if (tempDeviceName) {
		return tempDeviceName;
	}
		
	return NSLocalizedString(@"Unnamed Thunderbolt Device", @"");
}

#pragma mark Callbacks

-(void)tbDeviceName:(NSString*)deviceName added:(BOOL)added {
	NSString *title = added ? NSLocalizedString(@"Thunderbolt Connection", @"") : NSLocalizedString(@"Thunderbolt Disconnection", @"");
	
	[delegate notifyWithName:added ? @"ThunderboltConnected" : @"ThunderboltDisconnected"
							 title:title
					 description:deviceName
							  icon:nil
			  identifierString:deviceName
				  contextString:nil
							plugin:self];
}

-(void)tbDeviceAdded:(io_iterator_t)iterator {
	io_object_t	thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		if (notificationsArePrimed || [delegate onLaunchEnabled]) {
			//NSString *deviceName = [self nameForThunderboltObject:thisObject];
			//NSLog(@"hello %@", deviceName);
			//[self tbDeviceName:deviceName added:YES];
		}
		IOObjectRelease(thisObject);
	}
}

static void tbDeviceAdded(void *refCon, io_iterator_t iterator) {
	HWGrowlThunderboltMonitor *monitor = (HWGrowlThunderboltMonitor*)refCon;
	[monitor tbDeviceAdded:iterator];
}

-(void)tbDeviceRemoved:(io_iterator_t)iterator {
	io_object_t thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		//NSString *deviceName = [self nameForThunderboltObject:thisObject];
		//NSLog(@"goodbye %@", deviceName);
		//[self tbDeviceName:deviceName added:NO];		
		IOObjectRelease(thisObject);
	}
}

static void tbDeviceRemoved(void *refCon, io_iterator_t iterator) {
	HWGrowlThunderboltMonitor *monitor = (HWGrowlThunderboltMonitor*)refCon;
	[monitor tbDeviceRemoved:iterator];
}

#pragma mark -

-(void)registerForThunderboltNotifications {
	//http://developer.apple.com/documentation/DeviceDrivers/Conceptual/AccessingHardware/AH_Finding_Devices/chapter_4_section_2.html#//apple_ref/doc/uid/TP30000379/BABEACCJ
	kern_return_t   matchingResult;
	io_iterator_t   addedIterator;
	kern_return_t   removeNoteResult;
	io_iterator_t   removedIterator;
	CFDictionaryRef myThunderboltMatchDictionary;
	
	//	NSLog(@"registerForThunderboltNotifications");
	
	//	Setup a matching dictionary.
	myThunderboltMatchDictionary = IOServiceMatching("IOPCIDevice");
	
	//	Register our notification
	matchingResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
																	  kIOPublishNotification,
																	  myThunderboltMatchDictionary,
																	  tbDeviceAdded,
																	  self,
																	  &addedIterator);
	
	if (matchingResult)
		NSLog(@"matching notification registration failed: %d)", matchingResult);
	
	//	Prime the notifications (And deal with the existing devices)...
	[self tbDeviceAdded:addedIterator];
	
	//	Register for removal notifications.
	
	//	It seems we have to make a new dictionary...  reusing the old one didn't work.
	myThunderboltMatchDictionary = IOServiceMatching("IOPCIDevice");
	removeNoteResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
																		 kIOTerminatedNotification,
																		 myThunderboltMatchDictionary,
																		 tbDeviceRemoved,
																		 self,
																		 &removedIterator);
	
	// Matching notification must be "primed" by iterating over the
	// iterator returned from IOServiceAddMatchingNotification(), so
	// we call our device removed method here...
	//
	if (kIOReturnSuccess != removeNoteResult)
		NSLog(@"Couldn't add device removal notification");
	else
		[self tbDeviceRemoved:removedIterator];
	
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
	return NSLocalizedString(@"Thunderbolt Monitor", @"");
}
-(NSImage*)preferenceIcon {
	return nil;
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"ThunderboltConnected", @"ThunderboltDisconnected", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Thunderbolt Connected", @""), @"ThunderboltConnected",
			  NSLocalizedString(@"Thunderbolt Disconnected", @""), @"ThunderboltDisconnected", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sent when a Thunderbolt Device is connected", @""), @"ThunderboltConnected",
			  NSLocalizedString(@"Sent when a Thunderbolt Device is disconnected", @""), @"ThunderboltDisconnected", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"ThunderboltConnected", @"ThunderboltDisconnected", nil];
}

@end
