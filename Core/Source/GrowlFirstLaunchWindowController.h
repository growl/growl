//
//  GrowlFirstLaunchWindowController.h
//  Growl
//
//  Created by Daniel Siemer on 8/17/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrowlFirstLaunchWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, assign) IBOutlet NSView *contentView;
@property (nonatomic, assign) IBOutlet NSView *currentContent;

@property (nonatomic, assign) IBOutlet NSTextField *pageTitle;
@property (nonatomic, assign) IBOutlet NSTextField *nextPageIntro;

@property (nonatomic, assign) IBOutlet NSView *welcomeView;
@property (nonatomic, assign) IBOutlet NSView *startAtLoginView;
@property (nonatomic, assign) IBOutlet NSView *removeOldGrowlView;
@property (nonatomic, assign) IBOutlet NSView *whatsNewView;

@property (nonatomic, assign) IBOutlet NSButton *continueButton;

@property (nonatomic) NSUInteger state;
@property (nonatomic) NSUInteger nextState;

+(BOOL)shouldRunFirstLaunch;

- (void)updateViews;

-(IBAction)nextPage:(id)sender;
-(IBAction)enableGrowlAtLogin:(id)sender;
-(IBAction)openPreferences:(id)sender;
-(IBAction)disableHistory:(id)sender;

@end
