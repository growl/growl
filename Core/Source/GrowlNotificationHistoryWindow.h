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

@interface GrowlNotificationHistoryWindow : NSWindowController {
   IBOutlet NSTableView *historyTable;
   IBOutlet NSArrayController *arrayController;
   IBOutlet NSTextField *countLabel;
   IBOutlet NSTableColumn *notificationColumn;
   GrowlNotificationDatabase *historyController;
   
   BOOL currentlyShown;
}

@property (assign) IBOutlet NSTableView *historyTable;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTextField *countLabel;
@property (assign) IBOutlet NSTableColumn *notificationColumn;

-(void)updateTableView:(BOOL)willMerge;
-(void)resetArray;
-(IBAction)deleteNotifications:(id)sender;
-(CGFloat)heightForDescription:(NSString*)description forWidth:(CGFloat)width;

@end
