//
//  GrowlPrefsViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"
#import "GrowlPreferencePane.h"
#import "GrowlPreferencesController.h"

@implementation GrowlPrefsViewController

@synthesize prefPane;
@synthesize preferencesController;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
          forPrefPane:(GrowlPreferencePane*)aPrefPane
{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
       self.prefPane = aPrefPane;
       self.preferencesController = [GrowlPreferencesController sharedController];
    }
    
    return self;
}

- (void)dealloc
{
   [prefPane release];
   [super dealloc];
}

@end
