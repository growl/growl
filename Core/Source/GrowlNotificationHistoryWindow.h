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
   IBOutlet NSView *listAndDetails;
   IBOutlet NSTableColumn *appNameAndIconColumn;
   GrowlNotificationDatabase *historyController;
   
   NSDate *awayDate;
   BOOL expanded;
   NSSize expandSize;
}

@property (assign) IBOutlet NSTableView *historyTable;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTextField *countLabel;
@property (assign) IBOutlet NSView *storage;
@property (assign) IBOutlet NSView *listAndDetails;

@property (nonatomic, retain) NSDate *awayDate;

-(void)updateTableView;
-(void)resetArrayWithDate:(NSDate*)newAway;
-(void)shrinkWindow;

@end
