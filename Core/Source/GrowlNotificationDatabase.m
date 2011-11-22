//
//  GrowlNotificationDatabase.m
//  Growl
//
//  Created by Daniel Siemer on 8/11/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlNotificationDatabase.h"
#import "GrowlPreferencesController.h"
#import "GrowlDefines.h"
#import "GrowlHistoryNotification.h"
#import "GrowlPathUtilities.h"
#import "GrowlTicketController.h"
#import "GrowlApplicationTicket.h"
#import "GrowlNotificationTicket.h"
#import "GrowlNotificationDatabase+GHAAdditions.h"
#import "GrowlNotificationHistoryWindow.h"
#import <CoreData/CoreData.h>

@implementation GrowlNotificationDatabase

@synthesize historyWindow;
@synthesize notificationsWhileAway;

-(id)initSingleton
{
   if((self = [super initSingleton]))
   {      
      GrowlNotificationHistoryWindow *window = [[GrowlNotificationHistoryWindow alloc] init];
      historyWindow = [window retain];
      [window release];
      [historyWindow window];
      [historyWindow resetArray];
      
      notificationsWhileAway = NO;
      if([[GrowlPreferencesController sharedInstance] isRollupShown])
         [self showRollup];
   }
   return self;
}

-(void)destroy
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [maintenanceTimer invalidate];
   [maintenanceTimer release]; maintenanceTimer = nil;
   [lastImageCheck release]; lastImageCheck = nil;
   [super destroy]; 
}

-(NSString*)storePath
{
   return [[GrowlPathUtilities growlSupportDirectory] stringByAppendingPathComponent:@"notifications.history"];
}

-(NSString*)storeType
{
   return @"NotificationHistoryDB";
}

-(NSString*)modelName
{
   return @"GrowlNotificationHistory";
}

-(NSArray*)mostRecentNotifications:(unsigned int)amount
{
   if(amount == 0)
      amount = 1;
   
   NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Notification"] autorelease];
      
   NSSortDescriptor *sortDescription = [[[NSSortDescriptor alloc] initWithKey:@"Time" ascending:NO] autorelease];
   NSArray *sortArray = [NSArray arrayWithObject:sortDescription];
   [request setSortDescriptors:sortArray];
   
   [request setFetchLimit:amount];
   
    __block NSArray *awayHistory = nil;
    void (^recentBlock)(void) = ^{
        NSError *error = nil;
        awayHistory = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    };
    if(![[NSThread currentThread] isMainThread])
        [managedObjectContext performBlockAndWait:recentBlock];
    else
        recentBlock();
   return awayHistory;      
}

#pragma mark -
-(void)deleteSelectedObjects:(NSArray*)objects
{
    void (^deleteBlock)(void) = ^{
        NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Notification"] autorelease];
        NSError *error = nil;
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return;
        }
        
        for(NSManagedObject *note in notes)
        {
            if([objects containsObject:note])
                [managedObjectContext deleteObject:note];
        }
    };
    if(![[NSThread currentThread] isMainThread])
        [managedObjectContext performBlock:deleteBlock];
    else
        deleteBlock();
    [self saveDatabase:NO];
}
-(void)deleteAllHistory
{
    void (^deleteBlock)(void) = ^{
        NSError *error = nil;
        NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Notification"] autorelease];
        
        NSArray *notes = [[self managedObjectContext] executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return;
        }
        
        NSLog(@"Deleting Entire History");
        for(NSManagedObject *note in notes)
        {
            [[self managedObjectContext] deleteObject:note];
        }
    };
    if(![[NSThread currentThread] isMainThread])
        [managedObjectContext performBlock:deleteBlock];
    else
        deleteBlock();
    [self saveDatabase:NO];
}

#pragma mark -
#pragma mark Notification History Maintenance
/* StoreMaintenance cleans out old messages on a timer, either x max, y days old,
 * or whichever comes first depending on user prefrences.  Called only every half hour? need to decide that
 */
