//
//  GrowlOnSwitch.h
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMSliderControl.h"

@interface GrowlOnSwitch : TMSliderControl

@property (nonatomic, retain) IBOutlet NSTextField *onLabel;
@property (nonatomic, retain) IBOutlet NSTextField *offLabel;

@end
