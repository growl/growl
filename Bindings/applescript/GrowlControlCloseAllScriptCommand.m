//
//  GrowlControlCloseAllScriptCommand.m
//  Growl
//
//  Created by Rudy Richter on 8/19/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlControlCloseAllScriptCommand.h"

@implementation GrowlControlCloseAllScriptCommand

- (id) performDefaultImplementation {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_ALL_NOTIFICATIONS
                                                        object:nil];
    
    return nil;
}

@end
