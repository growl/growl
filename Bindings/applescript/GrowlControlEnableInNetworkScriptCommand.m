//
//  GrowlControlEnableInNetworkScriptCommand.m
//  Growl
//
//  Created by Daniel Siemer on 8/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlEnableInNetworkScriptCommand.h"

@implementation GrowlControlEnableInNetworkScriptCommand

- (id) performDefaultImplementation {
   
   //we always say yes, because this is not a toggle command
   [[GrowlPreferencesController sharedController] setGrowlServerEnabled:YES];
   
   return nil;
}

@end
