//
//  GrowlPluginPreferenceStrings.h
//  Growl
//
//  Created by Daniel Siemer on 1/30/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

/* FOR GROWL DEVELOPED COCOA PLUGINS ONLY AT THIS TIME, NOT STABLE */

#import <Foundation/Foundation.h>

@interface GrowlPluginPreferenceStrings : NSObject

@property (nonatomic, retain) NSString *growlDisplayOpacity;
@property (nonatomic, retain) NSString *growlDisplayDuration;

@property (nonatomic, retain) NSString *growlDisplayPriority;
@property (nonatomic, retain) NSString *growlDisplayPriorityVeryLow;
@property (nonatomic, retain) NSString *growlDisplayPriorityModerate;
@property (nonatomic, retain) NSString *growlDisplayPriorityNormal;
@property (nonatomic, retain) NSString *growlDisplayPriorityHigh;
@property (nonatomic, retain) NSString *growlDisplayPriorityEmergency;

@property (nonatomic, retain) NSString *growlDisplayTextColor;
@property (nonatomic, retain) NSString *growlDisplayBackgroundColor;

@property (nonatomic, retain) NSString *growlDisplayLimitLines;
@property (nonatomic, retain) NSString *growlDisplayScreen;
@property (nonatomic, retain) NSString *growlDisplaySize;
@property (nonatomic, retain) NSString *growlDisplaySizeNormal;
@property (nonatomic, retain) NSString *growlDisplaySizeLarge;
@property (nonatomic, retain) NSString *growlDisplaySizeSmall;

@property (nonatomic, retain) NSString *growlDisplayFloatingIcon;

@property (nonatomic, retain) NSString *effectLabel;
@property (nonatomic, retain) NSString *slideEffect;
@property (nonatomic, retain) NSString *fadeEffect;

@end
