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
#import "GrowlTicketController.h"
#import "GrowlApplication.h"
#import "GrowlPathUtilities.h"
#import "GrowlNotificationCellView.h"
#import "GrowlNotificationRowView.h"
#import "GrowlRollupGroupCellView.h"
#import "GroupedArrayController.h"
#import "GroupController.h"

#define GROWL_ROLLUP_WINDOW_HEIGHT @"GrowlRollupWindowHeight"
#define GROWL_ROLLUP_WINDOW_WIDTH @"GrowlRollupWindowWidth"

#define GROWL_DESCRIPTION_WIDTH_PAD 42.0
#define GROWL_DESCRIPTION_HEIGHT_PAD 28.0
#define GROWL_ROW_MINIMUM_HEIGHT 50.0

@implementation GrowlNotificationHistoryWindow

@synthesize historyTable;
@synthesize countLabel;
@synthesize notificationColumn;

-(id)init
{
   if((self = [super initWithWindowNibName:@"AwayHistoryWindow" owner:self]))
   {
      currentlyShown = NO;
      [[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
      [(NSPanel*)[self window] setFloatingPanel:YES];
      
       groupController = [[GroupedArrayController alloc] initWithEntityName:@"Notification" 
                                                        basePredicateString:@"showInRollup == 1" 
                                                                   groupKey:@"ApplicationName"
                                                       managedObjectContext:[[self historyController] managedObjectContext]];
       [groupController setDelegate:self];
       
       NSSortDescriptor *ascendingTime = [NSSortDescriptor sortDescriptorWithKey:@"Time" ascending:NO];
       [[groupController countController] setSortDescriptors:[NSArray arrayWithObject:ascendingTime]];
              
       [historyTable setDoubleAction:@selector(userDoubleClickedNote:)];
       transitionGroup = NO;
   }
   return self;
}

-(void)dealloc
{
   [groupController removeObserver:self forKeyPath:nil];
   [historyTable release]; historyTable = nil;
   [groupController release]; groupController = nil;
   historyController = nil;
   [groupController release];
   groupController = nil;
      
   [super dealloc];
}

-(void)windowWillClose:(NSNotification *)notification
{
   [[GrowlNotificationDatabase sharedInstance] userReturnedAndClosedList];
   currentlyShown = NO;
}

-(void)updateCount
{
   if(!currentlyShown)
      return;
   
   NSUInteger numberOfNotifications = [[[groupController countController] arrangedObjects] count];
   NSString* description;
   
   if(numberOfNotifications == 1){
      description = [NSString stringWithFormat:NSLocalizedString(@"There was %d notification while you were away", nil), numberOfNotifications];
   } else {
      description = [NSString stringWithFormat:NSLocalizedString(@"There were %d notifications while you were away", nil), numberOfNotifications];
   }

    [countLabel setObjectValue:description];
}

-(void)resetArray
{   
   [[self window] center];
   
   currentlyShown = YES;
   [self showWindow:self];
    [historyTable reloadData];
}

-(IBAction)userDoubleClickedNote:(id)sender
{
   NSInteger row = NSNotFound;
   if([sender isKindOfClass:[NSTableView class]]){
       row = [historyTable clickedRow];
   }else if([sender isKindOfClass:[NSButton class]]){
       //We use bindings, so the showGroup is already toggled, just tell it to update the array
       transitionGroup = YES;
       [groupController updateArray];
       return;
   }
   
   if(row != NSNotFound && row >= 0)
   {      
      id obj = [[groupController arrangedObjects] objectAtIndex:row];
      if([obj isKindOfClass:[GrowlHistoryNotification class]])
          [[GrowlApplicationController sharedInstance] growlNotificationDict:[obj valueForKey:@"GrowlDictionary"] 
                                                didCloseViaNotificationClick:YES 
                                                              onLocalMachine:YES];
      else if([obj isKindOfClass:[GroupController class]]){
          transitionGroup = YES;
          [groupController toggleShowGroup:[obj groupID]];
      }
   }
}

- (IBAction)deleteNotifications:(id)sender {
    /* Logic for what note to remove from the rollup:
     * If we clicked while on a hovered note, delete that one
     * If we clicked or pressed delete while on a selected note, delete that one
     * If there are other selected notes, and we clicked delete, or a selected one, delete those as well
     */
    NSUInteger row = [historyTable rowForView:sender];
    NSMutableIndexSet *rowsToDelete = [NSMutableIndexSet indexSet];
    if(row == NSNotFound){
        NSLog(@"no row for this button");
        return;
    }
    GrowlNotificationRowView *view = [historyTable rowViewAtRow:row makeIfNecessary:NO];
    if(view && view.mouseInside && ![[historyTable selectedRowIndexes] containsIndex:row]){
        [rowsToDelete addIndex:row];
    }else if([[historyTable selectedRowIndexes] containsIndex:row]){
        [rowsToDelete addIndexes:[historyTable selectedRowIndexes]];
    }
    if([rowsToDelete count] == 0)
        return;
    //NSLog(@"Rows to remove from the rollup: %@", rowsToDelete);
    for(id obj in [[groupController arrangedObjects] objectsAtIndexes:rowsToDelete]){
        if([obj isKindOfClass:[GrowlHistoryNotification class]])
            [obj setShowInRollup:[NSNumber numberWithBool:NO]];
    }
    [historyController saveDatabase:NO];
}

- (IBAction)deleteAppNotifications:(id)sender {
    NSUInteger row = [historyTable rowForView:sender];
    if(![self tableView:historyTable isGroupRow:row]){
        NSLog(@"Row not found, or not application");
        return;
    }

    NSArrayController *appController = [[[groupController arrangedObjects] objectAtIndex:row] groupArray];
    if(!appController)
        return;
    [[appController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:[GrowlHistoryNotification class]])
            [obj setShowInRollup:[NSNumber numberWithBool:NO]];
    }];
    [historyController saveDatabase:NO];
}

