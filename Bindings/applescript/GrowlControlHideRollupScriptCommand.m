//
//  GrowlControlHideRollupScriptCommand.m
//  Growl
//
//  Created by Rudy Richter on 9/3/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlHideRollupScriptCommand.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlNotificationDatabase+GHAAdditions.h"

@implementation GrowlControlHideRollupScriptCommand

- (id) performDefaultImplementation {
    
    //we always say yes, because this is not a toggle command
    [[GrowlNotificationDatabase sharedInstance] hideRollup];
    
    return nil;
}


@end
