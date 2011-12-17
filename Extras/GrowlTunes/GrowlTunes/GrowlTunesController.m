//
//  GrowlTunesController.m
//  growltunes
//
//  Created by Travis Tilley on 11/7/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlTunesController.h"
#import "ITunesConductor.h"
#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import "macros.h"
#import "NSObject+DRYDescription.h"
#import "TrackRatingLevelIndicatorValueTransformer.h"
#import "FormattedItemViewController.h"


static int _LogLevel = LOG_LEVEL_ERROR;


@interface GrowlTunesController ()

@property(readwrite, retain, nonatomic) IBOutlet ITunesConductor* conductor;

- (void)notifyWithTitle:(NSString*)title
            description:(NSString*)description
                   name:(NSString*)name
                   icon:(NSData*)icon;

- (BOOL)noMeansNo;

@end


@implementation GrowlTunesController

@synthesize conductor = _iTunesConductor;
@synthesize statusItemMenu = _statusItemMenu;
@synthesize currentTrackMenuItem = _currentTrackMenuItem;
@synthesize currentTrackController = _currentTrackController;

+ (void)setLogLevel:(int)level
{
    _LogLevel = level;
}

+ (int)logLevel
{
    return _LogLevel;
}

+ (void)initialize
{
    if (self == [GrowlTunesController class]) {
        setLogLevel("GrowlTunesController");
        
        NSValueTransformer* trackRatingTransformer = [[TrackRatingLevelIndicatorValueTransformer alloc] init];
        [NSValueTransformer setValueTransformer:trackRatingTransformer 
                                        forName:@"TrackRatingLevelIndicatorValueTransformer"];
        
        NSDictionary * defaults = 
        [NSDictionary dictionaryWithContentsOfFile:
         [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
        [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
    }
}

// NSMenuItem just doesn't seem to understand. bind title and suddenly no means yes. not cool, NSMenuItem.
- (BOOL)noMeansNo
{
    return NO;
}

- (NSString*)applicationNameForGrowl
{
	return @"GrowlTunes";
}

- (NSDictionary*)registrationDictionaryForGrowl
{    
    NSDictionary* notifications = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NotifierChangedTracksReadable, NotifierChangedTracks,
                                   NotifierPausedReadable, NotifierPaused,
                                   NotifierStoppedReadable, NotifierStopped,
                                   NotifierStartedReadable, NotifierStarted,
                                   nil];
    LogInfo(@"%@", notifications);
    
    NSArray* allNotifications = [notifications allKeys];
    
    NSURL* iconURL = [[NSBundle mainBundle] URLForImageResource:@"GrowlTunes"];
    NSImage* icon = [[NSImage alloc] initWithContentsOfURL:iconURL];
    LogImage(@"app icon", icon);
    
    NSDictionary* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"GrowlTunes", GROWL_APP_NAME,
                             @"com.growl.growltunes", GROWL_APP_ID,
                             allNotifications, GROWL_NOTIFICATIONS_ALL,
                             allNotifications, GROWL_NOTIFICATIONS_DEFAULT,
                             notifications, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
                             [icon TIFFRepresentation], GROWL_APP_ICON_DATA,
                             nil];
    
    return regDict;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentTrack"]) {
        [_currentTrackMenuItem setView:nil];
        
        if (![self.conductor isPlaying]) return;
        
        NSDictionary* formatted = [[[self conductor] currentTrack] formattedDescriptionDictionary];
        
        if (!_currentTrackController) { self.currentTrackController = [[FormattedItemViewController alloc] init]; }
        [_currentTrackController setFormattedDescription:formatted];
        [_currentTrackMenuItem setView:[_currentTrackController view]];
                
        NSString* title = [formatted valueForKey:@"title"];
        NSString* description = [formatted valueForKey:@"description"];
        NSImage* icon = [formatted valueForKey:@"icon"];
        NSData* iconData = [icon TIFFRepresentation];
        
        [self notifyWithTitle:title description:description name:NotifierChangedTracks icon:iconData];
    }
}

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
    
    [GrowlApplicationBridge setGrowlDelegate:self];
    [GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
    
    [self createStatusItem];
    
    if (!_iTunesConductor) { self.conductor = [[ITunesConductor alloc] init]; }
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
    
    [self.conductor addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionInitial context:nil];
    
#if defined(DEBUG) || defined(FSCRIPT)
    BOOL loaded = [[NSBundle bundleWithPath:@"/Library/Frameworks/FScript.framework"] load];
    if (loaded) {
        Class FScriptMenuItem = NSClassFromString(@"FScriptMenuItem");
        id fscMenuItem = [[FScriptMenuItem alloc] init];
        id fiv = [fscMenuItem performSelector:@selector(interpreterView)];
        id fi = [fiv performSelector:@selector(interpreter)];
        [fi performSelector:@selector(setObject:forIdentifier:) 
                 withObject:self 
                 withObject:@"appDelegate"];
        [fi performSelector:@selector(setObject:forIdentifier:) 
                 withObject:[NSApplication sharedApplication] 
                 withObject:@"app"];
        [fi performSelector:@selector(setObject:forIdentifier:) 
                 withObject:self.conductor 
                 withObject:@"conductor"];
        [self.statusItemMenu addItem:fscMenuItem];
    }
#endif
}

- (void)notifyWithTitle:(NSString*)title
            description:(NSString*)description
                   name:(NSString*)name
                   icon:(NSData*)icon
{
    BOOL notifyWhenFrontmost = [[NSUserDefaults standardUserDefaults] boolForKey:NOTIFY_ITUNES_FRONTMOST];
    
    if (!notifyWhenFrontmost && [self.conductor isFrontmost]) {
        LogInfo(@"Not growling: iTunes is frontmost");
        return;
    }
    
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:name
                                   iconData:icon
                                   priority:0
                                   isSticky:FALSE
                               clickContext:nil];
}

- (void)createStatusItem
{    
    if (!_statusItem) {
        NSStatusBar* statusBar = [NSStatusBar systemStatusBar];
        _statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
        if (_statusItem) {
            [_statusItem setMenu:self.statusItemMenu];
            [_statusItem setHighlightMode:YES];
            [_statusItem setImage:[NSImage imageNamed:@"growlTunes.png"]];
            [_statusItem setAlternateImage:[NSImage imageNamed:@"growlTunes-selected.png"]];
        }
    }
}

- (void)removeStatusItem
{    
    if (_statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
        _statusItem = nil;
    }
}

- (IBAction)configureFormatting:(id)sender
{
#pragma unused(sender)
    if (!_formatwc) {
        _formatwc = [[NSWindowController alloc] initWithWindowNibName:@"FormattingPreferences"];
    }
    [NSApp activateIgnoringOtherApps:YES];
    [_formatwc showWindow:self];
    [[_formatwc window] makeKeyWindow];
}

- (IBAction)quitGrowlTunes:(id)sender
{
#pragma unused(sender)
    [NSApp terminate:self];
}

- (IBAction)quitGrowlTunesAndITunes:(id)sender
{
#pragma unused(sender)
    [self.conductor quit:sender];
    [NSApp terminate:self];
}

@end
