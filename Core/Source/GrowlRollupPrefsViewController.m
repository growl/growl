//
//  GrowlRollupPrefsViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlRollupPrefsViewController.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <GrowlPlugins/SGKeyCombo.h>
#import "SGHotKeyCenter.h"
#import "GrowlApplicationController.h"
#import "SGHotKey.h"
#import "GrowlPreferencesController.h"

@implementation GrowlRollupPrefsViewController 

@synthesize recorderControl;
@synthesize rollupEnabledTitle;
@synthesize rollupAutomaticTitle;
@synthesize rollupAllTitle;
@synthesize rollupLoggedTitle;
@synthesize showHideTitle;

@synthesize pulseMenuItemTitle;
@synthesize idleDetectionBoxTitle;
@synthesize idleAfterTitle;
@synthesize secondsTitle;
@synthesize minutesTitle;
@synthesize hoursTitle;
@synthesize whenScreenSaverActiveTitle;
@synthesize whenScreenLockedTitle;

-(void)awakeFromNib {
   self.rollupEnabledTitle = NSLocalizedString(@"Rollup Enabled", @"Title for rollup enabled checkbox");
   self.rollupAutomaticTitle = NSLocalizedString(@"Rollup Automatically Displays", @"Title for rollup automatic checkbox");
   self.rollupAllTitle = NSLocalizedString(@"Rollup all notes", @"Rollup all notifications radio button");
   self.rollupLoggedTitle = NSLocalizedString(@"Rollup only logged notes", @"Rollup only logged notifications radio button");
   self.showHideTitle = NSLocalizedString(@"Show/Hide Shortcut", @"Show hide keyboard shortcut");
   
   self.pulseMenuItemTitle = NSLocalizedString(@"Pulse Menu Item", @"Checkbox for whether the menu item should pulse");
   self.idleDetectionBoxTitle = NSLocalizedString(@"Idle Detection", @"Title on box containing idle detection controls");
   self.idleAfterTitle = NSLocalizedString(@"Consider me idle after:", @"Consider me idle based on time entered below");
   self.secondsTitle = NSLocalizedString(@"Seconds", @"Unit of time for idle detection");
   self.minutesTitle = NSLocalizedString(@"Minutes", @"Unit of time for idle detection");
   self.hoursTitle = NSLocalizedString(@"Hours", @"Unit of time for idle detection");
   self.whenScreenSaverActiveTitle = NSLocalizedString(@"When Screensaver is active", @"checkbox for idle detection based on screensaver");
   self.whenScreenLockedTitle = NSLocalizedString(@"When Screen is locked", @"Checkbox for idle detection based on locking the screen");
   
   KeyCombo combo = {SRCarbonToCocoaFlags([GrowlPreferencesController sharedController].rollupKeyCombo.modifiers), [GrowlPreferencesController sharedController].rollupKeyCombo.keyCode};
   [self.recorderControl setKeyCombo:combo];
}

+ (NSString*)nibName {
   return @"RollupPrefs";
}

-(void)dealloc {
   [rollupEnabledTitle release];
   [rollupAutomaticTitle release];
   [secondsTitle release];
   [rollupAllTitle release];
   [rollupLoggedTitle release];
   [showHideTitle release];
   
   self.pulseMenuItemTitle = nil;
   self.idleDetectionBoxTitle = nil;
   self.idleAfterTitle = nil;
   self.secondsTitle = nil;
   self.minutesTitle = nil;
   self.hoursTitle = nil;
   self.whenScreenSaverActiveTitle = nil;
   self.whenScreenLockedTitle = nil;
   
   [super dealloc];
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
    return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    SGKeyCombo *combo = [SGKeyCombo keyComboWithKeyCode:newKeyCombo.code modifiers:SRCocoaToCarbonFlags(newKeyCombo.flags)];
    
    if(combo.keyCode == -1)
        combo = nil;
    
    [GrowlPreferencesController sharedController].rollupKeyCombo = combo;
}

@end
