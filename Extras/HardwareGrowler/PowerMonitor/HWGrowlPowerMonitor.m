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
	
	BOOL havePercent = NO;
	NSInteger percentage = [self batteryPercentage];
	if(percentage >= 0)
		havePercent = YES;
	
	BOOL warnBattery = NO;
	IOPSLowBatteryWarningLevel warnLevel = IOPSGetBatteryWarningLevel();
	if(warnLevel != kIOPSLowBatteryWarningNone)
		warnBattery = YES;
	
	if(changedType || sendTime || warnBattery){
		NSString *title = nil;
		NSString *name = nil;
		NSString *localizedSource = [self localizedNameForSource:currentSource];
		NSMutableString *description = nil;
		if(!warnBattery){
			name = @"PowerChange";
			title = [NSString stringWithFormat:NSLocalizedString(@"On %@", @"Format string for On <power type>"), localizedSource];
			if(remaining < 0.0f) {
				description = (currentSource == HGACPower) ? [NSMutableString stringWithString:NSLocalizedString(@"Battery charging", @"")] : nil;
			} else {
				NSUInteger minutesRemaining = (NSUInteger)(remaining / 60.0f);
				NSString *format = (currentSource == HGACPower) ? NSLocalizedString(@"Time to charge: %lu minutes", @"") : NSLocalizedString(@"Time remaining: %lu minutes", @"");
				description = [NSMutableString stringWithFormat:format, minutesRemaining];
			}
				
		} else {
			name = @"PowerWarning";
			title	= NSLocalizedString(@"Battery Low!", @"");
			description = [NSMutableString stringWithString:NSLocalizedString(@"Battery Low, Please plug the computer in now", @"")];
		}
		
		if(description && havePercent)
			[description appendString:@"\n"];
		if(havePercent){
			if(description) [description appendFormat:NSLocalizedString(@"Current Level: %ld%%", @""), percentage];
			else description = [NSMutableString stringWithFormat:NSLocalizedString(@"Current Level: %ld%%", @""), percentage];
		}
		
		[delegate notifyWithName:name
								 title:title
						 description:description
								  icon:nil
				  identifierString:name
					  contextString:nil
								plugin:self];
		
		lastPowerSource = currentSource;
		lastKnownTime = remaining;
	}
	
	CFRelease(sourcesBlob);
}

-(NSInteger)batteryPercentage {
	NSInteger percentageCapacity = -1;
	CFTypeRef sourcesBlob = IOPSCopyPowerSourcesInfo();
	CFArrayRef	powerSourcesList = IOPSCopyPowerSourcesList(sourcesBlob);
	CFIndex	count = CFArrayGetCount(powerSourcesList);
	for (CFIndex i = 0; i < count; ++i) {
		CFTypeRef		powerSource;
		CFDictionaryRef description;
		

		powerSource = CFArrayGetValueAtIndex(powerSourcesList, i);
		description = IOPSGetPowerSourceDescription(sourcesBlob, powerSource);
		
		//Don't display anything for power sources that aren't present (i.e. an absent second battery in a 2-battery machine)
		if (CFDictionaryGetValue(description, CFSTR(kIOPSIsPresentKey)) == kCFBooleanFalse)
			continue;
		
		if (CFStringCompare(CFDictionaryGetValue(description, CFSTR(kIOPSTransportTypeKey)), 
								  CFSTR(kIOPSInternalType), 
								  0) == kCFCompareEqualTo)
		{
			CFNumberRef currentCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSCurrentCapacityKey));
			CFNumberRef maxCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSMaxCapacityKey));
			
			CFIndex currentCapacity, maxCapacity, sourceCapacity;
			
			if (CFNumberGetValue(currentCapacityNum, kCFNumberCFIndexType, &currentCapacity) &&
				 CFNumberGetValue(maxCapacityNum, kCFNumberCFIndexType, &maxCapacity))
				sourceCapacity = roundf((currentCapacity / (float)maxCapacity) * 100.0f);
			
			if(sourceCapacity > percentageCapacity)
				percentageCapacity = sourceCapacity;
		}
	}
	return percentageCapacity;
}

-(NSString*)localizedNameForSource:(HGPowerSource)source {
	NSString *result = nil;
	switch (source) {
		case HGACPower:
			result = NSLocalizedString(@"AC Power", @"");
			break;
		case HGBatteryPower:
			result = NSLocalizedString(@"Battery Power", @"");
			break;
		case HGUPSPower:
			result = NSLocalizedString(@"HGUPSPower", @"");
			break;
		case HGUnknownPower:
		default:
			result = NSLocalizedString(@"Unknown Power Source", @"");
			break;
	}
	return result;
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
	return [NSArray arrayWithObjects:@"PowerChange", @"PowerWarning", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Power Changed", @"PowerChange",
			  @"Power Warning", @"Power Warning", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Sent when the type or status of power changed", @"PowerChange",
			  @"Sent when the battery is getting low", @"PowerWarning", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"PowerChange", @"PowerWarning", nil];
}

@end
