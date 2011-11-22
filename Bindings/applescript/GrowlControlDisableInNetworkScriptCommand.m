//
//  GrowlControlDisableInNetworkScriptCommand.m
//  Growl
//
//  Created by Daniel Siemer on 8/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlDisableInNetworkScriptCommand.h"

@implementation GrowlControlDisableInNetworkScriptCommand

- (id) performDefaultImplementation {
   
   //we always say no, because this is not a toggle command
   [[GrowlPreferencesController sharedController] setGrowlServerEnabled:NO];
   
   return nil;
}


@end
