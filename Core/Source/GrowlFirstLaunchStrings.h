//
//  GrowlFirstLaunchStrings.h
//  
//
//  Created by Daniel Siemer on 8/28/11.
//  Copyright 2011 The Growl Project, LLC. All rights reserved.
//

typedef enum{
   firstLaunchWelcome = 1,
   firstLaunchStartGrowl = 2,
   firstLaunchOldGrowl = 6,
   firstLaunchDone = 7
}GrowlFirstLaunchState;

#define FirstLaunchWelcomeTitle     NSLocalizedString(@"Welcome to Growl!",@"Title welcoming a new user to growl")
#define FirstLaunchWelcomeBody      NSLocalizedString(@"Welcome to the Growl walkthrough. Even if you have used Growl before, it would be helpful to you if you take a moment to get to know Growl 1.3.", @"");

#define FirstLaunchDoneNext         NSLocalizedString(@"You are all ready to go, enjoy Growl!", @"Done with first launch dialog")

#define FirstLaunchStartGrowlNext   NSLocalizedString(@"Continue on to enable Growl at login", @"Next page is enabling growl at login")
#define FirstLaunchStartGrowlTitle  NSLocalizedString(@"Let Growl Start at Login", @"Title for starting growl at login")
#define FirstLaunchStartGrowlBody   NSLocalizedString(@"Growl needs to run all of the time in order to work. Please click this button to enable Growl to run at Login", @"")
#define FirstLaunchStartGrowlButton NSLocalizedString(@"Enable Growl to run on Login", @"Button label to allow growl to start at login")

#define FirstLaunchOldGrowlNext     NSLocalizedString(@"Continue to remove old copies of Growl",@"Next page is removing old growl's")
#define FirstLaunchOldGrowlTitle    NSLocalizedString(@"Remove old copies of Growl",@"Title for removing old copies of growl")
#define FirstLaunchOldGrowlBody     NSLocalizedString(@"We have found an old installation of Growl on your computer. Please click on this button to go to our website to download the uninstaller.  Manual removal instructions are also available.", @"")
#define FirstLaunchOldGrowlButton   NSLocalizedString(@"Legacy Growl Uninstaller", @"Button label for removing old copies of growl")
