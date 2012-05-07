//
//  HWGrowlPowerMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/6/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlPowerMonitor.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/ps/IOPSKeys.h>
#include <IOKit/ps/IOPowerSources.h>

@interface HWGrowlPowerMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign)	CFRunLoopSourceRef notificationRunLoopSource;

@property (nonatomic, assign) HGPowerSource lastPowerSource;
@property (nonatomic, assign) NSTimeInterval lastKnownTime;

@end

@implementation HWGrowlPowerMonitor

@synthesize delegate;
@synthesize notificationRunLoopSource;
@synthesize lastPowerSource;
@synthesize lastKnownTime;

-(id)init {
	if((self = [super init])){
		self.notificationRunLoopSource = IOPSNotificationCreateRunLoopSource(powerSourceChanged, self);
		
		if (notificationRunLoopSource)
			CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
		lastPowerSource = HGUnknownPower;
		lastKnownTime = kIOPSTimeRemainingUnknown;
	}
	return self;
}

-(void)fireOnLaunchNotes {
	[self powerSourceChanged];
}

-(void)powerSourceChanged {
	BOOL changedType = NO;
	CFTypeRef sourcesBlob = IOPSCopyPowerSourcesInfo();
	NSString *source = (NSString*)IOPSGetProvidingPowerSourceType(sourcesBlob);

	HGPowerSource currentSource;
	if([source compare:@"AC Power"] == NSOrderedSame) {
		currentSource = HGACPower;
	} else if ([source compare:@"Battery Power"] == NSOrderedSame) {
		currentSource = HGBatteryPower;
	} else if ([source compare:@"UPS Power"] == NSOrderedSame) {
		currentSource = HGUPSPower;
	} else {
		currentSource = HGUnknownPower;
	}
	
	if(currentSource != lastPowerSource)
		changedType = YES;
	
	CFTimeInterval remaining = kIOPSTimeRemainingUnknown;
//	NSUInteger percentage = 0.0;
	switch (currentSource) {
		case HGACPower:
		{
			//Get our time to full
			CFArrayRef	powerSourcesList = IOPSCopyPowerSourcesList(sourcesBlob);
			CFIndex	count = CFArrayGetCount(powerSourcesList);
			for (CFIndex i = 0; i < count; ++i) {
				CFTypeRef		powerSource;
				CFDictionaryRef description;
				
				CFIndex			batteryTime = -1;
//				CFIndex			percentageCapacity = -1;
				
				powerSource = CFArrayGetValueAtIndex(powerSourcesList, i);
				description = IOPSGetPowerSourceDescription(sourcesBlob, powerSource);
				
				//Don't display anything for power sources that aren't present (i.e. an absent second battery in a 2-battery machine)
				if (CFDictionaryGetValue(description, CFSTR(kIOPSIsPresentKey)) == kCFBooleanFalse)
					continue;
				
				if (CFStringCompare(CFDictionaryGetValue(description, CFSTR(kIOPSTransportTypeKey)), 
										  CFSTR(kIOPSInternalType), 
										  0) == kCFCompareEqualTo)
				{
					if (CFDictionaryGetValue(description, CFSTR(kIOPSIsChargingKey)) == kCFBooleanTrue)
					{
						CFNumberRef timeToChargeNum = CFDictionaryGetValue(description, CFSTR(kIOPSTimeToFullChargeKey));
						CFIndex timeToCharge;
						
						if (CFNumberGetValue(timeToChargeNum, kCFNumberCFIndexType, &timeToCharge))
							batteryTime = timeToCharge;
						
						if((CFTimeInterval)batteryTime > 0.0 && (CFTimeInterval)batteryTime > remaining)
							remaining = (CFTimeInterval)(batteryTime * 60);
					}
					
					/* Capacity */
					/*
					CFNumberRef currentCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSCurrentCapacityKey));
					CFNumberRef maxCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSMaxCapacityKey));
					
					CFIndex currentCapacity, maxCapacity;
					
					if (CFNumberGetValue(currentCapacityNum, kCFNumberCFIndexType, &currentCapacity) &&
						 CFNumberGetValue(maxCapacityNum, kCFNumberCFIndexType, &maxCapacity))
						percentageCapacity = roundf((currentCapacity / (float)maxCapacity) * 100.0f);
					
					if(percentageCapacity > (NSInteger)percentage)
						percentage = percentageCapacity;
					 */
				}
			}
		}
			break;
		case HGUPSPower:
		case HGBatteryPower:
			//Get our time to empty
			remaining = IOPSGetTimeRemainingEstimate();
			break;
		case HGUnknownPower:
		default:
			break;
	}
	BOOL sendTime = NO;
	if(remaining >= 0.0f && (changedType || (remaining == kIOPSTimeRemainingUnknown) != (lastKnownTime == kIOPSTimeRemainingUnknown)))
		sendTime = YES;
	
	BOOL warnBattery = NO;
	IOPSLowBatteryWarningLevel warnLevel = IOPSGetBatteryWarningLevel();
	if(warnLevel != kIOPSLowBatteryWarningNone)
		warnBattery = YES;
	
	if(changedType || sendTime || warnBattery){
		if(!warnBattery){
			if(remaining < 0.0f)
				NSLog(@"On %@", source);
			else {
				NSUInteger minutesRemaining = (NSUInteger)(remaining / 60.0f);
				if(currentSource == HGACPower)
					NSLog(@"On AC Power, %lu minutes til full", minutesRemaining);
				else
					NSLog(@"On Battery Power, %lu minutes remaining", minutesRemaining);
			}
		}else
			NSLog(@"Battery %@", warnLevel == kIOPSLowBatteryWarningEarly ? @"warning" : @"FINAL WARNING");
		
		lastPowerSource = currentSource;
		lastKnownTime = remaining;
	}
	
	CFRelease(sourcesBlob);
}

static void powerSourceChanged(void *context) {
	HWGrowlPowerMonitor *monitor = (HWGrowlPowerMonitor*)context;
	[monitor powerSourceChanged];		
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return @"Power Monitor";
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray array];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionary];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionary];
}
-(NSArray*)defaultNotifications {
	return [NSArray array];
}

@end
