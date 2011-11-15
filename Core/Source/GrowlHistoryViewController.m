//
//  GrowlHistoryViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlHistoryViewController.h"
#import "GrowlNotificationDatabase.h"

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
    
    //set our default sort descriptor so that we're looking at new stuff at the top by default
    NSSortDescriptor *ascendingTime = [NSSortDescriptor sortDescriptorWithKey:@"Time" ascending:NO];
    [historyArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingTime]];
   
   [[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(growlDatabaseDidUpdate:) 
                                                name:@"GrowlDatabaseUpdated" 
                                              object:historyController];
   
   [self reloadPrefs:nil];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
   id object = [notification object];
   if(!object || [object isEqualToString:GrowlHistoryLogEnabled]){
      if([self.preferencesController isGrowlHistoryLogEnabled])
         [historyOnOffSwitch setSelectedSegment:0];
      else
         [historyOnOffSwitch setSelectedSegment:1];
   }
	
	[pool release];
}

#pragma mark HistoryTab

- (IBAction) toggleHistory:(id)sender
{
   if([(NSSegmentedControl*)sender selectedSegment] == 0){
      [self.preferencesController setGrowlHistoryLogEnabled:YES];
   }else{
      [self.preferencesController setGrowlHistoryLogEnabled:NO];
   }
}

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
