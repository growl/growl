/* AppController */

#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <CoreFoundation/CoreFoundation.h>

#include "PowerNotifier.h"

void AppController_fwDidConnect(CFStringRef deviceName);
void AppController_fwDidDisconnect(CFStringRef deviceName);
void AppController_usbDidConnect(CFStringRef deviceName);
void AppController_usbDidDisconnect(CFStringRef deviceName);
void AppController_bluetoothDidConnect(NSString *device);
void AppController_bluetoothDidDisconnect(NSString *device);
void AppController_airportConnect(CFStringRef networkName, const unsigned char *bssidBytes);
void AppController_airportDisconnect(CFStringRef networkName);
void AppController_linkUp(CFStringRef description);
void AppController_linkDown(CFStringRef description);
void AppController_ipAcquired(CFStringRef ip, CFStringRef type);
void AppController_ipReleased(void);
void AppController_syncStarted(void);
void AppController_syncFinished(void);
void AppController_powerSwitched(HGPowerSource powerSource, CFBooleanRef isCharging,
								 CFIndex batteryTime, CFIndex batteryPercentage);

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import <Growl/Growl.h>
#import "VolumeNotifier.h"
#import "NetworkNotifier.h"

void AppController_volumeDidMount(VolumeInfo *info);
void AppController_volumeDidUnmount(VolumeInfo *info);

@interface AppController : NSObject <GrowlApplicationBridgeDelegate> {
	NetworkNotifier *networkNotifier;
}

- (IBAction) doSimpleHelp:(id)sender;

@end

#endif

#endif
