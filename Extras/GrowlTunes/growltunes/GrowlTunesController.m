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
#import <dlfcn.h>


static int _LogLevel = LOG_LEVEL_ERROR;


@interface GrowlTunesController ()

@property(readwrite, strong, nonatomic) ITunesConductor* conductor;

- (void)notifyWithTitle:(NSString*)title
            description:(NSString*)description
                   name:(NSString*)name
                   icon:(NSData*)icon;
@end


@implementation GrowlTunesController

@synthesize conductor = _iTunesConductor;
@synthesize statusItemMenu = _statusItemMenu;

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
    NSDictionary * defaults = 
        [NSDictionary dictionaryWithContentsOfFile: 
            [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
}

- (NSString*)applicationNameForGrowl
{
	return @"GrowlTunes";
}

- (NSDictionary*)registrationDictionaryForGrowl
{    
    NSDictionary* notifications = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NotifierChangedTracks, NotifierChangedTracksReadable,
                                   NotifierPaused, NotifierPausedReadable,
                                   NotifierStopped, NotifierStoppedReadable,
                                   NotifierStarted, NotifierStartedReadable,
                                   nil];
    NSLog(@"%@", notifications);
    
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

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
    
    [GrowlApplicationBridge setGrowlDelegate:self];
    [GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
    
    self.conductor = [[ITunesConductor alloc] init];
    
    [self createStatusItem];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
    
    $depends(@"GrowlNotificationTrigger",
             self, @"conductor",
             _iTunesConductor, @"currentTrack",
             ^{
                 if ([[ITunesApplication sharedInstance] playerState] != StatePlaying) {
                     return;
                 }
                 
                 NSDictionary* formatted = [[[selff conductor] currentTrack] formattedDescriptionDictionary];
                 NSString* title = [formatted valueForKey:@"title"];
                 NSString* description = [formatted valueForKey:@"description"];
                 NSImage* icon = [formatted valueForKey:@"icon"];
                 NSData* iconData = [icon TIFFRepresentation];
                 
                 [selff notifyWithTitle:title description:description name:NotifierChangedTracks icon:iconData];
             });
    
#ifdef DEBUG
    // load FScript if available for easy runtime introspection and debugging
    void* dl_handle = dlopen("/Library/Frameworks/FScript.framework/FScript", RTLD_GLOBAL | RTLD_NOW);
    if (dl_handle) {
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


@end
