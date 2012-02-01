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
#import "defines.h"


@interface GrowlTunesController ()

@property(readwrite, retain, nonatomic) IBOutlet ITunesConductor* conductor;

@property(readonly, nonatomic) BOOL noMeansNo;

@property(readonly, retain, nonatomic) NSString* stringPlayPause;
@property(readonly, retain, nonatomic) NSString* stringNextTrack;
@property(readonly, retain, nonatomic) NSString* stringPreviousTrack;
@property(readonly, retain, nonatomic) NSString* stringRating;
@property(readonly, retain, nonatomic) NSString* stringVolume;
@property(readonly, retain, nonatomic) NSString* stringBringITunesToFront;
@property(readonly, retain, nonatomic) NSString* stringQuitBoth;
@property(readonly, retain, nonatomic) NSString* stringQuitITunes;
@property(readonly, retain, nonatomic) NSString* stringQuitGrowlTunes;
@property(readonly, retain, nonatomic) NSString* stringStartITunes;
@property(readonly, retain, nonatomic) NSString* stringNotifyWithITunesActive;
@property(readonly, retain, nonatomic) NSString* stringConfigureFormatting;

- (void)notifyWithTitle:(NSString*)title
            description:(NSString*)description
                   name:(NSString*)name
                   icon:(NSData*)icon;

- (void)populateLoggingMenu;

#if defined(BETA)
- (NSCalendarDate *)dateWithString:(NSString *)str;
- (BOOL)expired;
- (void)expiryCheck;
#endif


@end


@implementation GrowlTunesController

@synthesize conductor = _iTunesConductor;
@synthesize statusItemMenu = _statusItemMenu;
@synthesize currentTrackMenuItem = _currentTrackMenuItem;
@synthesize currentTrackController = _currentTrackController;
@synthesize loggingMenu = _loggingMenu;


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
        NSDictionary * defaults = 
        [NSDictionary dictionaryWithContentsOfFile:
         [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
        [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
        
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
        
        NSValueTransformer* trackRatingTransformer = [[TrackRatingLevelIndicatorValueTransformer alloc] init];
        [NSValueTransformer setValueTransformer:trackRatingTransformer 
                                        forName:@"TrackRatingLevelIndicatorValueTransformer"];
        RELEASE(trackRatingTransformer);
    }
}

// NSMenuItem just doesn't seem to understand. bind title and suddenly no means yes. not cool, NSMenuItem.
- (BOOL)noMeansNo
{ return NO; }

- (NSString*)stringPlayPause
{ return MenuPlayPause; }

- (NSString*)stringNextTrack
{ return MenuNextTrack; }

- (NSString*)stringPreviousTrack
{ return MenuPreviousTrack; }

- (NSString*)stringRating
{ return MenuRating; }

- (NSString*)stringVolume
{ return MenuVolume; }

- (NSString*)stringBringITunesToFront
{ return MenuBringITunesToFront; }

- (NSString*)stringQuitBoth
{ return MenuQuitBoth; }

- (NSString*)stringQuitITunes
{ return MenuQuitITunes; }

- (NSString*)stringQuitGrowlTunes
{ return MenuQuitGrowlTunes; }

- (NSString*)stringStartITunes
{ return MenuStartITunes; }

- (NSString*)stringNotifyWithITunesActive
{ return MenuNotifyWithITunesActive; }

- (NSString*)stringConfigureFormatting
{ return MenuConfigureFormatting; }

- (NSString*)applicationNameForGrowl
{ return @"GrowlTunes"; }

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
    NSImage* icon = [[NSImage alloc] initByReferencingURL:iconURL];
    
    NSDictionary* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"GrowlTunes",             GROWL_APP_NAME,
                             @"com.growl.growltunes",   GROWL_APP_ID,
                             allNotifications,          GROWL_NOTIFICATIONS_ALL,
                             allNotifications,          GROWL_NOTIFICATIONS_DEFAULT,
                             notifications,             GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
                             icon,                      GROWL_APP_ICON_DATA,
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
        NSData* iconData = [formatted valueForKey:@"icon"];
        
        [self notifyWithTitle:title description:description name:NotifierChangedTracks icon:iconData];
    }
}

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#if !defined(DEBUG)
    [DDLog addLogger:[DDASLLogger sharedInstance]];
