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
@synthesize countLabel;
@synthesize awayDate;

-(id)init
{
   if((self = [super initWithWindowNibName:@"AwayHistoryWindow" owner:self]))
   {
      expanded = NO;
      [[self window] setFrame:NSRectFromCGRect(CGRectMake(0, 0, 397, 60)) display:YES animate:NO];
      [[self window] center];
      [[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
   }
   return self;
}

-(void)dealloc
{
   [historyTable release]; historyTable = nil;
   [arrayController release]; historyTable = nil;
   historyController = nil;
   
   [awayDate release]; awayDate = nil;
   
   [super dealloc];
}

-(void)windowWillLoad
{

}

-(void)windowDidLoad
{
}

-(void)windowDidBecomeKey:(NSNotification *)notification
{
   if(expanded)
      return;
      
   CGRect temp = NSRectToCGRect([[self window] frame]);
   NSInteger oldX = temp.origin.x;
   NSInteger oldY = temp.origin.y;
   NSInteger newX = 0, newY = 0;
   
   newX = oldX - (600 - temp.size.width) / 2;
   newY = oldY - (375 - temp.size.height) / 2;
   
   [[self window] setFrame:NSRectFromCGRect(CGRectMake(newX, newY, 600, 375)) display:YES animate:YES];
   expanded = YES;
}

-(void)windowWillClose:(NSNotification *)notification
{
   [[GrowlNotificationDatabase sharedInstance] userReturnedAndClosedList];
}

-(void)showWindow:(id)sender
{
   [self updateTableView];
   [super showWindow:sender];
}

-(void)updateTableView
{
   NSError *error = nil;
   [arrayController fetchWithRequest:[arrayController defaultFetchRequest] merge:YES error:&error];
   [historyTable noteNumberOfRowsChanged];

   
   if (error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
   
   NSUInteger numberOfNotifications = [[arrayController arrangedObjects] count];
    
   NSString* description;
   
   if(numberOfNotifications == 1)
      description = [NSString stringWithFormat:NSLocalizedString(@"There was %d notification while you were away", nil), numberOfNotifications];
   else
      description = [NSString stringWithFormat:NSLocalizedString(@"There were %d notifications while you were away", nil), numberOfNotifications];
   [[countLabel cell] setStringValue:description];
}

-(void)resetArrayWithDate:(NSDate*)newAway
{   
   self.awayDate = newAway;
   if(expanded)
   {
      [[self window] setFrame:NSRectFromCGRect(CGRectMake(0, 0, 397, 60)) display:YES animate:NO];
      [[self window] center];
      expanded = NO;
   }

   NSError *error = nil;
   [arrayController setFetchPredicate:[NSPredicate predicateWithFormat:@"Time >= %@", awayDate]];
   [arrayController fetchWithRequest:[arrayController defaultFetchRequest] merge:NO error:&error];
   [historyTable noteNumberOfRowsChanged];

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
