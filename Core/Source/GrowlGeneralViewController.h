//
//  GrowlGeneralViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlPositionPicker, GrowlOnSwitch;
@class SRRecorderControl;

@interface GrowlGeneralViewController : GrowlPrefsViewController

@property (nonatomic, assign) IBOutlet GrowlPositionPicker *globalPositionPicker;
@property (nonatomic, assign) IBOutlet GrowlOnSwitch *startAtLoginSwitch;
@property (assign) IBOutlet SRRecorderControl *recorderControl;
@property (nonatomic, assign) IBOutlet NSImageView *growlClawLogo;
@property (nonatomic, assign) IBOutlet GrowlOnSwitch *useAppleNotificationCenterSwitch;
@property (nonatomic, assign) IBOutlet NSTextField *useAppleNotificationCenterLabelField;
@property (nonatomic, assign) IBOutlet NSTextField *useAppleNotificationCenterExplanationField;
@property (nonatomic, assign) IBOutlet NSButton *additionalDownloadsButton;

@property (nonatomic, retain) NSString *closeAllNotificationsTitle;
@property (nonatomic, retain) NSString *additionalDownloadsButtonTitle;
@property (nonatomic, retain) NSString *startGrowlAtLoginLabel;
@property (nonatomic, retain) NSString *useAppleNotificationCenterLabel;
@property (nonatomic, retain) NSString *appleNotificationCenterExplanation;
@property (nonatomic, retain) NSString *defaultStartingPositionLabel;
@property (nonatomic, retain) NSArray *iconMenuOptionsList;

-(IBAction)startGrowlAtLogin:(id)sender;
-(IBAction)useAppleNotificationCenter:(id)sender;

@end
