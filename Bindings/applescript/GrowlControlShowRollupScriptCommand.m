//
//  GrowlControlShowRollupScriptCommand.m
//  Growl
//
//  Created by Rudy Richter on 9/3/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlShowRollupScriptCommand.h"
#import "GrowlPreferencesController.h"

@implementation GrowlControlShowRollupScriptCommand

- (id) performDefaultImplementation {
    
    //we always say yes, because this is not a toggle command
    [[GrowlPreferencesController sharedInstance] setRollupShown:YES];
    
    return nil;
}


@end
