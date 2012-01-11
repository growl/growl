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

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane
{
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.historyController = [GrowlNotificationDatabase sharedInstance];
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

@end
