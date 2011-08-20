//
//  GrowlControlPauseScriptCommand.m
//  Growl
//
//  Created by Rudy Richter on 8/18/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlPauseScriptCommand.h"
#import "GrowlPreferencesController.h"

@implementation GrowlControlPauseScriptCommand

- (id) performDefaultImplementation {

    //we always say yes, because this is not a toggle command
    [[GrowlPreferencesController sharedController] setSquelchMode:YES];
    
    return nil;
}

@end
