//
//  GrowlRollupPrefsViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class SRRecorderControl;
@class GrowlPreferencesController;

@interface GrowlRollupPrefsViewController : GrowlPrefsViewController

@property (nonatomic, retain) IBOutlet SRRecorderControl *recorderControl;
@property (nonatomic, retain) NSString *rollupEnabledTitle;
@property (nonatomic, retain) NSString *rollupAutomaticTitle;
@property (nonatomic, retain) NSString *rollupAllTitle;
@property (nonatomic, retain) NSString *rollupLoggedTitle;
@property (nonatomic, retain) NSString *showHideTitle;

@property (nonatomic, retain) NSString *pulseMenuItemTitle;
@property (nonatomic, retain) NSString *idleDetectionBoxTitle;
@property (nonatomic, retain) NSString *idleAfterTitle;
@property (nonatomic, retain) NSString *secondsTitle;
@property (nonatomic, retain) NSString *minutesTitle;
@property (nonatomic, retain) NSString *hoursTitle;
@property (nonatomic, retain) NSString *whenScreenSaverActiveTitle;
@property (nonatomic, retain) NSString *whenScreenLockedTitle;

@end
