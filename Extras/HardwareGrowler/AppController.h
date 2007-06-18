/* AppController */

#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <CoreFoundation/CoreFoundation.h>

#include "PowerNotifier.h"

void AppController_fwDidConnect(CFStringRef deviceName);
void AppController_fwDidDisconnect(CFStringRef deviceName);
void AppController_usbDidConnect(CFStringRef deviceName);
void AppController_usbDidDisconnect(CFStringRef deviceName);
void AppController_bluetoothDidConnect(CFStringRef device);
void AppController_bluetoothDidDisconnect(CFStringRef device);
void AppController_airportConnect(CFStringRef networkName, const unsigned char *bssidBytes);
void AppController_airportDisconnect(CFStringRef networkName);
void AppController_linkUp(CFStringRef description);
void AppController_linkDown(CFStringRef description);
void AppController_ipAcquired(CFStringRef ip, CFStringRef type);
void AppController_ipReleased(void);
void AppController_syncStarted(void);
void AppController_syncFinished(void);
void AppController_powerSwitched(HGPowerSource powerSource, CFBooleanRef isCharging,
								 int batteryTime, int batteryPercentage);

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import <Growl/Growl.h>

void AppController_volumeDidMount(NSString *path);
void AppController_volumeDidUnmount(NSString *path);

@interface AppController : NSObject <GrowlApplicationBridgeDelegate> {
}

- (IBAction) doSimpleHelp:(id)sender;

@end

#endif

#endif
