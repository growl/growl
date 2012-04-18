//
//  GrowlRollupPrefsViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlRollupPrefsViewController.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "SGKeyCombo.h"
#import "SGHotKeyCenter.h"
#import "GrowlApplicationController.h"
#import "SGHotKey.h"
#import "GrowlPreferencesController.h"

@implementation GrowlRollupPrefsViewController 

@synthesize recorderControl;
@synthesize rollupEnabledTitle;
@synthesize rollupAutomaticTitle;
@synthesize rollupIdleTitle;
@synthesize secondsTitle;
@synthesize rollupAllTitle;
@synthesize rollupLoggedTitle;
@synthesize showHideTitle;

-(void)awakeFromNib {
   self.rollupEnabledTitle = NSLocalizedString(@"Rollup Enabled", @"Title for rollup enabled checkbox");
   self.rollupAutomaticTitle = NSLocalizedString(@"Rollup Automatically Displays", @"Title for rollup automatic checkbox");
   self.rollupIdleTitle = NSLocalizedString(@"Send notifications to the rollup after", @"First part of string for idle timeout");
   self.secondsTitle = NSLocalizedString(@"seconds of inactivity", @"second part of string for idle timeout");
   self.rollupAllTitle = NSLocalizedString(@"Rollup all notes", @"Rollup all notifications radio button");
   self.rollupLoggedTitle = NSLocalizedString(@"Rollup only logged notes", @"Rollup only logged notifications radio button");
    self.showHideTitle = NSLocalizedString(@"Show/Hide Shortcut", @"Show hide keyboard shortcut");
    
    KeyCombo combo = {SRCarbonToCocoaFlags([GrowlPreferencesController sharedController].rollupKeyCombo.modifiers), [GrowlPreferencesController sharedController].rollupKeyCombo.keyCode};
    [self.recorderControl setKeyCombo:combo];
}

+ (NSString*)nibName {
   return @"RollupPrefs";
}

-(void)dealloc {
    [rollupEnabledTitle release];
    [rollupAutomaticTitle release];
    [rollupIdleTitle release];
    [secondsTitle release];
    [rollupAllTitle release];
    [rollupLoggedTitle release];
    [showHideTitle release];
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
