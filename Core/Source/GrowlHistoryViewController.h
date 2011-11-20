//
//  GrowlHistoryViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlNotificationDatabase;

@interface GrowlHistoryViewController : GrowlPrefsViewController {
    GrowlNotificationDatabase *_notificationDatabase;
}

@property (nonatomic, assign) GrowlNotificationDatabase *notificationDatabase;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *historyOnOffSwitch;
@property (nonatomic, assign) IBOutlet NSArrayController *historyArrayController;
@property (nonatomic, assign) IBOutlet NSTableView *historyTable;
@property (nonatomic, assign) IBOutlet NSButton *trimByCountCheck;
@property (nonatomic, assign) IBOutlet NSButton *trimByDateCheck;

- (void) reloadPrefs:(NSNotification*)notification;

- (IBAction) toggleHistory:(id)sender;
- (IBAction) validateHistoryTrimSetting:(id)sender;
- (IBAction) deleteSelectedHistoryItems:(id)sender;
- (IBAction) clearAllHistory:(id)sender;

@end
