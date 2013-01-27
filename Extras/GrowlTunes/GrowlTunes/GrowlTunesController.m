//
//  GrowlTunesController.m
//  growltunes
//
//  Created by Travis Tilley on 11/7/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "defines.h"
#import "GrowlTunesController.h"
#import "GrowlTunesFormattingController.h"
#import "GrowlTunesPreferencesWindowController.h"
#import "iTunes+iTunesAdditions.h"
#import "ITunesConductor.h"
#import "FormattedItemViewController.h"
#import "TrackRatingLevelIndicatorValueTransformer.h"
#import "StartAtLoginController.h"
#import "GrowlLocalizedStringsController.h"

@interface GrowlTunesController ()

@property(readwrite, STRONG, nonatomic) IBOutlet ITunesConductor* conductor;
@property(readonly, assign, nonatomic) BOOL noMeansNo;
@property(readwrite, STRONG, nonatomic) StartAtLoginController* loginController;

- (void)notifyWithTitle:(NSString*)title
            description:(NSString*)description
                   name:(NSString*)name
                   icon:(NSData*)icon;

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
@synthesize loginController = _loginController;
@synthesize localizedStringsController = _localizedStringsController;

+ (void)initialize
{
	if (self == [GrowlTunesController class]) {
		NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"defaults"
																					ofType:@"plist"];
		NSDictionary *defaultDefaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		
		NSUserDefaults *helperAppDefaults = [NSUserDefaults standardUserDefaults];
		[helperAppDefaults addSuiteNamed:@"com.growl.GrowlTunes"];
		NSDictionary *existing = [helperAppDefaults persistentDomainForName:@"com.growl.GrowlTunes"];
		if (existing) {
			NSMutableDictionary *domain = [defaultDefaults mutableCopy];
			[domain addEntriesFromDictionary:existing];
			[helperAppDefaults setPersistentDomain:domain forName:@"com.growl.GrowlTunes"];
			RELEASE(domain);
		} else {
			[helperAppDefaults setPersistentDomain:defaultDefaults forName:@"com.growl.GrowlTunes"];
		}
		[[NSUserDefaults standardUserDefaults] synchronize];
				
		NSValueTransformer* trackRatingTransformer = [[TrackRatingLevelIndicatorValueTransformer alloc] init];
		[NSValueTransformer setValueTransformer:trackRatingTransformer
												  forName:@"TrackRatingLevelIndicatorValueTransformer"];
		RELEASE(trackRatingTransformer);
	}
}

-(id)init {
   if((self = [super init])){
	   [NSApp setDelegate:self];
	   _localizedStringsController = [[GrowlLocalizedStringsController alloc] init];
	   _localizedStringsController.table = @"Localizable";
	   _formatController = [[GrowlTunesFormattingController alloc] init];
      self.conductor = AUTORELEASE([[ITunesConductor alloc] init]);
   }
   return self;
}

// NSMenuItem just doesn't seem to understand. bind title and suddenly no means yes. not cool, NSMenuItem.
- (BOOL)noMeansNo
{ return NO; }

- (NSString*)applicationNameForGrowl
{ return @"GrowlTunes"; }

- (NSDictionary*)registrationDictionaryForGrowl
{
	NSArray *allNotifications = @[formattingTypes, NotifierPaused, NotifierStopped];
	NSArray *allReadable = @[[[self localizedStringsController] stringForKey:@"PodcastFormatTitle"],[[self localizedStringsController] stringForKey:@"StreamFormatTitle"],[[self localizedStringsController] stringForKey:@"ShowFormatTitle"],[[self localizedStringsController] stringForKey:@"MovieFormatTitle"],[[self localizedStringsController] stringForKey:@"MusicVideoFormatTitle"],[[self localizedStringsController] stringForKey:@"MusicFormatTitle"], NotifierPausedReadable, NotifierStoppedReadable];
	NSArray *readableDict = [NSDictionary dictionaryWithObjects:allReadable forKeys:allNotifications];
		
	NSURL* iconURL = [[NSBundle mainBundle] URLForImageResource:@"GrowlTunes"];
	NSData *iconData = [NSData dataWithContentsOfURL:iconURL];
	
	NSDictionary* regDict = @{GROWL_APP_NAME : @"GrowlTunes",
										GROWL_APP_ID : @"com.growl.growltunes",
										GROWL_NOTIFICATIONS_ALL : allNotifications,
										GROWL_NOTIFICATIONS_DEFAULT : allNotifications,
										GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES : readableDict,
										GROWL_APP_ICON_DATA : iconData};
		
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
		NSString *type = [self.conductor.currentTrack typeDescription];
		
		[self notifyWithTitle:title description:description name:type icon:iconData];
	}else if([keyPath isEqualToString:@"isPaused"]){
		if([self.conductor isPaused])
			[self notifyWithTitle:NotifierPausedReadable description:@"" name:NotifierPaused icon:nil];
	}else if ([keyPath isEqualToString:@"isStopped"]){
		if([self.conductor isStopped]){
			[self notifyWithTitle:NotifierStoppedReadable description:@"" name:NotifierStopped icon:nil];
		}
	}
}

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
       
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
    
    NSBundle* launcherBundle = [NSBundle bundleWithPath:
         [[[NSBundle mainBundle] bundlePath]
          stringByAppendingPathComponent:@"Contents/Library/LoginItems/GrowlTunesLauncher.app"]];
    self.loginController = [[StartAtLoginController alloc] initWithBundle:launcherBundle];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
