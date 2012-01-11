//
//  GrowlHistoryViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlNotificationDatabase, GrowlOnSwitch;

@interface GrowlHistoryViewController : GrowlPrefsViewController

@property (nonatomic, assign) GrowlNotificationDatabase *historyController;
@property (nonatomic, assign) IBOutlet GrowlOnSwitch *historyOnOffSwitch;
@property (nonatomic, assign) IBOutlet NSArrayController *historyArrayController;
@property (nonatomic, assign) IBOutlet NSTableView *historyTable;
@property (nonatomic, assign) IBOutlet NSButton *trimByCountCheck;
@property (nonatomic, assign) IBOutlet NSButton *trimByDateCheck;

- (void) reloadPrefs:(NSNotification*)notification;

- (IBAction) validateHistoryTrimSetting:(id)sender;
- (IBAction) deleteSelectedHistoryItems:(id)sender;
- (IBAction) clearAllHistory:(id)sender;

@end
