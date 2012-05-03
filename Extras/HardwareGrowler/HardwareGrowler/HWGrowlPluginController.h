//
//  HWGrowlPluginController.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Growl/Growl.h>
#import "HardwareGrowlPlugin.h"

@interface HWGrowlPluginController : NSObject <HWGrowlPluginControllerProtocol, GrowlApplicationBridgeDelegate>

-(void)loadPlugins;

@end
