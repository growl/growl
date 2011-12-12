#import "AppDelegate.h"


#define NotifierChangedTracks           @"Changed Tracks"
#define NotifierPaused                  @"Paused"
#define NotifierStopped                 @"Stopped"
#define NotifierStarted                 @"started"

#define NotifierChangedTracksReadable   NSLocalizedString(@"Changed Tracks", nil)
#define NotifierPausedReadable          NSLocalizedString(@"Paused", nil)
#define NotifierStoppedReadable         NSLocalizedString(@"Stopped", nil)
#define NotifierStartedReadable         NSLocalizedString(@"Started", nil)


@implementation AppDelegate

@synthesize statusItemMenu;

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
    
    NSArray* allNotifications = [notifications allKeys];
    
    NSURL* iconURL = [[NSBundle mainBundle] URLForImageResource:@"GrowlTunes"];
    NSImage* icon = [[NSImage alloc] initWithContentsOfURL:iconURL];
    
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

- (void)applicationWillFinishLaunching:(NSNotification*)__attribute__((unused))aNotification
{
    [GrowlApplicationBridge setGrowlDelegate:self];
    [GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
    
    [self createStatusItem];
    
    iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(songChanged:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
}

- (void) songChanged:(NSNotification *)aNotification
{
    BOOL iTunesIsTheActiveApp = ([[[[NSWorkspace sharedWorkspace] 
                                    activeApplication] 
                                   objectForKey:@"NSApplicationBundleIdentifier"] 
                                  caseInsensitiveCompare:@"com.apple.iTunes"] == NSOrderedSame);
    
    if (iTunesIsTheActiveApp) return;
    
    NSDictionary* userInfo = [aNotification userInfo];
    
    NSString* playerState = [userInfo objectForKey:@"Player State"];
    
    if ([playerState isEqualToString:@"Playing"]) {
        NSString* name = [userInfo objectForKey:@"Name"];
        NSString* artist = [userInfo objectForKey:@"Artist"];
        NSString* album = [userInfo objectForKey:@"Album"];
        NSString* length = [userInfo objectForKey:@"Total Time"];
        
        int sec = [length intValue] / 1000;
        int hr = sec / 3600;
        sec -= 3600 * hr;
        int min = sec / 60;
        sec -= 60 * min;
        
        if (hr > 0) {
            length = [NSString stringWithFormat:@"%d:%02d:%02d", hr, min, sec];
        } else {
            length = [NSString stringWithFormat:@"%d:%02d", min, sec];
        }
        
        NSString* title = [NSString stringWithFormat:@"GrowlTunes - %@", name];
        NSString* description = [NSString stringWithFormat:@"%@\n%@\n%@", length, artist, album];
        
        iTunesTrack* currentTrack = iTunes.currentTrack.get;
        iTunesArtwork* artwork = [currentTrack.artworks objectAtIndex:0];
        
        NSData* iconData = nil;
        NSImage* icon = [artwork data];
        
        if (icon != nil) {
            iconData = [icon TIFFRepresentation];
        }
        
        [self notifyWithTitle:title
                  description:description
                         name:NotifierChangedTracks
                         icon:iconData];
    }
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
    if (!statusItem) {
        NSStatusBar* statusBar = [NSStatusBar systemStatusBar];
        statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
        if (statusItem) {
            [statusItem setMenu:self.statusItemMenu];
            [statusItem setHighlightMode:YES];
            [statusItem setImage:[NSImage imageNamed:@"growlTunes.png"]];
            [statusItem setAlternateImage:[NSImage imageNamed:@"growlTunes-selected.png"]];
        }
    }
}

- (void)removeStatusItem
{
    if (statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
        statusItem = nil;
    }
}

- (IBAction)quitGrowlTunes:(id)sender
{
    [NSApp terminate:sender];
}

@end
