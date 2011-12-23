//
//  GrowlTunesController.m
//  growltunes
//
//  Created by Travis Tilley on 11/7/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//


#import "GrowlTunesController.h"
#import "ITunesConductor.h"
#import "FormattedItemViewController.h"
#import "TrackRatingLevelIndicatorValueTransformer.h"
#import "iTunes+iTunesAdditions.h"


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


static int ddLogLevel = DDNS_LOG_LEVEL_DEFAULT;

+ (int)ddLogLevel
{
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

+ (void)initialize
{
    if (self == [GrowlTunesController class]) {
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
        
        NSValueTransformer* trackRatingTransformer = [[TrackRatingLevelIndicatorValueTransformer alloc] init];
        [NSValueTransformer setValueTransformer:trackRatingTransformer 
                                        forName:@"TrackRatingLevelIndicatorValueTransformer"];
        RELEASE(trackRatingTransformer);
        
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
                                   NotifierChangedTracksReadable,   NotifierChangedTracks,
                                   NotifierPausedReadable,          NotifierPaused,
                                   NotifierStoppedReadable,         NotifierStopped,
                                   NotifierStartedReadable,         NotifierStarted,
                                   nil];
    LogInfo(@"%@", notifications);
    
    NSArray* allNotifications = [notifications allKeys];
    
    NSURL* iconURL = [[NSBundle mainBundle] URLForImageResource:@"GrowlTunes"];
    NSImage* icon = [[NSImage alloc] initWithContentsOfURL:iconURL];
    NSData* iconData = nil;
    if (icon) {
        LogImage(icon);
        iconData = [icon TIFFRepresentation];
    }
    
    NSDictionary* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"GrowlTunes",             GROWL_APP_NAME,
                             @"com.growl.growltunes",   GROWL_APP_ID,
                             allNotifications,          GROWL_NOTIFICATIONS_ALL,
                             allNotifications,          GROWL_NOTIFICATIONS_DEFAULT,
                             notifications,             GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
                             iconData,                  GROWL_APP_ICON_DATA,
                             nil];
    
    RELEASE(icon);
    
    return regDict;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentTrack"]) {
        [_currentTrackMenuItem setView:nil];
        
        if (![self.conductor isPlaying]) return;
        
        NSDictionary* formatted = [[[self conductor] currentTrack] formattedDescriptionDictionary];
        
        if (!_currentTrackController) {
            self.currentTrackController = AUTORELEASE([[FormattedItemViewController alloc] init]); 
        }
        [_currentTrackController setFormattedDescription:formatted];
        [_currentTrackMenuItem setView:[_currentTrackController view]];
                
        NSString* title = [formatted valueForKey:@"title"];
        NSString* description = [formatted valueForKey:@"description"];
        NSImage* icon = [formatted valueForKey:@"icon"];
        NSData* iconData = [icon TIFFRepresentation];
        
        [self notifyWithTitle:title description:description name:NotifierChangedTracks icon:iconData];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#if defined(NSLOGGER)
    [DDLog addLogger:[DDNSLogger sharedInstance]];
    [[DDNSLogger sharedInstance] addTag:@"init" forContext:LogTagInit];
    [[DDNSLogger sharedInstance] addTag:@"KVC" forContext:LogTagKVC];
    [[DDNSLogger sharedInstance] addTag:@"state" forContext:LogTagState];
#endif
    
    [GrowlApplicationBridge setGrowlDelegate:self];
    [GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
    
    [self createStatusItem];
    
    if (!_iTunesConductor) { self.conductor = AUTORELEASE([[ITunesConductor alloc] init]); }
    [self.conductor addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionInitial context:nil];
    
#if defined(FSCRIPT)
    // not entirely sandbox friendly ;(
    BOOL loaded = [[NSBundle bundleWithPath:@"/Library/Frameworks/FScript.framework"] load];
    if (loaded) {
        Class FScriptMenuItem = NSClassFromString(@"FScriptMenuItem");
        id fscMenuItem = AUTORELEASE([[FScriptMenuItem alloc] init]);
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

-(void)dealloc
{
    [self.conductor removeObserver:self forKeyPath:@"currentTrack"];
    RELEASE(_iTunesConductor);
    RELEASE(_statusItemMenu);
    RELEASE(_currentTrackMenuItem);
    RELEASE(_currentTrackController);
    RELEASE(_statusItem);
    RELEASE(_formatwc);
    SUPER_DEALLOC;
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
        RETAIN(_statusItem);
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
        RELEASE(_statusItem);
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
