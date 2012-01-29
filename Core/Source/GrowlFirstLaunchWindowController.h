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
@property (nonatomic, retain) NSString *actionButtonTitle;
@property (nonatomic, retain) NSString *continueButtonTitle;

@property (nonatomic) BOOL actionEnabled;

@property (nonatomic) NSUInteger current;

@property (nonatomic, retain) NSArray *launchViews;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) NSString *progressLabel;

+(BOOL)shouldRunFirstLaunch;

-(void)showCurrent;
-(IBAction)nextPage:(id)sender;
-(IBAction)actionButton:(id)sender;

@end
