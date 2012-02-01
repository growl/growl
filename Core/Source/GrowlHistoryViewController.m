//
//  GrowlHistoryViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlHistoryViewController.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlOnSwitch.h"

@implementation GrowlHistoryViewController

@synthesize historyController;
@synthesize historyOnOffSwitch;
@synthesize historyArrayController;
@synthesize historyTable;
@synthesize trimByCountCheck;
@synthesize trimByDateCheck;
@synthesize historySearchField;

@synthesize enableHistoryLabel;
@synthesize keepAmountLabel;
@synthesize keepDaysLabel;
@synthesize applicationColumnLabel;
@synthesize titleColumnLabel;
@synthesize timeColumnLabel;
@synthesize clearAllHistoryButtonTitle;


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane
{
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.historyController = [GrowlNotificationDatabase sharedInstance];
   
      self.enableHistoryLabel = NSLocalizedString(@"Enable History:", @"Label for the on/off switfh for enabling history");
      self.keepAmountLabel = NSLocalizedString(@"Keep Amount", @"Label for checkbox for keeping up to an amount of notifications");
      self.keepDaysLabel = NSLocalizedString(@"Keep Days", @"Label for checkbox for keeping up to a certain number of days worth of notifications");
      self.applicationColumnLabel = NSLocalizedString(@"Application", @"Column title for the applications column in the history table");
      self.titleColumnLabel = NSLocalizedString(@"Title", @"Column title for the title column in the history table");
      self.timeColumnLabel = NSLocalizedString(@"Time", @"Column title for the time column in the history table");
      self.clearAllHistoryButtonTitle = NSLocalizedString(@"Clear All History", @"Clear all history button title");
      [[historySearchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"Placeholder text in search field")];
   }
   return self;
}

-(void) awakeFromNib {
   [historyTable setAutosaveName:@"GrowlPrefsHistoryTable"];
   [historyTable setAutosaveTableColumns:YES];
   
   [historyOnOffSwitch addObserver:self 
                        forKeyPath:@"state" 
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                           context:nil];
    
    //set our default sort descriptor so that we're looking at new stuff at the top by default
    NSSortDescriptor *ascendingTime = [NSSortDescriptor sortDescriptorWithKey:@"Time" ascending:NO];
    [historyArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingTime]];
   
   [[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(growlDatabaseDidUpdate:) 
                                                name:@"GrowlDatabaseUpdated" 
                                              object:historyController];
   
   [self reloadPrefs:nil];
}

+ (NSString*)nibName {
   return @"HistoryPrefs";
}

- (void)dealloc
{
   [historyOnOffSwitch removeObserver:self forKeyPath:@"state"];
   
   [enableHistoryLabel release];
   [keepAmountLabel release];
   [keepDaysLabel release];
   [applicationColumnLabel release];
   [titleColumnLabel release];
   [timeColumnLabel release];
   [clearAllHistoryButtonTitle release];
   [super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
   if(object == historyOnOffSwitch && [keyPath isEqualToString:@"state"])
      [self.preferencesController setGrowlHistoryLogEnabled:[historyOnOffSwitch state]];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
   id object = [notification object];
   if(!object || [object isEqualToString:GrowlHistoryLogEnabled]){
      [historyOnOffSwitch setState:[self.preferencesController isGrowlHistoryLogEnabled]];
   }
	
	[pool release];
}

#pragma mark HistoryTab

-(void)growlDatabaseDidUpdate:(NSNotification*)notification
{
   [historyArrayController fetch:self];
}

-(IBAction)validateHistoryTrimSetting:(id)sender
{
   if([trimByDateCheck state] == NSOffState && [trimByCountCheck state] == NSOffState)
   {
      NSLog(@"User tried turning off both automatic trim options");
      NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Turning off both automatic trim functions is not allowed.", nil)
                                       defaultButton:NSLocalizedString(@"Ok", nil)
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"To prevent the history database from growing indefinitely, at least one type of automatic trim must be active", nil)];
      [alert runModal];
      if ([sender isEqualTo:trimByDateCheck]) {
         [self.preferencesController setGrowlHistoryTrimByDate:YES];
      }
      
      if([sender isEqualTo:trimByCountCheck]){
         [self.preferencesController setGrowlHistoryTrimByCount:YES];
      }
   }
}

- (IBAction) deleteSelectedHistoryItems:(id)sender
{
   [[GrowlNotificationDatabase sharedInstance] deleteSelectedObjects:[historyArrayController selectedObjects]];
   [historyArrayController rearrangeObjects];
}

- (IBAction) clearAllHistory:(id)sender
{
   NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! About to delete ALL history", nil)
                                    defaultButton:NSLocalizedString(@"Cancel", nil)
                                  alternateButton:NSLocalizedString(@"Ok", nil)
                                      otherButton:nil
                        informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone, please confirm that you want to delete the entire notification history", nil)];
   [alert beginSheetModalForWindow:[sender window]
                     modalDelegate:self
                    didEndSelector:@selector(clearAllHistoryAlert:didReturn:contextInfo:)
                       contextInfo:nil];
}

- (IBAction) clearAllHistoryAlert:(NSAlert*)alert didReturn:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
   switch (returnCode) {
      case NSAlertDefaultReturn:
         NSLog(@"Doing nothing");
         break;
      case NSAlertAlternateReturn:
         [[GrowlNotificationDatabase sharedInstance] deleteAllHistory];
         break;
   }
}

- (void)openSettings:(BOOL)notification {
   id obj = [[historyArrayController arrangedObjects] objectAtIndex:[historyTable clickedRow]];
   NSString *appName =  [obj valueForKey:@"ApplicationName"];
   NSString *hostName = [obj valueForKeyPath:[NSString stringWithFormat:@"GrowlDictionary.%@", GROWL_NOTIFICATION_GNTP_SENT_BY]];
   NSString *noteName = notification ? [obj valueForKey:@"Name"] : nil;
   //NSLog(@"Selected (<application> - <host> : <note>) %@ - %@ : %@", appName, hostName, noteName);
   NSString *urlString = [NSString stringWithFormat:@"growl://preferences/applications/%@/%@/%@", appName, (hostName ? hostName : @""), (noteName ? noteName : @"")];
   urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   //NSLog(@"url: %@", urlString);
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];

}

- (IBAction)openAppSettings:(id)sender {
   [self openSettings:NO];
}

- (IBAction)openNoteSettings:(id)sender {
   [self openSettings:YES];
}

@end
