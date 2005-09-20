/* AppController */

#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <CoreFoundation/CoreFoundation.h>

void AppController_fwDidConnect(CFStringRef deviceName);
void AppController_fwDidDisconnect(CFStringRef deviceName);
void AppController_usbDidConnect(CFStringRef deviceName);
void AppController_usbDidDisconnect(CFStringRef deviceName);
void AppController_bluetoothDidConnect(CFStringRef device);
void AppController_bluetoothDidDisconnect(CFStringRef device);
void AppController_volumeDidMount(CFStringRef name, CFStringRef path);
void AppController_volumeDidUnmount(CFStringRef name);
void AppController_airportConnect(CFStringRef networkName, const unsigned char *bssidBytes);
void AppController_airportDisconnect(CFStringRef networkName);
void AppController_linkUp(CFStringRef description);
void AppController_linkDown(CFStringRef description);
void AppController_ipAcquired(CFStringRef ip);
void AppController_ipReleased(void);
void AppController_syncStarted(void);
void AppController_syncFinished(void);

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import <Growl/Growl.h>

@interface AppController : NSObject <GrowlApplicationBridgeDelegate> {
}

- (IBAction) doSimpleHelp:(id)sender;

@end

#endif

#endif
