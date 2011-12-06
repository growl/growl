//
//  CapsterAppDelegate.h
//  Capster
//
//  Created by Vasileios Georgitzikis on 3/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//
// This source code is release under the BSD License.

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>

#include "GrowlController.h"
#include "StatusbarController.h"

#include <assert.h>
#include <errno.h>
#include <mach/mach.h>
#include <notify.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

@interface Growl_Caps_NotifierAppDelegate : NSObject <NSApplicationDelegate>
{
@private
	//Preferences Panel outlet
	IBOutlet NSPanel *preferencePanel;
	//the user's preferences, loaded at startup
	NSUserDefaults *preferences;
	//The following are outlets in the preferences panel.
	//the outlets are needed to change their text color to white
	NSInteger oldIconValue;
    NSArray *iconOptions;
    NSPopUpButton *iconPopUp;
//	IBOutlet NSMatrix *statusbarMatrix;
	//the menu shown when the menu icon is pressed
    IBOutlet NSMenu *statusMenu;
	NSUInteger *statusbar;
	
	NSUInteger* currentState;

    NSInteger oldOnLoginValue;
    NSSegmentedControl *onLoginSegmentedControl;
	
	GrowlController* myGrowlController;
	StatusbarController *myStatusbarController;
	
	NSString *prefsTitle, *onLoginTitle, *quitTitle;
	NSString *noneTitle, *blackIcons, *colorIcons, *preferenceTitle, *labelTitle, *closeTitle;
}

@property  (nonatomic, assign) IBOutlet NSSegmentedControl *onLoginSegmentedControl;

@property (nonatomic, retain)  NSString *prefsTitle;
@property (nonatomic, retain)  NSString *onLoginTitle;
@property (nonatomic, retain)  NSString *quitTitle;

@property (nonatomic, retain)  NSString *noneTitle;
@property (nonatomic, retain)  NSString *blackIcons;
@property (nonatomic, retain)  NSString *colorIcons;
@property (nonatomic, retain)  NSString *preferenceTitle;
@property (nonatomic, retain)  NSString *labelTitle;
@property (nonatomic, retain)  NSString *closeTitle;

@property (nonatomic, retain) NSArray *iconOptions;
@property (nonatomic, assign) IBOutlet NSPopUpButton *iconPopUp;


@property (assign) IBOutlet NSPanel *preferencePanel;

- (void) registerDefaults;
- (void) initTitles;
- (void)setButtonTitleFor:(id)button toString:(NSString*)title withColor:(NSColor*)color ;
- (void) listenForCapsInNewThread;
- (void) listen;

//set the status menu to the value of the checkbox sender
//- (IBAction) statusMenuChanged: (id) sender;
//show the preference panel
- (IBAction) showPreferences:(id) sender;

- (void) fetchedCapsState;
- (void) capsLockChanged: (NSUInteger) newState;
- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled;
@end
