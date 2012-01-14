//
//  GrowlGeneralViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlPositionPicker, GrowlOnSwitch;

@interface GrowlGeneralViewController : GrowlPrefsViewController

@property (nonatomic, assign) IBOutlet GrowlPositionPicker *globalPositionPicker;
@property (nonatomic, assign) IBOutlet GrowlOnSwitch *startAtLoginSwitch;

@property (nonatomic, retain) NSString *additionalDownloadsButtonTitle;
@property (nonatomic, retain) NSString *startGrowlAtLoginLabel;
@property (nonatomic, retain) NSString *defaultStartingPositionLabel;
@property (nonatomic, retain) NSArray *iconMenuOptionsList;

-(IBAction)startGrowlAtLogin:(id)sender;

@end
