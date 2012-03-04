//
//  GrowlActionPlugin.h
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlPlugin.h>

@interface GrowlActionPlugin : GrowlPlugin

-(BOOL)requiresMainThread;
-(NSDictionary*)requiredEntitlements;

@end
