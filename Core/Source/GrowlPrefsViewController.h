//
//  GrowlPrefsViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlPreferencePane;

@interface GrowlPrefsViewController : NSViewController

@property (nonatomic, retain) GrowlPreferencePane *prefPane;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
          forPrefPane:(GrowlPreferencePane*)aPrefPane;

@end
