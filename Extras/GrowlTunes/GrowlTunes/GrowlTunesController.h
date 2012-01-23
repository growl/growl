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

@class ITunesConductor, FormattedItemViewController;

@interface GrowlTunesController : NSObject <GrowlApplicationBridgeDelegate, NSApplicationDelegate> {
    ITunesConductor* _iTunesConductor;
    NSMenu* _statusItemMenu;
    NSMenuItem* _currentTrackMenuItem;
    FormattedItemViewController* _currentTrackController;
    NSStatusItem* _statusItem;
    NSWindowController* _formatwc;
    NSMenu* _loggingMenu;
}

@property(readonly, retain, nonatomic) IBOutlet ITunesConductor* conductor;
@property(readwrite, retain, nonatomic) IBOutlet NSMenu* statusItemMenu;
@property(readwrite, retain, nonatomic) IBOutlet NSMenuItem* currentTrackMenuItem;
@property(readwrite, retain, nonatomic) IBOutlet FormattedItemViewController* currentTrackController;
@property(readwrite, retain, nonatomic) IBOutlet NSMenu* loggingMenu;

- (IBAction)configureFormatting:(id)sender;
- (IBAction)quitGrowlTunes:(id)sender;
- (IBAction)quitGrowlTunesAndITunes:(id)sender;
- (void)createStatusItem;

@end
