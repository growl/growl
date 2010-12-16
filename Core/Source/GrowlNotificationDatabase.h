//
//  GrowlNotificationDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 8/11/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlAbstractDatabase.h"

#define NOTIFICATION_HISTORY_NOTIFICATION @"Growl Notification History"

@class GrowlNotificationHistoryWindow;

@interface GrowlNotificationDatabase : GrowlAbstractDatabase {
   NSTimer *maintenanceTimer;
   NSDate *lastImageCheck;
   NSDate *awayDate;
   BOOL notificationsWhileAway;
}
@property (readonly) NSDate *awayDate;
@property (readonly) BOOL notificationsWhileAway;

-(NSUInteger)awayHistoryCount;
-(NSArray*)mostRecentNotifications:(unsigned int)amount;

-(void)storeMaintenance:(NSTimer*)theTimer;
-(void)trimByDate;
-(void)trimByCount;
-(void)imageCacheMaintenance;
-(void)userReturnedAndOpenedList;
-(void)userReturnedAndClosedList;

@end