#endif
#if defined(NSLOGGER)
    [DDLog addLogger:[DDNSLogger sharedInstance]];
#endif
    
    [GrowlApplicationBridge setGrowlDelegate:self];
    [GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
    
#if defined(FSCRIPT)
    // fscript isn't entirely sandbox friendly ;(
    
    BOOL __block loaded = NO;
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
                                                         (NSUserDomainMask | NSLocalDomainMask), YES);
    [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString* frameworks = [(NSString*)obj stringByAppendingPathComponent:@"Frameworks"];
        NSString* fscript = [frameworks stringByAppendingPathComponent:@"FScript.framework"];
        loaded = [[NSBundle bundleWithPath:fscript] load];
        if (loaded) {
            LogVerbose(@"loaded FScript from framework at path: %@", fscript);
            *stop = loaded;
        }
    }];
    
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

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
    
#if defined(BETA)
    [self expiryCheck];
#endif
    
    [self createStatusItem];
    
    if (!_iTunesConductor) { self.conductor = AUTORELEASE([[ITunesConductor alloc] init]); }
    [self.conductor addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionInitial context:nil];
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
                               clickContext:nil
                                 identifier:name];
}

- (void)populateLoggingMenu
{
    NSMenu* loggingMenu = self.loggingMenu;
    [loggingMenu removeAllItems];
    
    NSArray* logLevelNumbers = [NSArray arrayWithObjects:
                                $num(DDNS_LOG_LEVEL_ERROR),
                                $num(DDNS_LOG_LEVEL_WARN),
                                $num(DDNS_LOG_LEVEL_INFO),
                                $num(DDNS_LOG_LEVEL_VERBOSE),
                                $num(DDNS_LOG_LEVEL_DEBUG),
                                nil];
    NSArray* logLevelNames = [NSArray arrayWithObjects: @"Error", @"Warning", @"Info", @"Verbose", @"Debug", nil];
    NSDictionary* logLevels = [NSDictionary dictionaryWithObjects:logLevelNumbers forKeys:logLevelNames];
    id menuTarget = self;
    
    void (^handleLogLevels)(NSString*, NSMenu*);
    handleLogLevels = ^(NSString* className, NSMenu* classMenu) {        
        @autoreleasepool {
            if (!className) className = @"All";
            id class = [className isEqualToString:@"All"] ? nil : NSClassFromString(className);

            NSNumber* currentLogLevel = class ? $num([DDLog logLevelForClass:class]) : $num(-1);
            
            for (NSString* levelName in logLevelNames) {
                NSMenuItem* levelItem = [[NSMenuItem alloc] initWithTitle:levelName 
                                                                   action:@selector(setLoggingLevel:) 
                                                            keyEquivalent:@""];
                [levelItem setTarget:menuTarget];
                
                NSNumber* levelNumber = [logLevels objectForKey:levelName];
                BOOL enabled = [levelNumber isEqualToNumber:currentLogLevel];
                [levelItem setState:enabled];
                
                NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                                      (class ? class : [NSNull null]),  @"class",
                                      levelName,                        @"levelName",
                                      levelNumber,                      @"level",
                                      nil];
                [levelItem setRepresentedObject:data];
                
                [classMenu addItem:levelItem];
                AUTORELEASE(levelItem);
            }
        }
    };
    
    NSMutableArray* configurableClasses = [[DDLog registeredClasses] mutableCopy];
    [configurableClasses insertObject:[NSNull null] atIndex:0];
    AUTORELEASE(configurableClasses);
    
    for (Class configurableClass in configurableClasses) {
        @autoreleasepool {
            NSString* className = (configurableClass != [NSNull null]) ? NSStringFromClass(configurableClass) : @"All";
            
            NSMenuItem* classItem = [[NSMenuItem alloc] initWithTitle:className 
                                                               action:NULL 
                                                        keyEquivalent:@""];
            [loggingMenu addItem:classItem];
            AUTORELEASE(classItem);
            
            NSMenu* classMenu = [[NSMenu alloc] initWithTitle:className];
            [classItem setSubmenu:classMenu];
            AUTORELEASE(classMenu);
            
            handleLogLevels(className, classMenu);
        }
    }
}

