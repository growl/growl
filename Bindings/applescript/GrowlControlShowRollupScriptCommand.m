//
//  GrowlControlShowRollupScriptCommand.m
//  Growl
//
//  Created by Rudy Richter on 9/3/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlShowRollupScriptCommand.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlNotificationDatabase+GHAAdditions.h"

@implementation GrowlControlShowRollupScriptCommand

- (id) performDefaultImplementation {
    
    //we always say yes, because this is not a toggle command
    [[GrowlNotificationDatabase sharedInstance] showRollup];
    
    return nil;
}


@end