-(void)storeMaintenance:(NSTimer*)theTimer
{
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   
   if(![preferences isGrowlHistoryTrimByDate] && ![preferences isGrowlHistoryTrimByCount])
   {
      NSLog(@"Setting trimByDate since both have been turned off outside of the UI");
      [preferences setGrowlHistoryTrimByDate:YES];
   }
   
   if([preferences isGrowlHistoryTrimByDate])
   {
      [self trimByDate];
   }
   
   if([preferences isGrowlHistoryTrimByCount])
   {
      [self trimByCount];
   }
   
   if(!lastImageCheck || [[NSDate date] timeIntervalSinceDate:lastImageCheck] > 3600 * 24)
   {
      [self imageCacheMaintenance];
      if(lastImageCheck)
         [lastImageCheck release];
      lastImageCheck = [[NSDate date] retain];
   }
   [self saveDatabase:NO];
}

-(void)trimByDate
{
    [managedObjectContext performBlock:^(void) {
        NSError *error = nil;
        
        GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];   
        
        NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Notification"] autorelease];
        
        NSSortDescriptor *dateSort = [[[NSSortDescriptor alloc] initWithKey:@"Time" ascending:NO] autorelease];
        [request setSortDescriptors:[NSArray arrayWithObject:dateSort]];
        
        NSInteger trimDays = -[preferences growlHistoryDayLimit];
        NSDate *trimDate = [[NSCalendarDate date] dateByAddingYears:0 months:0 days:trimDays hours:0 minutes:0 seconds:0];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Time <= %@", trimDate];
        [request setPredicate:predicate];
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return;
        }
        
        for(NSManagedObject *note in notes)
        {
            [managedObjectContext deleteObject:note];
        }
    }];
}

-(void)trimByCount
{
    [managedObjectContext performBlock:^(void) {
        GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
        
        NSError *error = nil;
        NSFetchRequest *countRequest = [[[NSFetchRequest alloc] initWithEntityName:@"Notification"] autorelease];
        
        NSUInteger totalCount = [managedObjectContext countForFetchRequest:countRequest error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return;
        }
        NSUInteger countLimit = [preferences growlHistoryCountLimit];
        if (totalCount <= countLimit)
        {
            return;
        }
        
        NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Notification"] autorelease];
        [request setFetchLimit:totalCount - countLimit];
        
        NSSortDescriptor *dateSort = [[[NSSortDescriptor alloc] initWithKey:@"Time" ascending:YES] autorelease];
        [request setSortDescriptors:[NSArray arrayWithObject:dateSort]];
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return;
        }
        for(NSManagedObject *note in notes)
        {
            [managedObjectContext deleteObject:note];
        }
    }];
}

-(void)imageCacheMaintenance
{
    [managedObjectContext performBlock:^(void) {
        NSError *error = nil;
        NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Image"] autorelease];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY Notifications == nil"];
        [request setPredicate:predicate];
        
        NSArray *images = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return;
        }
        
        if([images count] == 0)
        {
            return;
        }
        
        for(NSManagedObject *image in images)
        {
            [managedObjectContext deleteObject:image];
        }
    }];
}

-(void)userReturnedAndClosedList
{
    notificationsWhileAway = NO;
    
    [managedObjectContext performBlock:^(void) {
        NSError *error = nil;
        NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Notification"] autorelease];
        NSNumber *boolYES = [NSNumber numberWithBool:YES];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(deleteUponReturn == %@) OR (showInRollup == %@)", boolYES, boolYES];
        [request setPredicate:predicate];
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return;
        }
        
        for(GrowlHistoryNotification *note in notes)
        {
            if([[note deleteUponReturn] boolValue])
                [managedObjectContext deleteObject:note];
            else
                [note setShowInRollup:[NSNumber numberWithBool:NO]];
        }        
    }];
    [self saveDatabase:NO];
}

@end
