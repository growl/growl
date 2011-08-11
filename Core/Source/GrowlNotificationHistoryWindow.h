//
//  GrowlNotificationHistoryWindow.h
//  Growl
//
//  Created by Daniel Siemer on 9/2/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlAbstractDatabase.h"
#import "GroupedArrayController.h"

@class GrowlNotificationDatabase, GroupedArrayController;

@interface GrowlNotificationHistoryWindow : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, GroupedArrayControllerDelegate> {
   IBOutlet NSTableView *historyTable;
   IBOutlet NSTextField *countLabel;
   IBOutlet NSTableColumn *notificationColumn;
   GrowlNotificationDatabase *historyController;
    
   GroupedArrayController *groupController;
   
   BOOL currentlyShown;
}

@property (assign) IBOutlet NSTableView *historyTable;
@property (assign) IBOutlet NSTextField *countLabel;
@property (assign) IBOutlet NSTableColumn *notificationColumn;

-(GrowlNotificationDatabase*)historyController;
-(void)updateCount;
-(void)resetArray;
-(IBAction)deleteNotifications:(id)sender;
-(IBAction)deleteAppNotifications:(id)sender;
-(CGFloat)heightForDescription:(NSString*)description forWidth:(CGFloat)width;

@end
