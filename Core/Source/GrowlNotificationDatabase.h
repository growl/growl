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
}

-(NSUInteger)historyCountBetween:(NSDate*)start and:(NSDate*)end;
-(NSArray*)historyArrayBetween:(NSDate*)start and:(NSDate*)end sortByApplication:(BOOL)flag;
-(NSFetchRequest*)fetchRequestForStart:(NSDate*)start andEnd:(NSDate*)end;
-(NSArray*)mostRecentNotifications:(unsigned int)amount;

-(void)userReturnedAndClosedList;

@end
