//
//  GrowlFirstLaunchWindowController.h
//  Growl
//
//  Created by Daniel Siemer on 8/17/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlFirstLaunchStrings.h"

@interface GrowlFirstLaunchWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, retain) NSString *windowTitle;
@property (nonatomic, retain) NSAttributedString *textBoxString;
@property (nonatomic, retain) NSString *sectionTitle;
@property (nonatomic, retain) NSString *actionButtonTitle;
@property (nonatomic, retain) NSString *continueButtonTitle;
@property (nonatomic, retain) NSString *continueButtonLabel;

@property (nonatomic) BOOL actionEnabled;

@property (nonatomic) GrowlFirstLaunchState state;
@property (nonatomic) GrowlFirstLaunchState nextState;

+(BOOL)shouldRunFirstLaunch;

- (void)updateViews;

-(IBAction)nextPage:(id)sender;
-(IBAction)actionButton:(id)sender;
-(IBAction)enableGrowlAtLogin:(id)sender;
-(IBAction)openGrowlUninstallerPage:(id)sender;

@end
