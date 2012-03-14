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
@property (nonatomic, retain) NSString *rollupIdleTitle;
@property (nonatomic, retain) NSString *secondsTitle;
@property (nonatomic, retain) NSString *rollupAllTitle;
@property (nonatomic, retain) NSString *rollupLoggedTitle;
@property (nonatomic, retain) NSString *showHideTitle;
@end
