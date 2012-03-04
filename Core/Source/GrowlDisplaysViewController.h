//
//  GrowlDisplaysViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlPlugin, GrowlPluginController, GrowlTicketDatabase, GrowlTicketDatabasePlugin, GrowlPluginPreferencePane;

@interface GrowlDisplaysViewController : GrowlPrefsViewController

@property (nonatomic, assign) GrowlPluginController *pluginController;
@property (nonatomic, assign) GrowlTicketDatabase *ticketDatabase;
@property (nonatomic, assign) IBOutlet NSTableView *displayPluginsTable;
@property (nonatomic, assign) IBOutlet NSView *displayPrefView;
@property (nonatomic, assign) IBOutlet NSView *displayDefaultPrefView;
@property (nonatomic, assign) IBOutlet NSTextField *displayAuthor;
@property (nonatomic, assign) IBOutlet NSTextField *displayVersion;
@property (nonatomic, assign) IBOutlet NSButton *previewButton;
@property (nonatomic, assign) IBOutlet NSArrayController *displayPluginsArrayController;

@property (nonatomic, assign) IBOutlet NSWindow *disabledDisplaysSheet;
@property (nonatomic, assign) IBOutlet NSTextView *disabledDisplaysList;

@property (nonatomic, retain) GrowlPluginPreferencePane *pluginPrefPane;
@property (nonatomic, retain) NSMutableArray *loadedPrefPanes;

@property (nonatomic, retain) GrowlPlugin *currentPluginController;

@property (nonatomic, retain) NSString *defaultStyleLabel;
@property (nonatomic, retain) NSString *showDisabledButtonTitle;
@property (nonatomic, retain) NSString *getMoreStylesButtonTitle;
@property (nonatomic, retain) NSString *previewButtonTitle;
@property (nonatomic, retain) NSString *displayStylesColumnTitle;

- (void)selectPlugin:(NSString*)pluginName;

- (IBAction) showDisabledDisplays:(id)sender;
- (IBAction) endDisabledDisplays:(id)sender;
- (BOOL)hasDisabledDisplays;

- (IBAction) openGrowlWebSiteToStyles:(id)sender;
- (IBAction) showPreview:(id)sender;
- (void) loadViewForDisplay:(GrowlTicketDatabasePlugin*)displayName;

@end
