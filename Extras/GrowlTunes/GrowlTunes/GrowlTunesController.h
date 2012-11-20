//
//  GrowlTunesController.h
//  growltunes
//
//  Created by Travis Tilley on 11/7/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Growl/Growl.h>
#import "macros.h"

typedef enum : NSInteger {
	kShowIconInMenu = 0,
	kShowIconInDock = 1,
	kShowIconInBoth = 2,
	kDontShowIcon = 3
} GrowlTunesIconState;

@class ITunesConductor, FormattedItemViewController, StartAtLoginController, GrowlTunesFormattingController;

@interface GrowlTunesController : NSApplication <GrowlApplicationBridgeDelegate, NSApplicationDelegate> {
    ITunesConductor* _iTunesConductor;
    NSMenu* _statusItemMenu;
    NSMenuItem* _currentTrackMenuItem;
    FormattedItemViewController* _currentTrackController;
    NSStatusItem* _statusItem;
    NSWindowController* _formatwc;
    NSMenu* _loggingMenu;
    id <DDLogFormatter> _formatter;
    StartAtLoginController* _loginController;
}

@property(readonly, STRONG, nonatomic) IBOutlet ITunesConductor* conductor;
@property(readonly, STRONG, nonatomic) StartAtLoginController* loginController;
@property(readwrite, STRONG, nonatomic) IBOutlet NSMenu* statusItemMenu;
@property(readwrite, STRONG, nonatomic) IBOutlet NSMenuItem* currentTrackMenuItem;
@property(readwrite, STRONG, nonatomic) IBOutlet FormattedItemViewController* currentTrackController;
@property(readwrite, STRONG, nonatomic) IBOutlet NSMenu* loggingMenu;
@property(readonly, STRONG, nonatomic) GrowlTunesFormattingController *formatController;

- (IBAction)configureFormatting:(id)sender;
- (IBAction)quitGrowlTunes:(id)sender;
- (IBAction)quitGrowlTunesAndITunes:(id)sender;
- (void)createStatusItem;
- (void)destroyStatusItem;

@end