-(GrowlNotificationDatabase*)historyController
{
   if(!historyController)
      historyController = [GrowlNotificationDatabase sharedInstance];
      
   return historyController;
}

-(void)updateRowHeights
{
    if([[groupController arrangedObjects] count] == 0)
        return;
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[groupController arrangedObjects] count] - 1)];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.0];
    [historyTable noteHeightOfRowsWithIndexesChanged:set];
    [NSAnimationContext endGrouping];
}

-(CGFloat)heightForDescription:(NSString*)description forWidth:(CGFloat)width
{
    CGFloat padded = width - GROWL_DESCRIPTION_WIDTH_PAD;
    NSFont *font = [NSFont boldSystemFontOfSize:0];
    NSParagraphStyle *paragraph = [NSParagraphStyle defaultParagraphStyle];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, 
                                                                          paragraph, NSParagraphStyleAttributeName, nil];
    NSRect bound = [description boundingRectWithSize:NSMakeSize(padded, 0) 
                                             options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine 
                                          attributes:attributes];
    CGFloat result = bound.size.height + GROWL_DESCRIPTION_HEIGHT_PAD;
    return (result > GROWL_ROW_MINIMUM_HEIGHT) ? result : GROWL_ROW_MINIMUM_HEIGHT;
}


#pragma mark TableView Data source methods

- (BOOL)tableView:(NSTableView*)tableView isGroupRow:(NSInteger)row
{
    return [[[groupController arrangedObjects] objectAtIndex:row] isKindOfClass:[GroupController class]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[groupController arrangedObjects] count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
   if(aTableColumn == notificationColumn || [self tableView:aTableView isGroupRow:rowIndex]){
      return [[groupController arrangedObjects] objectAtIndex:rowIndex];
   }
   return nil;
}

-(NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableColumn == notificationColumn){
        if([groupController grouped]){
            GrowlNotificationCellView *cellView = [tableView makeViewWithIdentifier:@"GroupNoteCell" owner:self];
            [[cellView deleteButton] setHidden:![[historyTable selectedRowIndexes] containsIndex:row]];
            return cellView;
        }else{
            GrowlNotificationCellView *cellView = [tableView makeViewWithIdentifier:@"NotificationCellView" owner:self];
            [[cellView deleteButton] setHidden:![[historyTable selectedRowIndexes] containsIndex:row]];
            return cellView;
        }
    }else if([self tableView:tableView isGroupRow:row]){
        GrowlRollupGroupCellView *groupView = [tableView makeViewWithIdentifier:@"GroupCellView" owner:self];
       
        NSString *appName = [[self tableView:tableView objectValueForTableColumn:tableColumn row:row] groupID   ];
        NSImage *icon = [[[GrowlTicketController sharedController] ticketForApplicationName:appName hostName:nil] icon];
        if(icon){
            [[groupView imageView] setImage:icon];
        }else{
            [[groupView imageView] setImage:nil];
        }
        
        [[groupView deleteButton] setState:NSOnState];
        
        return groupView;
    }
    return nil;
}

