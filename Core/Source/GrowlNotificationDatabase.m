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
#import "GrowlNotificationHistoryWindow.h"
#import <CoreData/CoreData.h>

@implementation GrowlNotificationDatabase

@synthesize awayDate;
@synthesize notificationsWhileAway;

-(id)initSingleton
{
   if((self = [super initSingleton]))
   {
      notificationsWhileAway = NO;
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

-(NSUInteger)awayHistoryCount
{
   NSError *error = nil;
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notification" 
                                                        inManagedObjectContext:managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
   [request setEntity:entityDescription];
   
   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Time >= %@ AND Time <= %@", awayDate, [NSDate date]];
   [request setPredicate:predicate];
   
   NSUInteger count = [managedObjectContext countForFetchRequest:request error:&error];
   if(error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
   return count;
}

-(NSArray*)mostRecentNotifications:(unsigned int)amount
{
   if(amount == 0)
      amount = 1;
   
   NSError *error = nil;
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notification" 
                                                        inManagedObjectContext:managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
   [request setEntity:entityDescription];
      
   NSSortDescriptor *sortDescription = [[[NSSortDescriptor alloc] initWithKey:@"Time" ascending:NO] autorelease];
   NSArray *sortArray = [NSArray arrayWithObject:sortDescription];
   [request setSortDescriptors:sortArray];
   
   [request setFetchLimit:amount];
   
   NSArray *awayHistory = [managedObjectContext executeFetchRequest:request error:&error];
   if(error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
   return awayHistory;      
}

#pragma mark -
#pragma mark Notification History Maintenance
/* StoreMaintenance cleans out old messages on a timer, either x max, y days old,
 * or whichever comes first depending on user prefrences.  Called only every half hour? need to decide that
 */
-(void)storeMaintenance:(NSTimer*)theTimer
{
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
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
   
   NSError *error = nil;
   [managedObjectContext save:&error];
   if(error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

-(void)trimByDate
{
   NSError *error = nil;
   
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notification"
                                                        inManagedObjectContext:managedObjectContext];
   
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];   
   
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
   [request setEntity:entityDescription];
   
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
   NSLog(@"%d notes older than %@, trimming.", [notes count], trimDate);
   for(NSManagedObject *note in notes)
   {
      [managedObjectContext deleteObject:note];
   }
}

-(void)trimByCount
{
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notification"
                                                        inManagedObjectContext:managedObjectContext];
   
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   
   NSError *error = nil;
   NSFetchRequest *countRequest = [[[NSFetchRequest alloc] init] autorelease];
   [countRequest setEntity:entityDescription];
   
   NSUInteger totalCount = [managedObjectContext countForFetchRequest:countRequest error:&error];
   if(error)
   {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      return;
   }
   NSUInteger countLimit = [preferences growlHistoryCountLimit];
   if (totalCount <= countLimit)
   {
      NSLog(@"Only %d notifications, not trimming", totalCount);
      return;
   }
   
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
   [request setEntity:entityDescription];
   [request setFetchLimit:totalCount - countLimit];
   
   NSSortDescriptor *dateSort = [[[NSSortDescriptor alloc] initWithKey:@"Time" ascending:YES] autorelease];
   [request setSortDescriptors:[NSArray arrayWithObject:dateSort]];
   
   NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
   
   NSLog(@"Found %d notifications, limit is %d, retrieved %d to trim.", totalCount, countLimit, [notes count]);
   if(error)
   {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      return;
   }
   for(NSManagedObject *note in notes)
   {
      [managedObjectContext deleteObject:note];
   }
}

-(void)imageCacheMaintenance
{
   NSError *error = nil;
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Image" 
                                                        inManagedObjectContext:managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
   [request setEntity:entityDescription];
   
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
      NSLog(@"No images to cull found");
      return;
   }
   NSLog(@"Culling %d images from cache", [images count]);
   
   for(NSManagedObject *image in images)
   {
      [managedObjectContext deleteObject:image];
   }
   [managedObjectContext save:&error];
   if(error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);   
}
-(void)userReturnedAndOpenedList
{
   notificationsWhileAway = NO;
}

-(void)userReturnedAndClosedList
{
   notificationsWhileAway = NO;
   NSError *error = nil;
   NSEntityDescription *entityDescriptipn = [NSEntityDescription entityForName:@"Notification" 
                                                        inManagedObjectContext:managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
   [request setEntity:entityDescriptipn];
   
   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deleteUponReturn == %@", [NSNumber numberWithBool:YES]];
   [request setPredicate:predicate];

   NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
   if(error)
   {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      return;
   }
   if([notes count] == 0)
   {
      NSLog(@"No notes which should not be logged permanently");
      return;
   }
   
   NSLog(@"Removing %d notes which should no longer be retained", [notes count]);
   for(NSManagedObject *note in notes)
   {
      [managedObjectContext deleteObject:note];
   }
   [managedObjectContext save:&error];
   if(error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);   
}

@end
