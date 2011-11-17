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

@interface AppController : NSObject <NSApplicationDelegate, GrowlApplicationBridgeDelegate> {
	NetworkNotifier *networkNotifier;
	IBOutlet NSMenu* statusMenu;
	NSStatusItem* statusItem;
	IBOutlet NSMenuItem *mainItem;
	IBOutlet NSMenu *submenu;
	NSString* showDevicesTitle;
	NSString* groupNetworkTitle;
	NSString* moveToMenuTitle;
	NSString* moveToDockTitle;
	NSString* quitTitle;
	NSString* preferencesTitle;
	NSString* openPreferencesTitle;
	NSString* iconTitle;
    NSWindow *prefsWindow;
    NSArray *iconOptions;
    NSSegmentedControl *onLoginSegmentedControl;
    NSPopUpButton *iconPopUp;
    
    NSInteger oldIconValue;
    NSInteger oldOnLoginValue;
}

@property  (nonatomic, retain) NSString* showDevices;
@property  (nonatomic, retain) NSString* groupNetworkTitle;
@property  (nonatomic, retain) NSString* quitTitle;
@property  (nonatomic, retain) NSString* preferencesTitle;
@property  (nonatomic, retain) NSString* openPreferencesTitle;
@property  (nonatomic, retain) NSString* iconTitle;
@property  (nonatomic, assign) IBOutlet NSWindow *prefsWindow;
@property  (nonatomic, assign) IBOutlet NSSegmentedControl *onLoginSegmentedControl;
@property (nonatomic, assign) IBOutlet NSPopUpButton *iconPopUp;

@property (nonatomic, retain) NSArray *iconOptions;
- (IBAction)showPreferences:(id)sender;

- (void) initMenu;
- (IBAction) doSimpleHelp:(id)sender;
- (BOOL) isEnabled: (CFStringRef) type;
- (void) initTitles;
- (void)expiryCheck;
- (void)warnUserAboutIcons;
- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled;

@end

#endif

#endif
