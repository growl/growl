/*
 *  PowerNotifier.c
 *  HardwareGrowler
 *
 *  Created by Evan Schoenberg on 3/27/06.
 *
 */

#include "PowerNotifier.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/ps/IOPSKeys.h>
#include <IOKit/ps/IOPowerSources.h>

#include "AppController.h"

extern void NSLog(CFStringRef format, ...);

static CFRunLoopSourceRef powerNotifierRunLoopSource = NULL;
static HGPowerSource lastPowerSource;
static CFBooleanRef lastChargingState;
static CFIndex lastBatteryTime = -1;

static bool stringsAreEqual(CFStringRef a, CFStringRef b)
{
	if (!a || !b) return 0;

	return (CFStringCompare(a, b, 0) == kCFCompareEqualTo);
}

static void powerSourceChanged(void *context)
{
#pragma unused(context)
	CFTypeRef	powerBlob = IOPSCopyPowerSourcesInfo();
	CFArrayRef	powerSourcesList = IOPSCopyPowerSourcesList(powerBlob);

	CFIndex	count = CFArrayGetCount(powerSourcesList);
	for (CFIndex i = 0; i < count; ++i) {
		CFTypeRef		powerSource;
		CFDictionaryRef description;

		HGPowerSource	hgPowerSource;
		CFBooleanRef	charging = kCFBooleanFalse;
		CFIndex			batteryTime = -1;
		CFIndex			percentageCapacity = -1;

		powerSource = CFArrayGetValueAtIndex(powerSourcesList, i);
		description = IOPSGetPowerSourceDescription(powerBlob, powerSource);

		//Don't display anything for power sources that aren't present (i.e. an absent second battery in a 2-battery machine)
		if (CFDictionaryGetValue(description, CFSTR(kIOPSIsPresentKey)) == kCFBooleanFalse)
			continue;

		//We only know how to handle internal (battery, a/c power) transport types. The other values indicate UPS usage.
		if (stringsAreEqual(CFDictionaryGetValue(description, CFSTR(kIOPSTransportTypeKey)),
							CFSTR(kIOPSInternalType))) {
			CFStringRef currentState = CFDictionaryGetValue(description, CFSTR(kIOPSPowerSourceStateKey));
			if (stringsAreEqual(currentState, CFSTR(kIOPSACPowerValue)))
				hgPowerSource = HGACPower;
			else if (stringsAreEqual(currentState, CFSTR(kIOPSBatteryPowerValue)))
				hgPowerSource = HGBatteryPower;
			else
				hgPowerSource = HGUnknownPower;

			//Battery power
			if (CFDictionaryGetValue(description, CFSTR(kIOPSIsChargingKey)) == kCFBooleanTrue) {
				//Charging
				charging = kCFBooleanTrue;

				CFNumberRef timeToChargeNum = CFDictionaryGetValue(description, CFSTR(kIOPSTimeToFullChargeKey));
				CFIndex timeToCharge;

				if (CFNumberGetValue(timeToChargeNum, kCFNumberCFIndexType, &timeToCharge))
					batteryTime = timeToCharge;
			} else {
				//Not charging
				charging = kCFBooleanFalse;

				CFNumberRef timeToEmptyNum = CFDictionaryGetValue(description, CFSTR(kIOPSTimeToEmptyKey));
				CFIndex timeToEmpty;

				if (CFNumberGetValue(timeToEmptyNum, kCFNumberCFIndexType, &timeToEmpty))
					batteryTime = timeToEmpty;
			}

			/* Capacity */
			CFNumberRef currentCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSCurrentCapacityKey));
			CFNumberRef maxCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSMaxCapacityKey));

			CFIndex currentCapacity, maxCapacity;

			if (CFNumberGetValue(currentCapacityNum, kCFNumberCFIndexType, &currentCapacity) &&
					CFNumberGetValue(maxCapacityNum, kCFNumberCFIndexType, &maxCapacity))
				percentageCapacity = roundf((currentCapacity / (float)maxCapacity) * 100.0f);

		} else {
			//UPS power
			hgPowerSource = HGUPSPower;
		}

		//Avoid sending notifications on the same power source multiple times, unless the charging state or presence/absence of a time estimate has changed.
		if (lastPowerSource != hgPowerSource || lastChargingState != charging || (lastBatteryTime == -1) != (batteryTime == -1)) {
			lastPowerSource = hgPowerSource;
			lastChargingState = charging;
			lastBatteryTime = batteryTime;
			AppController_powerSwitched(hgPowerSource, charging, batteryTime, percentageCapacity);
		}
	}

	CFRelease(powerSourcesList);
	CFRelease(powerBlob);
}

void PowerNotifier_init(void)
{
	powerNotifierRunLoopSource = IOPSNotificationCreateRunLoopSource(powerSourceChanged,
																	 NULL);
	if (powerNotifierRunLoopSource)
		CFRunLoopAddSource(CFRunLoopGetCurrent(), powerNotifierRunLoopSource, kCFRunLoopDefaultMode);

	lastPowerSource = HGUnknownPower;
}

void PowerNotifier_dealloc(void)
{
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), powerNotifierRunLoopSource, kCFRunLoopDefaultMode);
	CFRelease(powerNotifierRunLoopSource);
}
