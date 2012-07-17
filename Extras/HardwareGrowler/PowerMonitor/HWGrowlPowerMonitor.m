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

@property (nonatomic, retain) NSTimer *refireTimer;
@property (nonatomic, assign) BOOL lastWarnState;

@end

@implementation HWGrowlPowerMonitor

@synthesize prefsView;
@synthesize delegate;
@synthesize notificationRunLoopSource;
@synthesize lastPowerSource;
@synthesize lastKnownTime;
@synthesize refireTimer;
@synthesize lastWarnState;

-(id)init {
	if((self = [super init])){
		self.notificationRunLoopSource = IOPSNotificationCreateRunLoopSource(powerSourceChanged, self);
		
		if (notificationRunLoopSource)
			CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
		lastPowerSource = HGUnknownPower;
		lastKnownTime = kIOPSTimeRemainingUnknown;
		lastWarnState = NO;
	}
	return self;
}

-(void)dealloc {
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
	CFRelease(notificationRunLoopSource);
	[refireTimer invalidate];
	[refireTimer release];
	[super dealloc];
}

-(void)fireOnLaunchNotes {
	[self powerSourceChanged:YES];
	[self checkTimer];
}

-(BOOL)refireOnBattery {
	BOOL result = YES;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"RefireOnBattery"])
		result = [[NSUserDefaults standardUserDefaults] boolForKey:@"RefireOnBattery"];
	return result;
}
-(void)setRefireOnBattery:(BOOL)refire {
	[[NSUserDefaults standardUserDefaults] setBool:refire forKey:@"RefireOnBattery"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self checkTimer];
}

-(CGFloat)refireTime {
	CGFloat result = 10.0f;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"PowerRefireTime"])
		result = [[NSUserDefaults standardUserDefaults] boolForKey:@"PowerRefireTime"];
	return result;
}
-(void)setRefireTime:(CGFloat)time {
	[[NSUserDefaults standardUserDefaults] setFloat:time forKey:@"PowerRefireTime"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self stopTimer];
	[self checkTimer];
}

-(BOOL)enableRefire {
	BOOL result = YES;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"EnablePowerRefire"])
		result = [[NSUserDefaults standardUserDefaults] boolForKey:@"EnablePowerRefire"];
	return result;
}
-(void)setEnableRefire:(BOOL)enable {
	[[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"EnablePowerRefire"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self checkTimer];
}

-(void)checkTimer {
	if(refireTimer) {
		/* Conditions under which we stop:
		 * refire is disabled, or we are on AC and we only want to fire on battery
		 */
		if(![self enableRefire] || (lastPowerSource == HGACPower && [self refireOnBattery]))
			[self stopTimer];
	} else {
		/* Conditions under which we start:
		 * refire is enabled, and we are not on AC or we only want to fire on battery
		 */
		if([self enableRefire] && (lastPowerSource != HGACPower || ![self refireOnBattery]))
			[self startTimer];
	}
}

-(void)startTimer {	
	if(refireTimer)
		return;
	
//	NSLog(@"start timer");
	self.refireTimer = [NSTimer timerWithTimeInterval:[self refireTime] * 60.0f
															 target:self 
														  selector:@selector(timerFire:)
														  userInfo:nil
															repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:refireTimer forMode:NSDefaultRunLoopMode];
}

-(void)stopTimer {
	if(!refireTimer)
		return;
	
//	NSLog(@"stop timer");
	[refireTimer invalidate];
	self.refireTimer = nil;
}

-(void)timerFire:(NSTimer*)timer {
	[self powerSourceChanged:YES];
}

-(void)powerSourceChanged:(BOOL)force {
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
			CFRelease(powerSourcesList);
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
	if(remaining != kIOPSTimeRemainingUnknown && (changedType || (remaining == kIOPSTimeRemainingUnknown) != (lastKnownTime == kIOPSTimeRemainingUnknown)))
		sendTime = YES;
	
	BOOL havePercent = NO;
	NSInteger percentage = [self batteryPercentage];
	if(percentage >= 0)
		havePercent = YES;
	
	BOOL warnBattery = NO;
	IOPSLowBatteryWarningLevel warnLevel = IOPSGetBatteryWarningLevel();
	if(warnLevel != kIOPSLowBatteryWarningNone)
		warnBattery = YES;
	
	if(lastWarnState && warnBattery)
		warnBattery = NO;
	else if(!lastWarnState && warnBattery)
		lastWarnState = YES;
	else if(lastWarnState && !warnBattery)
		lastWarnState = NO;
	
	if(changedType || sendTime || warnBattery || force){
		NSString *title = nil;
		NSString *name = nil;
		NSString *localizedSource = [self localizedNameForSource:currentSource];
		NSMutableString *description = nil;
		NSData *imageData = nil;
		if(!warnBattery){
			name = @"PowerChange";
			title = [NSString stringWithFormat:NSLocalizedString(@"On %@", @"Format string for On <power type>"), localizedSource];
			if(remaining == kIOPSTimeRemainingUnknown) {
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
		
		switch (currentSource) {
			case HGACPower:
				if(remaining != kIOPSTimeRemainingUnknown || (havePercent && percentage < 95))
					imageData = [[NSImage imageNamed:@"Power-Charging"] TIFFRepresentation];
				else
					imageData = [[NSImage imageNamed:@"Power-Plugged"] TIFFRepresentation];
				break;
			case HGBatteryPower:
			case HGUPSPower:
				if(havePercent){
					NSInteger adjusted = (NSInteger)roundf((CGFloat)percentage / 10.0f);
					NSString *imageName = [NSString stringWithFormat:@"Power-%ld0", adjusted];
					if(adjusted == 0)
						imageName = @"Power-0";
					imageData = [[NSImage imageNamed:imageName] TIFFRepresentation];
				}
				if(!imageData){
					imageData = [[NSImage imageNamed:@"Power-NoBattery"] TIFFRepresentation];
				}
				break;
			case HGUnknownPower:
			default:
				//Shouldn't get to either of these
				imageData = [[NSImage imageNamed:@"Power-BatteryFailure"] TIFFRepresentation];
				break;
		}
		
		[delegate notifyWithName:name
								 title:title
						 description:description
								  icon:imageData
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
			
			CFIndex currentCapacity, maxCapacity, sourceCapacity = -1;
			
			if (CFNumberGetValue(currentCapacityNum, kCFNumberCFIndexType, &currentCapacity) &&
				 CFNumberGetValue(maxCapacityNum, kCFNumberCFIndexType, &maxCapacity))
				sourceCapacity = roundf((currentCapacity / (float)maxCapacity) * 100.0f);
			
			if(sourceCapacity > percentageCapacity)
				percentageCapacity = sourceCapacity;
		}
	}
	CFRelease(sourcesBlob);
	CFRelease(powerSourcesList);
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
			result = NSLocalizedString(@"UPS Power", @"");
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
	[monitor powerSourceChanged:NO];
	[monitor checkTimer];
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return NSLocalizedString(@"Power Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsPower"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[NSBundle loadNibNamed:@"PowerMonitorPrefs" owner:self];
	});
	return prefsView;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"PowerChange", @"PowerWarning", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Power Changed", @""), @"PowerChange",
			  NSLocalizedString(@"Power Warning", @""), @"Power Warning", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sent when the type or status of power changed", @""), @"PowerChange",
			  NSLocalizedString(@"Sent when the battery is getting low", @""), @"PowerWarning", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"PowerChange", @"PowerWarning", nil];
}

@end
