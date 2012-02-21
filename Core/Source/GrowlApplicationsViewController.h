//
//  GrowlApplicationsViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class TicketsArrayController, NotificationsArrayController, GrowlPositionPicker, GrowlTicketController, GrowlOnSwitch;

@interface GrowlApplicationsViewController : GrowlPrefsViewController <NSTableViewDataSource>

@property (nonatomic, assign) IBOutlet NSTableView *growlApplications;
@property (nonatomic, assign) IBOutlet NSTableView *notificationsTable;
@property (nonatomic, assign) IBOutlet NSTableColumn *applicationsNameAndIconColumn;
@property (nonatomic, assign) GrowlTicketController *ticketController;
@property (nonatomic, assign) IBOutlet TicketsArrayController *ticketsArrayController;
@property (nonatomic, assign) IBOutlet NotificationsArrayController *notificationsArrayController;
@property (nonatomic, assign) IBOutlet NSTabView *appSettingsTabView;
@property (nonatomic, assign) IBOutlet GrowlOnSwitch *appOnSwitch;
@property (nonatomic, assign) IBOutlet GrowlPositionPicker *appPositionPicker;
@property (nonatomic, assign) IBOutlet NSPopUpButton *soundMenuButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *displayMenuButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *notificationDisplayMenuButton;
@property (nonatomic, assign) NSIndexSet *selectedNotificationIndexes;

@property (nonatomic, assign) IBOutlet NSScrollView *applicationScrollView;
@property (nonatomic, retain) NSSound *demoSound;
@property (nonatomic) BOOL canRemoveTicket;

@property (nonatomic, retain) NSString *getApplicationsTitle;
@property (nonatomic, retain) NSString *enableApplicationLabel;
@property (nonatomic, retain) NSString *enableLoggingLabel;
@property (nonatomic, retain) NSString *applicationDefaultStyleLabel;
@property (nonatomic, retain) NSString *applicationSettingsTabLabel;
@property (nonatomic, retain) NSString *notificationSettingsTabLabel;
@property (nonatomic, retain) NSString *defaultStartPositionLabel;
@property (nonatomic, retain) NSString *customStartPositionLabel;
@property (nonatomic, retain) NSString *noteDisplayStyleLabel;
@property (nonatomic, retain) NSString *stayOnScreenLabel;
@property (nonatomic, retain) NSString *priorityLabel;
@property (nonatomic, retain) NSString *playSoundLabel;
@property (nonatomic, retain) NSString *stayOnScreenNever;
@property (nonatomic, retain) NSString *stayOnScreenAlways;
@property (nonatomic, retain) NSString *stayOnScreenAppDecides;
@property (nonatomic, retain) NSString *priorityLow;
@property (nonatomic, retain) NSString *priorityModerate;
@property (nonatomic, retain) NSString *priorityNormal;
@property (nonatomic, retain) NSString *priorityHigh;
@property (nonatomic, retain) NSString *priorityEmergency;

- (BOOL) canRemoveTicket;
- (void) setCanRemoveTicket:(BOOL)flag;
- (IBAction)getApplications:(id)sender;
- (IBAction) deleteTicket:(id)sender;
- (IBAction)playSound:(id)sender;
- (void)selectApplication:(NSString*)appName hostName:(NSString*)hostName notificationName:(NSString*)noteNameOrNil;
- (IBAction) changeNameOfDisplayForApplication:(id)sender;
- (IBAction) changeNameOfDisplayForNotification:(id)sender;
- (NSIndexSet *) selectedNotificationIndexes;
- (void) setSelectedNotificationIndexes:(NSIndexSet *)newSelectedNotificationIndexes;

- (BOOL)tableView:(NSTableView*)tableView isGroupRow:(NSInteger)row;

@end
