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
#import <CoreData/CoreData.h>

@implementation GrowlNotificationDatabase

-(id)initSingleton
{
   if((self = [super initSingleton]))
   {
      //TODO: set up if need be scheduled cleaning of the DB.
   }
   return self;
}

-(void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [super dealloc]; 
}

-(NSString*)storePath
{
   return [[GrowlPathUtilities growlSupportDirectory] stringByAppendingPathComponent:@"notifications.history"];
}

-(NSString*)storeType
{
   return @"NotificationHistoryDB";
}

- (void) logNotificationWithDictionary:(NSDictionary *)noteDict whileAway:(BOOL)awayFlag
{
}

-(NSUInteger)historyCountBetween:(NSDate*)start and:(NSDate*)end
{
   NSError *error = nil;
   NSFetchRequest *request = [self fetchRequestForStart:start andEnd:end];
   NSUInteger count = [managedObjectContext countForFetchRequest:request error:&error];
   if(error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
   return count;
}

-(NSArray*)historyArrayBetween:(NSDate*)start and:(NSDate*)end sortByApplication:(BOOL)flag
{
   NSError *error = nil;
   
   NSFetchRequest *request = [self fetchRequestForStart:start andEnd:end];
   
   NSSortDescriptor *dateSort = [[[NSSortDescriptor alloc] initWithKey:@"Time" ascending:NO] autorelease];
   NSArray *sortArray;
   if(flag)
   {
      NSSortDescriptor *appSort = [[NSSortDescriptor alloc] initWithKey:@"ApplicatioName" ascending:NO];
      sortArray = [NSArray arrayWithObjects:appSort, dateSort, nil];
   }else {
      sortArray = [NSArray arrayWithObject:dateSort];
   }

   
   [request setSortDescriptors:sortArray];
   
   NSArray *awayHistory = [managedObjectContext executeFetchRequest:request error:&error];
   if(error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
   return awayHistory;   
}

-(NSFetchRequest*)fetchRequestForStart:(NSDate*)start andEnd:(NSDate*)end
{
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:managedObjectContext];
   NSFetchRequest *request = [[NSFetchRequest alloc] init];
   [request setEntity:entityDescription];
   
   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Time >= %@ AND Time <= %@", start, end];
   [request setPredicate:predicate];
   return [request autorelease];
}

-(NSArray*)mostRecentNotifications:(unsigned int)amount
{
   if(amount == 0)
      amount = 1;
   
   NSError *error = nil;
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:managedObjectContext];
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
-(void)storeMaintenance
{
   //TODO: implement this
}

-(void)userReturnedAndClosedList
{
   //TODO: implement this
}


@end
