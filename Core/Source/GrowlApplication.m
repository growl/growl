//
//  GrowlApplication.m
//  Growl
//
//  Created by Evan Schoenberg on 5/10/07.
//

#import "GrowlApplication.h"

@implementation GrowlApplication

- (BOOL)paused
{
    return [[GrowlPreferencesController sharedController] squelchMode];
}

- (BOOL)allowsIncomingNetwork
{
   return [[GrowlPreferencesController sharedController] isGrowlServerEnabled];
}

@end
