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
   firstLaunchWhatsNew1 = 3,
   firstLaunchWhatsNew2 = 4,
   firstLaunchWhatsNew3 = 5,
   firstLaunchOldGrowl = 6,
   firstLaunchDone = 7
}GrowlFirstLaunchState;

#define FirstLaunchWelcomeTitle     NSLocalizedString(@"Welcome to Growl!",@"Title welcoming a new user to growl")
#define FirstLaunchWelcomeBody      NSLocalizedString(@"Welcome to the Growl walkthrough. Even if you have used Growl before, it would be helpful to you if you take a moment to to get to know Growl 1.3.", @"");

#define FirstLaunchDoneNext         NSLocalizedString(@"You are all ready to go, enjoy Growl!", @"Done with first launch dialog")

#define FirstLaunchStartGrowlNext   NSLocalizedString(@"Continue on to enable Growl at login", @"Next page is enabling growl at login")
#define FirstLaunchStartGrowlTitle  NSLocalizedString(@"Let Growl Start at Login", @"Title for starting growl at login")
#define FirstLaunchStartGrowlBody   NSLocalizedString(@"Growl needs to run all of the time in order to work. Please click this button to enable Growl to run at Login", @"")
#define FirstLaunchStartGrowlButton NSLocalizedString(@"Enable Growl to run on Login", @"Button label to allow growl to start at login")

#define FirstLaunchWhatsNewNext     NSLocalizedString(@"Continue to learn whats new in Growl 1.3",@"Next page is whats new in the current growl")
#define FirstLaunchWhatsNewTitle    NSLocalizedString(@"New to Growl 1.3", @"Title for whats new to growl")
#define FirstLaunchWhatsNewBody1    NSLocalizedString(@"Growl 1.3 comes with a number of changes and new features for users.  Growl now runs as a status bar item, and preferences can be reached from there",@"")
#define FirstLaunchWhatsNewButton1  NSLocalizedString(@"Show me the preference pane", @"Button label for showing the preference pane")

#define FirstLaunchWhatsNewBody2    NSLocalizedString(@"History, and the notification rollup are also new.  When you are idle, notifications will be stored in a window for when you return to your computer.\nHistory is on by default, but you can click below to turn it off", @"")
#define FirstLaunchWhatsNewButton2  NSLocalizedString(@"Disable History", @"Button label for disabling history")

#define FirstLaunchWhatsNewBody3    NSLocalizedString(@"Growl 1.3 comes with a completely new networking system, called GNTP. GNTP can talk to Growl 1.3 and above, and other GNTP compliant software, such as Growl for Windows", @"")
#define FirstLaunchWhatsNewButton3  NSLocalizedString(@"Learn more about GNTP", @"Button label for showing a website with more information on GNTP")

#define FirstLaunchOldGrowlNext     NSLocalizedString(@"Continue to remove old copies of Growl",@"Next page is removing old growl's")
#define FirstLaunchOldGrowlTitle    NSLocalizedString(@"Remove old copies of Growl",@"Title for removing old copies of growl")
#define FirstLaunchOldGrowlBody     NSLocalizedString(@"We have found an old installation of Growl on your computer. Please click on this button to go to our website to download the uninstaller.  Manual removal instructions are also available.", @"")
#define FirstLaunchOldGrowlButton   NSLocalizedString(@"Legacy Growl Uninstaller", @"Button label for removing old copies of growl")
