//
//  GrowlNotificationHistoryWindow.h
//  Growl
//
//  Created by Daniel Siemer on 9/2/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlAbstractDatabase.h"

@class GrowlNotificationDatabase;

@interface GrowlNotificationHistoryWindow : NSWindowController <GrowlDatabaseUpdateDelegate> {
   IBOutlet NSTableView *historyTable;
   IBOutlet NSArrayController *arrayController;
   IBOutlet NSTextField *countLabel;
   IBOutlet NSView *storage;
   IBOutlet NSView *countView;
   IBOutlet NSView *searchView;
   IBOutlet NSTableColumn *dateColumn;
   IBOutlet NSTableColumn *notificationColumn;
   IBOutlet NSTableHeaderView *headerView;
   GrowlNotificationDatabase *historyController;
   
   NSDate *awayDate;
   BOOL expanded;
   BOOL currentlyShown;
   NSSize expandSize;
}

@property (assign) IBOutlet NSTableView *historyTable;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTextField *countLabel;
@property (assign) IBOutlet NSView *storage;
@property (nonatomic, retain) IBOutlet NSView *countView;
@property (nonatomic, retain) IBOutlet NSView *searchView;
@property (assign) IBOutlet NSTableColumn *dateColumn;
@property (assign) IBOutlet NSTableColumn *notificationColumn;
@property (assign) IBOutlet NSTableHeaderView *headerView;

@property (nonatomic, retain) NSDate *awayDate;

-(IBAction)expandWindow:(id)sender;
-(void)updateTableView:(BOOL)willMerge;
-(void)resetArrayWithDate:(NSDate*)newAway;
-(void)shrinkWindow;
-(IBAction)openFullLog:(id)sender;

@end
