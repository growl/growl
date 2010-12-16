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
   GrowlNotificationDatabase *historyController;
   
   NSDate *awayDate;
}

@property (assign) IBOutlet NSTableView *historyTable;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) NSDate *awayDate;

-(void)resetArrayWithDate:(NSDate*)newAway;

@end
