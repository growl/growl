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
#import "GrowlHistoryWindowNotificationCell.h"
#import "GrowlPathUtilities.h"

#define GROWL_ROLLUP_WINDOW_HEIGHT @"GrowlRollupWindowHeight"
#define GROWL_ROLLUP_WINDOW_WIDTH @"GrowlRollupWindowWidth"

#define GROWL_ROLLUP_MIN_WINDOW_WIDTH 600
#define GROWL_ROLLUP_MIN_WINDOW_HEIGHT 350

#define GROWL_ROLLUP_SMALL_WINDOW_WIDTH 400
#define GROWL_ROLLUP_SMALL_WINDOW_HEIGHT 263
#define GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT 63
#define GROWL_ROLLUP_ROW_HEIGHT 37

@implementation GrowlNotificationHistoryWindow

@synthesize historyTable;
@synthesize arrayController;
@synthesize countLabel;
@synthesize storage;
@synthesize countView;
@synthesize searchView;
@synthesize dateColumn;
@synthesize notificationColumn;
@synthesize headerView;
@synthesize awayDate;

-(id)init
{
   if((self = [super initWithWindowNibName:@"AwayHistoryWindow" owner:self]))
   {
      expanded = NO;
      currentlyShown = NO;
      [[self window] setFrame:NSMakeRect(0, 0, GROWL_ROLLUP_SMALL_WINDOW_WIDTH, GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + GROWL_ROLLUP_ROW_HEIGHT) display:YES animate:NO];
      [[self window] setMaxSize:NSMakeSize(GROWL_ROLLUP_SMALL_WINDOW_WIDTH, GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + GROWL_ROLLUP_ROW_HEIGHT)];
      [[self window] center];
      [[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
      [(NSPanel*)[self window] setFloatingPanel:YES];
      [(NSPanel*)[self window] setBecomesKeyOnlyIfNeeded:YES];
      
      [[GrowlNotificationDatabase sharedInstance] setUpdateDelegate:self];
      
      NSInteger height = [[GrowlPreferencesController sharedController] integerForKey:GROWL_ROLLUP_WINDOW_HEIGHT];
      NSInteger width = [[GrowlPreferencesController sharedController] integerForKey:GROWL_ROLLUP_WINDOW_WIDTH];
      if(width < GROWL_ROLLUP_MIN_WINDOW_WIDTH)
         width = GROWL_ROLLUP_MIN_WINDOW_WIDTH;
      if(height < GROWL_ROLLUP_MIN_WINDOW_HEIGHT)
         height = GROWL_ROLLUP_MIN_WINDOW_HEIGHT;
      
      expandSize = NSMakeSize(width, height);
      
      [historyTable setDoubleAction:@selector(userDoubleClickedNote:)];
      GrowlHistoryWindowNotificationCell *noteCell = [[[GrowlHistoryWindowNotificationCell alloc] init] autorelease];
      [notificationColumn setDataCell:noteCell];
      [historyTable setHeaderView:nil];
      [historyTable sizeLastColumnToFit];
   }
   return self;
}

-(void)dealloc
{
   [historyTable release]; historyTable = nil;
   [arrayController release]; historyTable = nil;
   historyController = nil;
   
   [awayDate release]; awayDate = nil;
   [countView release]; countView = nil;
   [searchView release]; searchView = nil;
   
   [super dealloc];
}

-(void)windowDidBecomeKey:(NSNotification *)notification
{
   if(expanded)
      return;
   
   [self updateTableView:NO];
   
   NSRect temp = [[self window] frame];
   NSInteger oldX = temp.origin.x;
   NSInteger oldY = temp.origin.y;
   NSInteger newX = 0, newY = 0;
   
   newX = oldX - (expandSize.width - temp.size.width) / 2;
   newY = oldY - (expandSize.height - temp.size.height) / 2;
   
   [historyTable setHeaderView:headerView];
   [historyTable addTableColumn:dateColumn];
   [historyTable sizeLastColumnToFit];
   
   [searchView setFrame:[storage frame]];
   [[storage animator] replaceSubview:countView with:searchView];
   
   [[self window] setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
   [[self window] setFrame:NSMakeRect(newX, newY, expandSize.width, expandSize.height) 
                  display:YES 
                  animate:YES];
   [[self window] setMinSize:NSMakeSize(GROWL_ROLLUP_MIN_WINDOW_WIDTH, GROWL_ROLLUP_MIN_WINDOW_HEIGHT)];
   expanded = YES;
}

-(void)shrinkWindow
{
   if(!expanded)
      return;
   
   [historyTable setHeaderView:nil];
   [historyTable removeTableColumn:dateColumn];
   [historyTable sizeLastColumnToFit];
   expandSize = [[self window] frame].size;
   [[GrowlPreferencesController sharedController] setInteger:expandSize.height 
                                                      forKey:GROWL_ROLLUP_WINDOW_HEIGHT];
   [[GrowlPreferencesController sharedController] setInteger:expandSize.width 
                                                      forKey:GROWL_ROLLUP_WINDOW_WIDTH];
   
   NSRect temp = [[self window] frame];
   NSInteger oldX = temp.origin.x;
   NSInteger oldY = temp.origin.y;
   NSInteger newX = 0, newY = 0;
   NSInteger rows = [[arrayController arrangedObjects] count];
   NSInteger heightRows = GROWL_ROLLUP_ROW_HEIGHT * ((rows > 5) ? 5 : rows);
   
   newX = oldX + (temp.size.width - GROWL_ROLLUP_SMALL_WINDOW_WIDTH) / 2;
   newY = oldY + (temp.size.height - (GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows)) / 2;
   
   [countView setFrame:[storage frame]];
   [[storage animator] replaceSubview:searchView with:countView];
   [[self window] setMinSize:NSMakeSize(GROWL_ROLLUP_SMALL_WINDOW_WIDTH, (GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows))];
   [[self window] setFrame:NSMakeRect(newX, newY, GROWL_ROLLUP_SMALL_WINDOW_WIDTH, (GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows)) display:YES animate:YES];
   [[self window] setMaxSize:NSMakeSize(GROWL_ROLLUP_SMALL_WINDOW_WIDTH, (GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows))];
   expanded = NO;
}

-(void)windowWillClose:(NSNotification *)notification
{
   [[GrowlNotificationDatabase sharedInstance] userReturnedAndClosedList];
   [self shrinkWindow];
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
   
   if(numberOfNotifications == 0){
      /* No sense keeping the window around, likely the user deleted all the notes that happened while away */
      [[self window] performClose:self];
      return;
   } else if(numberOfNotifications == 1){
      description = [NSString stringWithFormat:NSLocalizedString(@"There was %d notification while you were away", nil), numberOfNotifications];
   } else {
      description = [NSString stringWithFormat:NSLocalizedString(@"There were %d notifications while you were away", nil), numberOfNotifications];
   }
   
   [[countLabel cell] setStringValue:description];
   
   if(numberOfNotifications > 5)
      [(NSScrollView*)[[historyTable superview] superview] setHasVerticalScroller:YES];
   else 
      [(NSScrollView*)[[historyTable superview] superview] setHasVerticalScroller:NO];

   if(expanded)
      return;
   NSRect temp = [[self window] frame];
   NSInteger oldY = temp.origin.y;
   NSInteger newY = 0;
   
   NSInteger heightRows = GROWL_ROLLUP_ROW_HEIGHT * ((numberOfNotifications > 5) ? 5 : numberOfNotifications);
   
   newY = oldY - ((GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows) - temp.size.height) / 2;
   
   [[self window] setMinSize:NSMakeSize(GROWL_ROLLUP_SMALL_WINDOW_WIDTH, (GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows))];
   [[self window] setFrame:NSMakeRect(temp.origin.x, newY, GROWL_ROLLUP_SMALL_WINDOW_WIDTH, (GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows)) display:YES animate:YES];
   [[self window] setMaxSize:NSMakeSize(GROWL_ROLLUP_SMALL_WINDOW_WIDTH, (GROWL_ROLLUP_SMALL_WINDOW_BASE_HEIGHT + heightRows))];
   expanded = NO;
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
      GrowlHistoryWindowNotificationCell *cell = (GrowlHistoryWindowNotificationCell*)[aTableColumn dataCellForRow:rowIndex];
      [cell setNote:[[arrayController arrangedObjects] objectAtIndex:rowIndex]];
   }
	return nil;
}
#pragma mark -
#pragma mark GrowlDatabaseUpdateDelegate methods

-(BOOL)CanGrowlDatabaseHardReset:(GrowlAbstractDatabase*)db
{
   return NO;
}

-(void)GrowlDatabaseDidUpdate:(GrowlAbstractDatabase*)db
{
   [self updateTableView:NO];
}

@end
