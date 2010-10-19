//
//  GrowlNotificationHistoryWindow.m
//  Growl
//
//  Created by Daniel Siemer on 9/2/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlNotificationHistoryWindow.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlHistoryNotification.h"

@implementation GrowlNotificationHistoryWindow

@synthesize historyTable;
@synthesize arrayController;
@synthesize awayDate;
@synthesize returnDate;

-(id)init
{
   if((self = [super initWithWindowNibName:@"AwayHistoryWindow" owner:self]))
   {

   }
   return self;
}

-(void)windowWillLoad
{

}

-(void)windowDidLoad
{
}


-(void)windowWillClose:(NSNotification *)notification
{
   [[GrowlNotificationDatabase sharedInstance] userReturnedAndClosedList];
}

-(void)showWindow:(id)sender
{
   [historyTable noteNumberOfRowsChanged];
   [super showWindow:sender];
}

-(void)setAwayDate:(NSDate*)newAway returnDate:(NSDate*)newReturn
{
   self.awayDate = newAway;
   self.returnDate = newReturn;

   NSError *error = nil;
   [arrayController setFetchPredicate:[NSPredicate predicateWithFormat:@"Time >= %@ AND Time <= %@", awayDate, returnDate]];
   [arrayController fetchWithRequest:[arrayController defaultFetchRequest] merge:NO error:&error];
   if (error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

-(GrowlNotificationDatabase*)historyController
{
   if(!historyController)
      historyController = [GrowlNotificationDatabase sharedInstance];
      
   return historyController;
}

#pragma mark -
#pragma mark GrowlDatabaseUpdateDelegate methods

-(BOOL)CanGrowlDatabaseHardReset:(GrowlAbstractDatabase*)db
{
   return NO;
}

-(void)GrowlDatabaseDidUpdate:(GrowlAbstractDatabase*)db
{

}

@end
