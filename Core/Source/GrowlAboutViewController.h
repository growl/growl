//
//  GrowlAboutViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@interface GrowlAboutViewController : GrowlPrefsViewController

@property (nonatomic, assign) IBOutlet NSTextField *aboutVersionString;
@property (nonatomic, assign) IBOutlet NSTextView *aboutBoxTextView;

@property (nonatomic, retain) NSString *bugSubmissionLabel;
@property (nonatomic, retain) NSString *growlWebsiteLabel;

- (void) setupAboutTab;
- (IBAction) openGrowlWebSite:(id)sender;
- (IBAction) openGrowlBugSubmissionPage:(id)sender;

@end
