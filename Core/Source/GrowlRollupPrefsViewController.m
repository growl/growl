//
//  GrowlRollupPrefsViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlRollupPrefsViewController.h"

@implementation GrowlRollupPrefsViewController 

@synthesize rollupEnabledTitle;
@synthesize rollupAutomaticTitle;
@synthesize rollupIdleTitle;
@synthesize secondsTitle;
@synthesize rollupAllTitle;
@synthesize rollupLoggedTitle;

-(void)awakeFromNib {
   self.rollupEnabledTitle = NSLocalizedString(@"Rollup Enabled", @"Title for rollup enabled checkbox");
   self.rollupAutomaticTitle = NSLocalizedString(@"Rollup Automatically Displays", @"Title for rollup automatic checkbox");
   self.rollupIdleTitle = NSLocalizedString(@"Send notifications to the rollup after", @"First part of string for idle timeout");
   self.secondsTitle = NSLocalizedString(@"seconds of inactivity", @"second part of string for idle timeout");
   self.rollupAllTitle = NSLocalizedString(@"Rollup all notes", @"Rollup all notifications radio button");
   self.rollupLoggedTitle = NSLocalizedString(@"Rollup only logged notes", @"Rollup only logged notifications radio button");
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
   [super dealloc];
}

@end
