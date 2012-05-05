//
//  GrowlControlResumeScriptCommand.m
//  Growl
//
//  Created by Rudy Richter on 8/18/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlResumeScriptCommand.h"
#import "GrowlPreferencesController.h"

@implementation GrowlControlResumeScriptCommand

- (id) performDefaultImplementation {
    
    //we always say yes, because this is not a toggle command
    [[GrowlPreferencesController sharedController] setSquelchMode:NO];
    
    return nil;
}

@end