#pragma unused(aNotification)
        
#if defined(BETA)
    [self expiryCheck];
#endif
	
	NSNumber *visibility = [[NSUserDefaults standardUserDefaults] objectForKey:@"Visibility"];
	if(visibility == nil || [visibility integerValue] == kShowIconInDock || [visibility integerValue] == kShowIconInBoth){
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	}
	
	if(visibility == nil || [visibility integerValue] == kShowIconInMenu || [visibility integerValue] == kShowIconInBoth){
		[self createStatusItem];
	}
	    
    if (!_iTunesConductor) { self.conductor = AUTORELEASE([[ITunesConductor alloc] init]); }
    [self.conductor addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionInitial context:nil];
	[self.conductor addObserver:self forKeyPath:@"isPaused" options:NSKeyValueObservingOptionInitial context:nil];
	[self.conductor addObserver:self forKeyPath:@"isStopped" options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self.formatController saveTokens];
}

-(void)dealloc
{
    [self.conductor removeObserver:self forKeyPath:@"currentTrack"];
	[self.conductor removeObserver:self forKeyPath:@"isPaused"];
	[self.conductor removeObserver:self forKeyPath:@"isStopped"];
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
		return;
	}
	
	BOOL enabled = NO;
	if([name isEqualToString:NotifierPaused]){
		enabled = [[NSUserDefaults standardUserDefaults] boolForKey:NOTIFY_ON_PAUSE];
	}else if([name isEqualToString:NotifierStopped]){
		enabled = [[NSUserDefaults standardUserDefaults] boolForKey:NOTIFY_ON_STOP];
	}else if([name isEqualToString:@"error"]){
		enabled = NO;
	}else{
		enabled = [_formatController isFormatTypeEnabled:name];
	}
	if(!enabled)
		return;
	
	[GrowlApplicationBridge notifyWithTitle:title
										 description:description
								  notificationName:name
											 iconData:icon
											 priority:0
											 isSticky:FALSE
										clickContext:nil
										  identifier:name];
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

- (void)destroyStatusItem
{
	if(_statusItem) {
		[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
		RELEASE(_statusItem);
		_statusItem = nil;
	}
}

- (void)openMenu:(id)sender
{
#pragma unused(sender)
    
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
        _formatwc = [[GrowlTunesPreferencesWindowController alloc] initWithWindowNibName:@"GrowlTunesPrefs"];
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

- (IBAction)quitWithWarning:(id)sender
{
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"HideQuitWarning"])
	{
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure you want to quit?", nil)
										 defaultButton:NSLocalizedString(@"Yes", nil)
									   alternateButton:NSLocalizedString(@"No", nil)
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"If you quit GrowlTunes you will no longer receive iTunes notifications.", nil)];
		[alert setShowsSuppressionButton:YES];
		
		NSInteger result = [alert runModal];
		if(result == NSOKButton)
		{
			[[NSUserDefaults standardUserDefaults] setBool:(BOOL)[[alert suppressionButton] state] forKey:@"HideQuitWarning"];
			[NSApp terminate:self];
		}
	}
	else
		[NSApp terminate:self];
}

- (IBAction)quitGrowlTunesAndITunes:(id)sender
{
#pragma unused(sender)
    [self.conductor quit:sender];
    [NSApp terminate:self];
}


#pragma mark Pass through from UI to conductor
- (IBAction)quitItunes:(id)sender {
	[self.conductor quit:sender];
}
- (IBAction)runiTunes:(id)sender {
	[self.conductor runiTunes:sender];
}
- (IBAction)playPause:(id)sender {
	[self.conductor playPause:sender];
}
- (IBAction)nextTrack:(id)sender {
	[self.conductor nextTrack:sender];
}
- (IBAction)previousTrack:(id)sender {
	[self.conductor previousTrack:sender];
}
- (IBAction)activateItunes:(id)sender {
	[self.conductor activate:sender];
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
