//
//  GrowlHistoryViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlNotificationDatabase, GrowlOnSwitch;

@interface GrowlHistoryViewController : GrowlPrefsViewController {
    GrowlNotificationDatabase *_notificationDatabase;
}

@property (nonatomic, assign) GrowlNotificationDatabase *notificationDatabase;
@property (nonatomic, assign) IBOutlet GrowlOnSwitch *historyOnOffSwitch;
@property (nonatomic, assign) IBOutlet NSArrayController *historyArrayController;
@property (nonatomic, assign) IBOutlet NSTableView *historyTable;
@property (nonatomic, assign) IBOutlet NSButton *trimByCountCheck;
@property (nonatomic, assign) IBOutlet NSButton *trimByDateCheck;
@property (nonatomic, assign) IBOutlet NSSearchField *historySearchField;

@property (nonatomic, retain) NSString *enableHistoryLabel;
@property (nonatomic, retain) NSString *keepAmountLabel;
@property (nonatomic, retain) NSString *keepDaysLabel;
@property (nonatomic, retain) NSString *applicationColumnLabel;
@property (nonatomic, retain) NSString *titleColumnLabel;
@property (nonatomic, retain) NSString *timeColumnLabel;
@property (nonatomic, retain) NSString *clearAllHistoryButtonTitle;

- (void) reloadPrefs:(NSNotification*)notification;

- (IBAction) validateHistoryTrimSetting:(id)sender;
- (IBAction) deleteSelectedHistoryItems:(id)sender;
- (IBAction) clearAllHistory:(id)sender;
- (IBAction) openAppSettings:(id)sender;
- (IBAction) openNoteSettings:(id)sender;

@end
