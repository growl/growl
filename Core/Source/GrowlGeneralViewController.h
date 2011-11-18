//
//  GrowlGeneralViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlPositionPicker;

@interface GrowlGeneralViewController : GrowlPrefsViewController

@property (nonatomic, assign) IBOutlet GrowlPositionPicker *globalPositionPicker;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *startAtLoginSwitch;

@end
