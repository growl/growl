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

@property (nonatomic, assign) IBOutlet NSTextField *pageTitle;
@property (nonatomic, assign) IBOutlet NSTextField *nextPageIntro;
@property (nonatomic, assign) IBOutlet NSTextField *pageBody;

@property (nonatomic, assign) IBOutlet NSButton *actionButton;
@property (nonatomic, assign) IBOutlet NSButton *continueButton;

@property (nonatomic) GrowlFirstLaunchState state;
@property (nonatomic) GrowlFirstLaunchState nextState;

+(BOOL)shouldRunFirstLaunch;

- (void)updateViews;

-(IBAction)nextPage:(id)sender;
-(IBAction)actionButton:(id)sender;
-(IBAction)enableGrowlAtLogin:(id)sender;
-(IBAction)openGrowlUninstallerPage:(id)sender;
-(IBAction)openGrowlGNTPPage:(id)sender;
-(IBAction)openPreferences:(id)sender;
-(IBAction)disableHistory:(id)sender;

@end
