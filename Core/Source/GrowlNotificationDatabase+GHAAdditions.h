//
//  GrowlNotificationDatabase+GHAAdditions.h
//  Growl
//
//  Created by Daniel Siemer on 10/5/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlNotificationDatabase.h"

/* These are functions that should not be used outside of GHA
 * Database maintenance functions should be run in one place only, and since GHA is
 * (normally) always running, we set them up to run here.
 *
 * presently the maintenance function stubs are in the main class,
 * but they might move in here once they are written, depending on what they need 
 * access to
 *
 * Additionally, logging requires access to code/classes not needed in GrowlMenu 
 * or whatever else might use the notification database down the line.
 */
@interface GrowlNotificationDatabase (GHAAditions)

-(void)setupMaintenanceTimers;
-(void)logNotificationWithDictionary:(NSDictionary*)noteDict;

-(void)showRollup;
-(void)hideRollup;

@end
