//
//  GrowlBoxcarAction.h
//  Boxcar
//
//  Created by Daniel Siemer on 3/19/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <GrowlPlugins/GrowlActionPlugin.h>

@interface GrowlBoxcarAction : GrowlActionPlugin <GrowlDispatchNotificationProtocol, GrowlUpgradePluginPrefsProtocol, NSURLConnectionDelegate>

@end