-(NSView*)tableView:(NSTableView*)tableView rowViewForRow:(NSInteger)row
{
    if(![self tableView:tableView isGroupRow:row]){
        GrowlNotificationRowView *rowView = [tableView makeViewWithIdentifier:NSTableViewRowViewKey owner:self];
        [rowView setMouseInside:NO];
        return rowView;
    }else{
        return [tableView makeViewWithIdentifier:@"GroupRowView" owner:self];
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if([self tableView:tableView isGroupRow:row]){
        return 34;
    }else{
        id obj = [[groupController arrangedObjects] objectAtIndex:row];
        if([obj isKindOfClass:[GrowlHistoryNotification class]]){
            NSString *description = [[[groupController arrangedObjects] objectAtIndex:row] Description];
            CGFloat width = [[self window] frame].size.width;
            return [self heightForDescription:description forWidth:width];
        }else
            return GROWL_ROW_MINIMUM_HEIGHT;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [historyTable enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        NSView *cellView = [rowView viewAtColumn:0];
        if ([cellView isKindOfClass:[GrowlNotificationCellView class]] && [rowView isKindOfClass:[GrowlNotificationRowView class]]) {
            GrowlNotificationRowView *tableRowView = (GrowlNotificationRowView*)rowView;
            GrowlNotificationCellView *tableCellView = (GrowlNotificationCellView *)cellView;
            NSButton *deleteButton = tableCellView.deleteButton;
            if (tableRowView.selected || tableRowView.mouseInside) {
                [deleteButton setHidden:NO];
            } else {
                [deleteButton setHidden:YES];
            }
        }
    }];
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
   return ![self tableView:tableView isGroupRow:row];
}

#pragma mark Window delegate methods

- (void)windowDidResize:(NSNotification *)note
{
    [self updateRowHeights];
}

#pragma mark GroupedArrayControllerDelegate methods

-(void)groupedControllerBeginUpdates:(GroupedArrayController*)groupedController
{
    [historyTable beginUpdates];
}
-(void)groupedControllerEndUpdates:(GroupedArrayController*)groupedController
{
    [historyTable endUpdates];
    [self updateCount];
    transitionGroup = NO;
}
-(void)groupedController:(GroupedArrayController*)groupedController insertIndexes:(NSIndexSet*)indexSet
{
    NSTableViewAnimationOptions options = NSTableViewAnimationEffectFade|NSTableViewAnimationEffectGap;
    if (!transitionGroup)
        options = options|NSTableViewAnimationSlideLeft;
    [historyTable insertRowsAtIndexes:indexSet withAnimation:options];
}
-(void)groupedController:(GroupedArrayController*)groupedController removeIndexes:(NSIndexSet*)indexSet
{
    NSTableViewAnimationOptions options = NSTableViewAnimationEffectFade|NSTableViewAnimationEffectGap;
    if (!transitionGroup)
        options = options|NSTableViewAnimationSlideRight;
    [historyTable removeRowsAtIndexes:indexSet withAnimation:options];
}
-(void)groupedController:(GroupedArrayController*)groupedController moveIndex:(NSUInteger)start toIndex:(NSUInteger)end
{
    [historyTable moveRowAtIndex:start toIndex:end];
}

@end
