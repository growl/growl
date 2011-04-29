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

#define GROWL_ROLLUP_WINDOW_HEIGHT @"GrowlRollupWindowHeight"
#define GROWL_ROLLUP_WINDOW_WIDTH @"GrowlRollupWindowWidth"

#define GROWL_ROLLUP_MIN_WINDOW_WIDTH 600
#define GROWL_ROLLUP_MIN_WINDOW_HEIGHT 350

@implementation GrowlNotificationHistoryWindow

@synthesize historyTable;
@synthesize arrayController;
@synthesize countLabel;
@synthesize storage;
@synthesize listAndDetails;
@synthesize awayDate;

-(id)init
{
   if((self = [super initWithWindowNibName:@"AwayHistoryWindow" owner:self]))
   {
      expanded = NO;
      [[self window] setFrame:NSMakeRect(0, 0, 400, 60) display:YES animate:NO];
      [[self window] setMaxSize:NSMakeSize(400, 60)];
      [[self window] center];
      [[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
      [(NSPanel*)[self window] setFloatingPanel:YES];
      [(NSPanel*)[self window] setBecomesKeyOnlyIfNeeded:YES];
      
      NSInteger height = [[GrowlPreferencesController sharedController] integerForKey:GROWL_ROLLUP_WINDOW_HEIGHT];
      NSInteger width = [[GrowlPreferencesController sharedController] integerForKey:GROWL_ROLLUP_WINDOW_WIDTH];
      if(width < GROWL_ROLLUP_MIN_WINDOW_WIDTH)
         width = GROWL_ROLLUP_MIN_WINDOW_WIDTH;
      if(height < GROWL_ROLLUP_MIN_WINDOW_HEIGHT)
         height = GROWL_ROLLUP_MIN_WINDOW_HEIGHT;
      
      expandSize = NSMakeSize(width, height);
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

-(void)windowDidBecomeKey:(NSNotification *)notification
{
   if(expanded)
      return;
   
   NSError *error = nil;
   [arrayController fetchWithRequest:[arrayController defaultFetchRequest] merge:NO error:&error];
   [self updateTableView];
   if (error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
   
   NSRect temp = [[self window] frame];
   NSInteger oldX = temp.origin.x;
   NSInteger oldY = temp.origin.y;
   NSInteger newX = 0, newY = 0;
   
   newX = oldX - (expandSize.width - temp.size.width) / 2;
   newY = oldY - (expandSize.height - temp.size.height) / 2;
   
   [[self window] setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
   [[self window] setFrame:NSMakeRect(newX, newY, expandSize.width, expandSize.height) 
                  display:YES 
                  animate:YES];
   [[self window] setMinSize:NSMakeSize(GROWL_ROLLUP_MIN_WINDOW_WIDTH, GROWL_ROLLUP_MIN_WINDOW_HEIGHT)];
   [[storage animator] addSubview:listAndDetails];
   [listAndDetails setFrame:storage.frame];
   
   expanded = YES;
}

-(void)shrinkWindow
{
   if(expanded)
   {
      [listAndDetails removeFromSuperview];
      expandSize = [[self window] frame].size;
      [[GrowlPreferencesController sharedController] setInteger:expandSize.height 
                                                         forKey:GROWL_ROLLUP_WINDOW_HEIGHT];
      [[GrowlPreferencesController sharedController] setInteger:expandSize.width 
                                                         forKey:GROWL_ROLLUP_WINDOW_WIDTH];
      [[self window] setMinSize:NSMakeSize(400, 60)];
      [[self window] setFrame:NSMakeRect(0, 0, 400, 60) display:YES animate:NO];
      [[self window] setMaxSize:NSMakeSize(400, 60)];
      [[self window] center];
      expanded = NO;
   }
}

-(void)windowWillClose:(NSNotification *)notification
{
   [[GrowlNotificationDatabase sharedInstance] userReturnedAndClosedList];
   [self shrinkWindow];
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
   [self shrinkWindow];

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
