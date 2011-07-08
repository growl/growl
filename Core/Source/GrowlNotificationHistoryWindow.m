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
#import "GrowlApplicationController.h"
#import "GrowlPathUtilities.h"

#define GROWL_ROLLUP_WINDOW_HEIGHT @"GrowlRollupWindowHeight"
#define GROWL_ROLLUP_WINDOW_WIDTH @"GrowlRollupWindowWidth"

#define GROWL_ROLLUP_MIN_WINDOW_WIDTH 600
#define GROWL_ROLLUP_MIN_WINDOW_HEIGHT 350

#define GROWL_ROLLUP_SMALL_WINDOW_WIDTH 400
#define GROWL_ROLLUP_SMALL_WINDOW_HEIGHT 263
#define GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT 63

@implementation GrowlNotificationHistoryWindow

@synthesize historyTable;
@synthesize arrayController;
@synthesize countLabel;
@synthesize notificationColumn;
@synthesize awayDate;

-(id)init
{
   if((self = [super initWithWindowNibName:@"AwayHistoryWindow" owner:self]))
   {
      currentlyShown = NO;
      [[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
      [(NSPanel*)[self window] setFloatingPanel:YES];
      
       NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];       
       GrowlNotificationDatabase *db = [GrowlNotificationDatabase sharedInstance];
       [nc addObserver:self 
              selector:@selector(growlDatabaseDidUpdate:) 
                  name:@"GrowlDatabaseUpdated"
                object:db];
      
      NSInteger height = [[GrowlPreferencesController sharedController] integerForKey:GROWL_ROLLUP_WINDOW_HEIGHT];
      NSInteger width = [[GrowlPreferencesController sharedController] integerForKey:GROWL_ROLLUP_WINDOW_WIDTH];
      if(width < GROWL_ROLLUP_MIN_WINDOW_WIDTH)
         width = GROWL_ROLLUP_MIN_WINDOW_WIDTH;
      if(height < GROWL_ROLLUP_MIN_WINDOW_HEIGHT)
         height = GROWL_ROLLUP_MIN_WINDOW_HEIGHT;
      
      expandSize = NSMakeSize(width, height);
      
      [historyTable setDoubleAction:@selector(userDoubleClickedNote:)];
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

-(void)windowWillClose:(NSNotification *)notification
{
   [[GrowlNotificationDatabase sharedInstance] userReturnedAndClosedList];
   currentlyShown = NO;
}

-(void)showWindow:(id)sender
{
   [self updateTableView:NO];
   [super showWindow:sender];
}

-(void)updateTableView:(BOOL)willMerge
{
   if(!currentlyShown)
      return;

   NSError *error = nil;
   [arrayController fetchWithRequest:[arrayController defaultFetchRequest] merge:willMerge error:&error];
   [historyTable noteNumberOfRowsChanged];
   
   if (error)
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
   
   NSUInteger numberOfNotifications = [[arrayController arrangedObjects] count];
    
   NSString* description;
   
   if(numberOfNotifications == 1){
      description = [NSString stringWithFormat:NSLocalizedString(@"There was %d notification while you were away", nil), numberOfNotifications];
   } else {
      description = [NSString stringWithFormat:NSLocalizedString(@"There were %d notifications while you were away", nil), numberOfNotifications];
   }

    [countLabel setObjectValue:description];
}

-(void)resetArrayWithDate:(NSDate*)newAway
{   
   self.awayDate = newAway;
   [[self window] center];
   
   currentlyShown = YES;
   [arrayController setFetchPredicate:[NSPredicate predicateWithFormat:@"Time >= %@", awayDate]];
   [self updateTableView:NO];
   [self showWindow:self];
}

-(IBAction)userDoubleClickedNote:(id)sender
{
   if([arrayController selectionIndex] != NSNotFound)
   {
      GrowlHistoryNotification *note = [[arrayController arrangedObjects] objectAtIndex:[arrayController selectionIndex]];
      [[GrowlApplicationController sharedInstance] growlNotificationDict:[note GrowlDictionary] didCloseViaNotificationClick:YES onLocalMachine:YES];
   }
}

-(IBAction)openFullLog:(id)sender
{
   [[GrowlPreferencesController sharedController] setSelectedPreferenceTab:4];   
   NSString *prefPane = [[GrowlPathUtilities growlPrefPaneBundle] bundlePath];
	[[NSWorkspace sharedWorkspace] openFile:prefPane];
}

-(GrowlNotificationDatabase*)historyController
{
   if(!historyController)
      historyController = [GrowlNotificationDatabase sharedInstance];
      
   return historyController;
}

#pragma mark TableView Data source methods

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
   if(aTableColumn == notificationColumn){
      return [[arrayController arrangedObjects] objectAtIndex:rowIndex];
   }
	return nil;
}
#pragma mark -
#pragma mark GrowlDatabaseUpdateDelegate methods

-(void)growlDatabaseDidUpdate:(NSNotification*)notification
{
   [self updateTableView:NO];
}

@end
