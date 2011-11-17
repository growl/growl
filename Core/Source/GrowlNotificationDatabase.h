//
//  GrowlNotificationDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 8/11/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlAbstractDatabase.h"

@class GrowlNotificationHistoryWindow;

@interface GrowlNotificationDatabase : GrowlAbstractDatabase {
   NSTimer *maintenanceTimer;
   NSDate *lastImageCheck;
   BOOL notificationsWhileAway;
   GrowlNotificationHistoryWindow *historyWindow;
}
@property (readonly) GrowlNotificationHistoryWindow *historyWindow;
@property (readonly) BOOL notificationsWhileAway;

-(NSArray*)mostRecentNotifications:(unsigned int)amount;

-(void)deleteSelectedObjects:(NSArray*)objects;
-(void)deleteAllHistory;

-(void)storeMaintenance:(NSTimer*)theTimer;
-(void)trimByDate;
-(void)trimByCount;
-(void)imageCacheMaintenance;
-(void)userReturnedAndClosedList;

@end