- (void)setLoggingLevel:(id)sender
{
    NSDictionary* data = [(NSMenuItem*)sender representedObject];
    if (!data) return;
    
    NSNumber* level = [data objectForKey:@"level"];
    NSString* name = [data objectForKey:@"levelName"];
    id class = [data objectForKey:@"class"];
    
    if (class == [NSNull null]) {
        NSArray* classes = [DDLog registeredClasses];
        for (Class _class in classes) {
            [DDLog setLogLevel:[level intValue] forClass:_class];
            LogInfo(@"Setting log level for class %@ to %@", NSStringFromClass(_class), name);
        }
    } else {
        [DDLog setLogLevel:[level intValue] forClass:class];
        LogInfo(@"Setting log level for class %@ to %@", NSStringFromClass(class), name);
    }
}

- (void)createStatusItem
{    
    if (!_statusItem) {
        NSStatusBar* statusBar = [NSStatusBar systemStatusBar];
        _statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
        if (_statusItem) {
            RETAIN(_statusItem);
            [_statusItem setImage:[NSImage imageNamed:@"GrowlTunes-Template.pdf"]];
            [_statusItem setHighlightMode:YES];
            [_statusItem setAction:@selector(openMenu:)];
            [_statusItem setTarget:self];
//            [_statusItem setMenu:self.statusItemMenu];
        }
    }
}

- (void)openMenu:(id)sender
{
#pragma unused(sender)
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableLoggingConfiguration"]) {
        LogVerbose(@"populating logging menu");
        [self populateLoggingMenu];
    }
    
    LogVerbose(@"popUpStatusItemMenu:");
    [_statusItem popUpStatusItemMenu:self.statusItemMenu];
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


#if defined(BETA)
- (NSCalendarDate *)dateWithString:(NSString *)str {
	str = [str stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	NSArray *dateParts = [str componentsSeparatedByString:@" "];
	int month = 1;
	NSString *monthString = [dateParts objectAtIndex:0];
	if ([monthString isEqualToString:@"Feb"]) {
		month = 2;
	} else if ([monthString isEqualToString:@"Mar"]) {
		month = 3;
	} else if ([monthString isEqualToString:@"Apr"]) {
		month = 4;
	} else if ([monthString isEqualToString:@"May"]) {
		month = 5;
	} else if ([monthString isEqualToString:@"Jun"]) {
		month = 6;
	} else if ([monthString isEqualToString:@"Jul"]) {
		month = 7;
	} else if ([monthString isEqualToString:@"Aug"]) {
		month = 8;
	} else if ([monthString isEqualToString:@"Sep"]) {
		month = 9;
	} else if ([monthString isEqualToString:@"Oct"]) {
		month = 10;
	} else if ([monthString isEqualToString:@"Nov"]) {
		month = 11;
	} else if ([monthString isEqualToString:@"Dec"]) {
		month = 12;
	}
	
	NSString *dateString = [NSString stringWithFormat:@"%@-%d-%@ 00:00:00 +0000", [dateParts objectAtIndex:2], month, [dateParts objectAtIndex:1]];
	return [NSCalendarDate dateWithString:dateString];
}

- (BOOL)expired
{
    BOOL result = YES;
    
    NSCalendarDate* nowDate = [self dateWithString:[NSString stringWithUTF8String:__DATE__]];
    NSCalendarDate* expiryDate = [nowDate dateByAddingTimeInterval:(60*60*24* DAYSTOEXPIRY)];
    
    if ([expiryDate earlierDate:[NSDate date]] != expiryDate)
        result = NO;
    
    return result;
}

- (void)expiryCheck
{
    if([self expired])
    {
        [NSApp activateIgnoringOtherApps:YES];
        NSInteger alert = NSRunAlertPanel(@"This Beta Has Expired", [NSString stringWithFormat:@"Please download a new version to keep using %@.", [[NSProcessInfo processInfo] processName]], @"Quit", nil, nil);
        if (alert == NSOKButton) 
        {
            [NSApp terminate:self];
        }
    }
}
#endif



@end
