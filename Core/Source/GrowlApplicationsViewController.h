//
//  GrowlApplicationsViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class TicketsArrayController, NotificationsArrayController, GrowlPositionPicker, GrowlTicketController;

@interface GrowlApplicationsViewController : GrowlPrefsViewController <NSTableViewDataSource>

@property (nonatomic, assign) IBOutlet NSTableView *growlApplications;
@property (nonatomic, assign) IBOutlet NSTableColumn *applicationsNameAndIconColumn;
@property (nonatomic, assign) IBOutlet NSMenu *notificationPriorityMenu;
@property (nonatomic, assign) GrowlTicketController *ticketController;
@property (nonatomic, assign) IBOutlet TicketsArrayController *ticketsArrayController;
@property (nonatomic, assign) IBOutlet NotificationsArrayController *notificationsArrayController;
@property (nonatomic, assign) IBOutlet GrowlPositionPicker *appPositionPicker;
@property (nonatomic, assign) IBOutlet NSPopUpButton *soundMenuButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *displayMenuButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *notificationDisplayMenuButton;
@property (nonatomic, assign) NSIndexSet *selectedNotificationIndexes;

@property (nonatomic, assign) IBOutlet NSScrollView *applicationScrollView;

@property (nonatomic, retain) NSSound *demoSound;

@property (nonatomic) BOOL canRemoveTicket;
@property (nonatomic) BOOL showSearch;

- (BOOL) canRemoveTicket;
- (void) setCanRemoveTicket:(BOOL)flag;
- (IBAction) deleteTicket:(id)sender;
- (IBAction)playSound:(id)sender;
- (void)selectApplication:(NSString*)appName hostName:(NSString*)hostName;
- (IBAction) showApplicationConfigurationTab:(id)sender;
- (IBAction) changeNameOfDisplayForApplication:(id)sender;
- (IBAction) changeNameOfDisplayForNotification:(id)sender;
- (NSIndexSet *) selectedNotificationIndexes;
- (void) setSelectedNotificationIndexes:(NSIndexSet *)newSelectedNotificationIndexes;

- (BOOL)tableView:(NSTableView*)tableView isGroupRow:(NSInteger)row;

@end
