//
//  HWGrowlPhoneMonitor.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 6/6/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "HardwareGrowlPlugin.h"

@interface HWGrowlPhoneMonitor : NSObject <HWGrowlPluginProtocol, HWGrowlPluginNotifierProtocol, IOBluetoothHandsFreeDelegate, IOBluetoothHandsFreeDeviceDelegate>

@end
